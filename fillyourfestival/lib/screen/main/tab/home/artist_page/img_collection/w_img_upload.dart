import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../../../../../../auth/token_store.dart';
import '../../../../../../config.dart';
import 'dto_presign_response.dart';

class ImgUpload extends StatefulWidget {
  const ImgUpload({super.key, required this.artistId, required this.artistName});

  final int artistId;
  final String artistName;

  @override
  State<ImgUpload> createState() => _ImgUploadState();
}

class _ImgUploadState extends State<ImgUpload> {
  final _formKey = GlobalKey<FormState>();

  Uint8List? imageData;
  XFile? image;

  TextEditingController titleTEC = TextEditingController();
  TextEditingController ftvNameTEC = TextEditingController();

  Future<Uint8List> imageCompressList(Uint8List list) async {
    var result = await FlutterImageCompress.compressWithList(list, quality: 50);
    return result;
  }

  Future<void> addImage() async {
    if (imageData == null) return;

    final compressedData = await imageCompressList(imageData!);

    const contentType = 'image/jpeg';
    const extension = 'jpg';

    final token = await TokenStore.readAccessToken();
    if (token == null || token.isEmpty) {
      throw Exception('로그인이 필요합니다(토큰 없음)');
    }

    final artistId = widget.artistId;

    final dio = Dio();

    final presignRes = await dio.post(
      '$baseUrl/artists/$artistId/photos/presign',
      data: {'contentType': contentType, 'extension': extension},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    final presign = PresignResponse.fromJson(presignRes.data);

    final putRes = await http.put(
      Uri.parse(presign.uploadUrl),
      headers: {'Content-Type': contentType},
      body: compressedData,
    );

    if (putRes.statusCode < 200 || putRes.statusCode >= 300) {
      throw Exception('S3 upload failed: ${putRes.statusCode} ${putRes.body}');
    }

    await dio.post(
      '$baseUrl/artists/$artistId/photos',
      data: {'objectKey': presign.objectKey, 'contentType': contentType},
      options: Options(headers: {'Authorization': 'Bearer $token'}),
    );

    if (!mounted) return;
    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("사진 올리기"),
        actions: [
          IconButton(
            onPressed: () async {
              if (_formKey.currentState?.validate() ?? false) {
                try {
                  await addImage();
                } on DioException catch (e) {
                  debugPrint('status=${e.response?.statusCode}');
                  debugPrint('data=${e.response?.data}'); // 서버 500 원인 확인용 [web:837]
                } catch (e) {
                  debugPrint('upload error: $e');
                }
              }
            },
            icon: const Icon(Icons.send),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            children: [
              GestureDetector(
                onTap: () async {
                  final ImagePicker picker = ImagePicker();
                  image = await picker.pickImage(source: ImageSource.gallery);
                  imageData = await image?.readAsBytes();
                  setState(() {});
                },
                child: Align(
                  alignment: Alignment.center,
                  child: Container(
                    margin: const EdgeInsets.all(20),
                    height: 240,
                    width: 240,
                    decoration: BoxDecoration(
                      color: Colors.grey[200]!,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: imageData == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                color: Colors.black,
                                Icons.add,
                              ),
                              Text(
                                "아티스트 사진 추가",
                                style: TextStyle(
                                  color: Colors.black,
                                ),
                              ),
                            ],
                          )
                        : Image.memory(imageData!, fit: BoxFit.cover),
                  ),
                ),
              ),
              Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16.0),
                        child: Text(
                          widget.artistName,
                          style: Theme.of(context).textTheme.headlineMedium,
                        ) //아티스트 이름,
                        ),
                    TextFormField(
                      controller: titleTEC,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "작품명",
                          hintText: "작품명을 입력하세요."),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "필수 입력 항목입니다.";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(
                      height: 12,
                    ),
                    TextFormField(
                      controller: ftvNameTEC,
                      decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          labelText: "페스티벌 이름",
                          hintText: "페스티벌 위치나 이름을 입력하세요."),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return "필수 입력 항목입니다.";
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}

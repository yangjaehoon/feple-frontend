import 'dart:typed_data';

//import 'package:cloud_firestore/cloud_firestore.dart';
//import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../../../model/artist_img.dart';

class ImgUpload extends StatefulWidget {
  const ImgUpload({super.key, required this.artistName});

  final String artistName;

  @override
  State<ImgUpload> createState() => _ImgUploadState();
}

class _ImgUploadState extends State<ImgUpload> {
  final _formKey = GlobalKey<FormState>();

  //final db = FirebaseFirestore.instance;
  //final storage = FirebaseStorage.instance;
  Uint8List? imageData;
  XFile? image;

  TextEditingController titleTEC = TextEditingController();
  TextEditingController ftvNameTEC = TextEditingController();

  // 파이어베이스 용량 적으니 일단 압축해서 사진 올려줌
  Future<Uint8List> imageCompressList(Uint8List list) async {
    var result = await FlutterImageCompress.compressWithList(list, quality: 50);
    return result;
  }

  Future addImage() async {
    if (imageData != null) {
      // // storage에 저장할 파일 이름
      // final storageRef = storage.ref().child(
      //     "/artist_img/${widget.artistName}/${widget.artistName}_${DateTime.now().millisecondsSinceEpoch}_${image?.name ?? "??"}");
      // final compressedData = await imageCompressList(imageData!);
      // await storageRef.putData(compressedData);
      // final downloadLink = await storageRef.getDownloadURL();
      // final sampleData = ArtistImg(
      //   title: titleTEC.text,
      //   ftvName: ftvNameTEC.text,
      //   imgUrl: downloadLink,
      //   timestamp: DateTime.now().millisecondsSinceEpoch,
      // );
      // final doc = await db.collection("ArtistImg").add(sampleData.toJson());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("사진 올리기"),
        actions: [
          IconButton(
            onPressed: () {
              // 폼 검증을 수행하여 유효한 경우에만 이미지 추가
              if (_formKey.currentState?.validate() ?? false) {
                addImage();
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

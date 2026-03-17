import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/common/constant/app_colors.dart';
import 'package:fast_app_base/model/FestivalPreview.dart';
import 'package:fast_app_base/network/dio_client.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:fast_app_base/service/artist_photo_service.dart';

import 'w_image_picker_box.dart';

class ImgUpload extends StatefulWidget {
  const ImgUpload(
      {super.key, required this.artistId, required this.artistName});

  final int artistId;
  final String artistName;

  @override
  State<ImgUpload> createState() => _ImgUploadState();
}

const _otherFestival = FestivalPreview(id: -1, title: '기타', location: '', posterUrl: '', startDate: '');

class _ImgUploadState extends State<ImgUpload> {
  final _formKey = GlobalKey<FormState>();
  final _photoService = ArtistPhotoService();

  Uint8List? imageData;
  TextEditingController titleTEC = TextEditingController();
  FestivalPreview? _selectedFestival;
  late final Future<List<FestivalPreview>> _festivalsFuture;
  bool isUploading = false;

  @override
  void initState() {
    super.initState();
    _festivalsFuture = _fetchFestivals();
  }

  Future<List<FestivalPreview>> _fetchFestivals() async {
    final resp = await DioClient.dio.get('/festivals', queryParameters: {'page': 0, 'size': 200});
    final decoded = resp.data;
    final List<dynamic> list = decoded is List ? decoded : (decoded['content'] as List<dynamic>);
    return list.map((e) => FestivalPreview.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      imageData = await image.readAsBytes();
      setState(() {});
    }
  }

  Future<void> _submit() async {
    if (imageData == null) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => isUploading = true);
    try {
      await _photoService.uploadPhoto(
        artistId: widget.artistId,
        imageData: imageData!,
        title: titleTEC.text,
        description: (_selectedFestival == null || _selectedFestival!.id == -1)
            ? ''
            : _selectedFestival!.title,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on DioException catch (e) {
      debugPrint('status=${e.response?.statusCode}');
      debugPrint('data=${e.response?.data}');
    } catch (e) {
      debugPrint('upload error: $e');
    } finally {
      if (mounted) setState(() => isUploading = false);
    }
  }

  @override
  void dispose() {
    titleTEC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('사진 올리기'),
        backgroundColor: colors.appBarColor,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            onPressed: isUploading ? null : _submit,
            icon: isUploading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Icon(Icons.send_rounded),
          ),
        ],
      ),
      backgroundColor: colors.backgroundMain,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            children: [
              ImagePickerBox(
                imageData: imageData,
                onTap: _pickImage,
                label: '아티스트 사진 추가',
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
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: colors.textTitle,
                        ),
                      ),
                    ),
                    TextFormField(
                      controller: titleTEC,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.activate, width: 2),
                        ),
                        labelText: '작품명',
                        hintText: '작품명을 입력하세요.',
                        labelStyle: TextStyle(color: colors.textSecondary),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? '필수 입력 항목입니다.' : null,
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<List<FestivalPreview>>(
                      future: _festivalsFuture,
                      builder: (context, snapshot) {
                        final festivals = snapshot.data ?? [];
                        return DropdownButtonFormField<FestivalPreview>(
                          value: _selectedFestival,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: colors.activate, width: 2),
                            ),
                            labelText: '페스티벌',
                            labelStyle: TextStyle(color: colors.textSecondary),
                          ),
                          hint: snapshot.connectionState != ConnectionState.done
                              ? const Text('불러오는 중...')
                              : const Text('페스티벌을 선택하세요'),
                          items: [
                            ...festivals.map((f) => DropdownMenuItem(
                                  value: f,
                                  child: Text(f.title, overflow: TextOverflow.ellipsis),
                                )),
                            const DropdownMenuItem(
                              value: _otherFestival,
                              child: Text('기타'),
                            ),
                          ],
                          onChanged: (f) => setState(() => _selectedFestival = f),
                          validator: (_) =>
                              _selectedFestival == null ? '페스티벌을 선택해주세요.' : null,
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

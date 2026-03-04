import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/common/constant/app_colors.dart';
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

class _ImgUploadState extends State<ImgUpload> {
  final _formKey = GlobalKey<FormState>();
  final _photoService = ArtistPhotoService();

  Uint8List? imageData;
  TextEditingController titleTEC = TextEditingController();
  TextEditingController ftvNameTEC = TextEditingController();
  bool isUploading = false;

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
        description: ftvNameTEC.text,
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
    ftvNameTEC.dispose();
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
                    TextFormField(
                      controller: ftvNameTEC,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: colors.activate, width: 2),
                        ),
                        labelText: '페스티벌 이름',
                        hintText: '페스티벌 위치나 이름을 입력하세요.',
                        labelStyle: TextStyle(color: colors.textSecondary),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? '필수 입력 항목입니다.' : null,
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

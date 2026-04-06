import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:fast_app_base/common/common.dart';
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

const _dailyFestival = FestivalPreview(
    id: -2, title: '일상 사진', location: '', posterUrl: '', startDate: '');
const _snsFestival = FestivalPreview(
    id: -3, title: 'SNS 사진', location: '', posterUrl: '', startDate: '');
const _otherFestival = FestivalPreview(
    id: -1, title: '기타', location: '', posterUrl: '', startDate: '');

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
    final resp =
        await DioClient.dio.get('/artists/${widget.artistId}/schedule');
    final List<dynamic> list = resp.data as List<dynamic>;
    return list.map((e) {
      final m = e as Map<String, dynamic>;
      return FestivalPreview(
        id: (m['festivalId'] as num).toInt(),
        title: (m['title'] ?? '') as String,
        location: (m['location'] ?? '') as String,
        posterUrl: (m['posterUrl'] ?? '') as String,
        startDate: m['startDate']?.toString() ?? '',
      );
    }).toList();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      imageData = await image.readAsBytes();
      setState(() {});
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    if (imageData == null) {
      _showSnackBar('사진을 선택해주세요.');
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) {
      _showSnackBar('입력하지 않은 항목이 있습니다.');
      return;
    }

    setState(() => isUploading = true);
    try {
      await _photoService.uploadPhoto(
        artistId: widget.artistId,
        imageData: imageData!,
        title: titleTEC.text,
        description:
            _selectedFestival!.id == -1 ? '' : _selectedFestival!.title,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on DioException catch (e) {
      final status = e.response?.statusCode;
      final body = e.response?.data?.toString() ?? '';
      debugPrint('status=$status  data=$body');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('업로드 실패 ($status): $body'),
          duration: const Duration(seconds: 8),
        ),
      );
    } catch (e) {
      debugPrint('upload error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('업로드 중 오류가 발생했습니다.')),
      );
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
                          borderSide:
                              BorderSide(color: colors.activate, width: 2),
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
                          initialValue: _selectedFestival,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide:
                                  BorderSide(color: colors.activate, width: 2),
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
                                  child: Text(f.title,
                                      overflow: TextOverflow.ellipsis),
                                )),
                            const DropdownMenuItem(
                                value: _dailyFestival, child: Text('일상 사진')),
                            const DropdownMenuItem(
                                value: _snsFestival, child: Text('SNS 사진')),
                            const DropdownMenuItem(
                                value: _otherFestival, child: Text('기타')),
                          ],
                          onChanged: (f) =>
                              setState(() => _selectedFestival = f),
                          validator: (_) => _selectedFestival == null
                              ? '페스티벌을 선택해주세요.'
                              : null,
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

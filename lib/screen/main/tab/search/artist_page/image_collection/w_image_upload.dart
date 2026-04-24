import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/photo_category.dart';
import 'package:feple/model/festival_preview.dart';
import 'package:feple/service/artist_schedule_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:feple/service/artist_photo_service.dart';

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
  FestivalPreview? _selectedFestival;
  late final Future<List<FestivalPreview>> _festivalsFuture;
  bool isUploading = false;
  String? _imageError;

  @override
  void initState() {
    super.initState();
    _festivalsFuture = _fetchFestivals();
  }

  Future<List<FestivalPreview>> _fetchFestivals() =>
      ArtistScheduleService.fetchFestivals(widget.artistId);

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      imageData = await image.readAsBytes();
      setState(() => _imageError = null);
    }
  }

  Future<void> _submit() async {
    if (imageData == null) {
      setState(() => _imageError = 'photo_select_required'.tr());
      return;
    }
    setState(() => _imageError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

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
          content: Text('photo_upload_failed_detail'.tr(args: [status.toString(), body])),
          duration: const Duration(seconds: 8),
        ),
      );
    } catch (e) {
      debugPrint('upload error: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('photo_upload_failed'.tr())),
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
        title: Text('photo_upload_title'.tr()),
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
                label: 'artist_photo_add_label'.tr(),
              ),
              if (_imageError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      _imageError!,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
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
                        labelText: 'photo_artwork_label'.tr(),
                        hintText: 'photo_artwork_hint'.tr(),
                        labelStyle: TextStyle(color: colors.textSecondary),
                      ),
                      validator: (v) =>
                          (v == null || v.isEmpty) ? 'required_field'.tr() : null,
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
                            labelText: 'festival_label'.tr(),
                            labelStyle: TextStyle(color: colors.textSecondary),
                          ),
                          hint: snapshot.connectionState != ConnectionState.done
                              ? Text('loading'.tr())
                              : Text('select_festival_hint'.tr()),
                          items: [
                            ...festivals.map((f) => DropdownMenuItem(
                                  value: f,
                                  child: Text(f.title,
                                      overflow: TextOverflow.ellipsis),
                                )),
                            const DropdownMenuItem(
                                value: photoCategoryDaily, child: Text('일상 사진')),
                            const DropdownMenuItem(
                                value: photoCategorySns, child: Text('SNS 사진')),
                            const DropdownMenuItem(
                                value: photoCategoryOther, child: Text('기타')),
                          ],
                          onChanged: (f) =>
                              setState(() => _selectedFestival = f),
                          validator: (_) => _selectedFestival == null
                              ? 'select_festival_required'.tr()
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

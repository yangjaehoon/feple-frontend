import 'package:dio/dio.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/confirm_dialog.dart';
import 'package:feple/model/festival_preview.dart';
import 'package:feple/model/photo_destination.dart';
import 'package:feple/service/artist_schedule_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:feple/injection.dart';
import 'package:feple/service/artist_photo_uploadable.dart';

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
  final _photoService = sl<ArtistPhotoUploadable>();
  final _scheduleService = sl<ArtistScheduleService>();

  Uint8List? imageData;
  final TextEditingController _titleCtrl = TextEditingController();
  PhotoDestination? _selectedDestination;
  late final Future<List<FestivalPreview>> _festivalsFuture;
  bool isUploading = false;
  bool _isAnonymous = false;
  String? _imageError;

  bool get _isDirty => imageData != null || _titleCtrl.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _festivalsFuture = _fetchFestivals();
  }

  Future<List<FestivalPreview>> _fetchFestivals() =>
      _scheduleService.fetchFestivals(widget.artistId);

  Future<void> _pickImage() async {
    try {
      final picker = ImagePicker();
      final image = await picker.pickImage(source: ImageSource.gallery);
      if (image != null) {
        imageData = await image.readAsBytes();
        if (mounted) setState(() => _imageError = null);
      }
    } on PlatformException catch (e) {
      debugPrint('image pick error: $e');
      if (mounted) context.showErrorSnackbar('photo_pick_failed'.tr());
    }
  }

  Future<void> _submit() async {
    if (imageData == null) {
      setState(() => _imageError = 'photo_select_required'.tr());
      return;
    }
    setState(() => _imageError = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final destination = _selectedDestination;
    if (destination == null) return;
    setState(() => isUploading = true);
    try {
      await _photoService.uploadPhoto(
        artistId: widget.artistId,
        imageData: imageData!,
        title: _titleCtrl.text,
        description: destination.description,
        isAnonymous: _isAnonymous,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } on DioException catch (e) {
      debugPrint('photo upload error: status=${e.response?.statusCode} data=${e.response?.data}');
      if (!mounted) return;
      context.showErrorSnackbar('photo_upload_failed_detail'.tr());
    } catch (e) {
      debugPrint('upload error: $e');
      if (!mounted) return;
      context.showErrorSnackbar('photo_upload_failed'.tr());
    } finally {
      if (mounted) setState(() => isUploading = false);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  Future<void> _onPopInvoked(bool didPop) async {
    if (didPop) return;
    if (isUploading) return;
    if (!_isDirty) { Navigator.of(context).pop(); return; }
    final ctx = context;
    final confirmed = await showConfirmDialog(
      ctx,
      title: 'discard_changes'.tr(),
      content: 'discard_changes_msg'.tr(),
      confirmLabel: 'discard'.tr(),
    );
    if (confirmed && ctx.mounted) Navigator.of(ctx).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) => _onPopInvoked(didPop),
      child: Scaffold(
        backgroundColor: colors.backgroundMain,
        body: Column(
          children: [
            _buildCustomAppBar(colors),
            _buildScrollContent(colors),
          ],
        ),
      ),
    );
  }

  Widget _buildCustomAppBar(AbstractThemeColors colors) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: AppDimens.appBarHeight,
        color: colors.appBarColor,
        child: Row(
          children: [
            IconButton(
              tooltip: 'back'.tr(),
              icon: Icon(Icons.arrow_back_ios_rounded, color: colors.appBarIconColor),
              onPressed: () => Navigator.pop(context),
            ),
            Expanded(
              child: Text(
                'photo_upload_title'.tr(),
                style: TextStyle(
                  color: colors.appBarIconColor,
                  fontSize: AppDimens.fontSizeTitle,
                  fontWeight: FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            IconButton(
              tooltip: 'submit'.tr(),
              onPressed: isUploading ? null : _submit,
              icon: isUploading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: colors.appBarIconColor))
                  : Icon(Icons.send_rounded, color: colors.appBarIconColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTitleField(AbstractThemeColors colors) {
    return TextFormField(
      controller: _titleCtrl,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny)),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
          borderSide: BorderSide(color: colors.activate, width: 2),
        ),
        labelText: 'photo_artwork_label'.tr(),
        hintText: 'photo_artwork_hint'.tr(),
        labelStyle: TextStyle(color: colors.textSecondary),
      ),
      validator: (v) => (v == null || v.isEmpty) ? 'required_field'.tr() : null,
    );
  }

  Widget _buildFestivalDropdown(AbstractThemeColors colors) {
    return FutureBuilder<List<FestivalPreview>>(
      future: _festivalsFuture,
      builder: (context, snapshot) {
        final festivals = snapshot.data ?? [];
        return DropdownButtonFormField<PhotoDestination>(
          initialValue: _selectedDestination,
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny)),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
              borderSide: BorderSide(color: colors.activate, width: 2),
            ),
            labelText: 'festival_label'.tr(),
            labelStyle: TextStyle(color: colors.textSecondary),
          ),
          hint: snapshot.connectionState != ConnectionState.done
              ? Text('loading'.tr())
              : Text('select_festival_hint'.tr()),
          items: [
            ...festivals.map((f) => DropdownMenuItem(
                  value: FestivalDestination(f),
                  child: Text(f.displayTitle(context.isEnglish), overflow: TextOverflow.ellipsis),
                )),
            ...PhotoDestination.categories.map((c) => DropdownMenuItem(
                  value: c,
                  child: Text(c.labelKey.tr()),
                )),
          ],
          onChanged: (d) => setState(() => _selectedDestination = d),
          validator: (_) => _selectedDestination == null ? 'select_festival_required'.tr() : null,
        );
      },
    );
  }

  Widget _buildAnonymousToggle(AbstractThemeColors colors) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: _isAnonymous,
      onChanged: (v) => setState(() => _isAnonymous = v),
      activeThumbColor: colors.activate,
      title: Text(
        'post_anonymous'.tr(),
        style: TextStyle(fontSize: AppDimens.fontSizeMd, color: colors.textTitle),
      ),
    );
  }

  Widget _buildScrollContent(AbstractThemeColors colors) {
    return Expanded(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: Column(
            children: [
              _buildImagePicker(colors),
              _buildForm(colors),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker(AbstractThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                style: TextStyle(
                  fontSize: AppDimens.fontSizeXs,
                  color: colors.error,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildForm(AbstractThemeColors colors) {
    return Form(
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
          _buildTitleField(colors),
          const SizedBox(height: 12),
          _buildFestivalDropdown(colors),
          const SizedBox(height: 4),
          _buildAnonymousToggle(colors),
        ],
      ),
    );
  }
}

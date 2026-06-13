import 'dart:typed_data';

import 'package:feple/common/common.dart';
import 'package:feple/common/util/bottom_sheet_helper.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/dio_error_helper.dart';
import 'package:feple/common/widget/w_bottom_sheet_handle.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/festival_model.dart';
import 'package:feple/service/certification_service.dart';
import 'package:feple/service/festival_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

class SubmitCertificationSheet extends StatefulWidget {
  final CertificationService certService;

  const SubmitCertificationSheet({super.key, required this.certService});

  @override
  State<SubmitCertificationSheet> createState() =>
      _SubmitCertificationSheetState();
}

class _SubmitCertificationSheetState extends State<SubmitCertificationSheet> {
  List<FestivalModel> _festivals = [];
  FestivalModel? _selectedFestival;
  bool _loadingFestivals = true;
  bool _festivalLoadError = false;
  bool _submitting = false;
  bool _submitSuccess = false;

  @override
  void initState() {
    super.initState();
    _loadFestivals();
  }

  Future<void> _loadFestivals() async {
    if (mounted) setState(() { _loadingFestivals = true; _festivalLoadError = false; });
    try {
      final festivals = await sl<FestivalService>().fetchAll();
      if (mounted) setState(() { _festivals = festivals; _loadingFestivals = false; });
    } catch (_) {
      if (mounted) setState(() { _loadingFestivals = false; _festivalLoadError = true; });
    }
  }

  Future<void> _showFestivalSearchSheet() async {
    final result = await showAppBottomSheet<FestivalModel>(
      context,
      builder: (_) => _FestivalSearchSheet(festivals: _festivals),
    );
    if (!mounted) return;
    if (result != null) {
      setState(() => _selectedFestival = result);
    }
  }

  Future<void> _submit() async {
    if (_selectedFestival == null) {
      context.showInfoSnackbar('select_festival_required_msg'.tr());
      return;
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1920,
      maxHeight: 1920,
    );
    if (picked == null || !mounted) return;

    setState(() => _submitting = true);
    try {
      final Uint8List imageData = await picked.readAsBytes();
      await widget.certService.submit(
        festivalId: _selectedFestival!.id,
        imageData: imageData,
      );
      if (!mounted) return;
      setState(() { _submitting = false; _submitSuccess = true; });
      await Future.delayed(AppDimens.animSuccessDelay);
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      debugPrint('cert submit error: $e');
      context.showErrorSnackbar(networkAwareErrorKey(
        e,
        isDioConflict(e) ? 'cert_already_submitted' : 'cert_submit_failed',
      ).tr());
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.backgroundMain,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom +
            kBottomNavigationBarHeight +
            MediaQuery.of(context).padding.bottom +
            24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 12),
          const BottomSheetHandle(),
          _buildSheetHeader(colors),
          _buildFestivalSelector(colors),
          const SizedBox(height: 16),
          _buildSubmitButton(colors),
        ],
      ),
    );
  }

  Widget _buildSheetHeader(AbstractThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
          child: Text(
            'cert_submit_title'.tr(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: colors.textTitle,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
          child: Text(
            'cert_photo_guide'.tr(),
            style: TextStyle(
                fontSize: 13, color: colors.textSecondary, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildFestivalSelector(AbstractThemeColors colors) {
    if (_loadingFestivals) {
      return const Padding(
        padding: EdgeInsets.all(20),
        child: Center(child: CircularProgressIndicator.adaptive()),
      );
    }
    if (_festivalLoadError) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: AppColors.errorRed, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'err_fetch_data'.tr(),
                style: TextStyle(fontSize: 13, color: colors.textSecondary),
              ),
            ),
            TextButton(
              onPressed: _loadFestivals,
              child: Text('retry'.tr(), style: TextStyle(color: colors.activate, fontSize: 13)),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: InkWell(
        onTap: _showFestivalSearchSheet,
        borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: 'tab_concert'.tr(),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
            ),
            contentPadding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 12),
            suffixIcon: const Icon(Icons.arrow_drop_down),
          ),
          isEmpty: _selectedFestival == null,
          child: Text(
            _selectedFestival?.title ?? '',
            style: const TextStyle(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _buildSubmitButton(AbstractThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: LoadingButton(
        label: 'cert_select_photo'.tr(),
        icon: Icons.add_photo_alternate_rounded,
        isLoading: _submitting,
        isSuccess: _submitSuccess,
        onPressed: _submit,
        backgroundColor: colors.certRingColor,
        height: 50,
        borderRadius: 12,
      ),
    );
  }
}

class _FestivalSearchSheet extends StatefulWidget {
  final List<FestivalModel> festivals;

  const _FestivalSearchSheet({required this.festivals});

  @override
  State<_FestivalSearchSheet> createState() => _FestivalSearchSheetState();
}

class _FestivalSearchSheetState extends State<_FestivalSearchSheet> {
  late List<FestivalModel> _filtered;
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _filtered = widget.festivals;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch(String query) {
    setState(() {
      _filtered = widget.festivals
          .where((f) => f.title.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      maxChildSize: 0.9,
      minChildSize: 0.4,
      expand: false,
      builder: (ctx, scrollCtrl) {
        return Container(
          decoration: BoxDecoration(
            color: colors.backgroundMain,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              const BottomSheetHandle(),
              _buildSearchField(colors),
              Expanded(child: _buildFestivalList(ctx, scrollCtrl, colors)),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchField(AbstractThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: TextField(
        controller: _searchCtrl,
        autofocus: true,
        onChanged: _onSearch,
        decoration: InputDecoration(
          hintText: 'festival_search_hint'.tr(),
          prefixIcon: const Icon(Icons.search),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
          ),
          contentPadding: const EdgeInsets.symmetric(
              horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildFestivalList(BuildContext ctx,
      ScrollController scrollCtrl, AbstractThemeColors colors) {
    if (_filtered.isEmpty) {
      return Center(
        child: Text(
          'search_no_result'.tr(),
          style: TextStyle(color: colors.textSecondary),
        ),
      );
    }
    return ListView.builder(
      controller: scrollCtrl,
      itemCount: _filtered.length,
      itemBuilder: (_, index) {
        final festival = _filtered[index];
        return ListTile(
          title: Text(
            festival.title,
            style: const TextStyle(fontSize: 14),
          ),
          onTap: () => Navigator.pop(ctx, festival),
        );
      },
    );
  }
}

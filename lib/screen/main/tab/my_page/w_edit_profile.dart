import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/exception/banned_word_exception.dart';
import 'package:feple/common/util/dio_error_helper.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/common/widget/w_nickname_field.dart';
import 'package:feple/injection.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/service/user_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class EditProfileWidget extends StatefulWidget {
  const EditProfileWidget({super.key});

  @override
  State<EditProfileWidget> createState() => _EditProfileWidgetState();
}

class _EditProfileWidgetState extends State<EditProfileWidget> {
  XFile? _pickedImage;
  bool _isSaving = false;
  String _originalNickname = '';

  final _nicknameKey = GlobalKey<NicknameFieldState>();
  final _bioController = TextEditingController();
  String? _bioError;

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>().user;
    if (user != null) {
      _originalNickname = user.nickname;
      _bioController.text = user.bio ?? '';
    }
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked != null && mounted) setState(() => _pickedImage = picked);
  }

  Future<void> _save() async {
    final userProvider = context.read<UserProvider>();
    final user = userProvider.user;
    if (user == null) return;

    final nicknameState = _nicknameKey.currentState;
    final newNickname = nicknameState?.currentNickname ?? '';
    if (newNickname.isEmpty) {
      nicknameState?.showError('enter_nickname'.tr());
      return;
    }
    if (newNickname.length < 2 || newNickname.length > 8) {
      nicknameState?.showError('nickname_length_error'.tr());
      return;
    }

    // 닉네임이 변경된 경우 중복 확인 필수
    if (newNickname != _originalNickname) {
      if (nicknameState?.available == null || nicknameState?.lastCheckedNickname != newNickname) {
        nicknameState?.showError('nickname_check_req'.tr());
        return;
      }
      if (nicknameState?.available == false) {
        nicknameState?.showError('nickname_invalid'.tr());
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      final userService = sl<UserService>();

      final pickedImage = _pickedImage;
      if (pickedImage != null) {
        await userService.updateProfileImage(user.id, pickedImage);
      }

      if (newNickname != user.nickname) {
        await userService.updateNickname(user.id, newNickname);
      }

      final newBio = _bioController.text.trim();
      if (newBio != (user.bio ?? '')) {
        await userService.updateBio(user.id, newBio);
      }

      await userProvider.fetchUser(user.id);

      if (!mounted) return;
      context.showSuccessSnackbar('profile_updated'.tr());
      Navigator.of(context).pop();
    } on BannedWordException {
      if (!mounted) return;
      setState(() => _bioError = 'bio_banned_word'.tr());
    } catch (e) {
      // 일부 항목이 이미 저장됐을 수 있으므로 서버 상태와 동기화
      try { await userProvider.fetchUser(user.id); } catch (_) {}
      if (!mounted) return;
      debugPrint('profile save error: $e');
      context.showErrorSnackbar(networkAwareErrorKey(e, 'save_failed').tr());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    // profileImageUrl·userId만 구독 — 다른 UserProvider 상태 변경 시 재빌드 안 함
    final (profileImageUrl, userId) = context.select<UserProvider, (String?, int?)>(
      (p) => (p.currentProfileImageUrl, p.currentUserId),
    );

    return Scaffold(
      backgroundColor: colors.backgroundMain,
      body: Column(
        children: [
          SecondaryAppBar(
            title: 'edit_profile'.tr(),
            actions: [_buildSaveAction()],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
              child: Column(
                children: [
                  _buildProfileImage(colors, profileImageUrl),
                  const SizedBox(height: 36),
                  _buildNicknameSection(colors, userId),
                  const SizedBox(height: 24),
                  _buildBioSection(colors),
                  const SizedBox(height: 40),
                  LoadingButton(
                    label: 'save'.tr(),
                    onPressed: _save,
                    isLoading: _isSaving,
                    backgroundColor: colors.activate,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSaveAction() {
    return TextButton(
      onPressed: _isSaving ? null : _save,
      child: _isSaving
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            )
          : Text(
              'save'.tr(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            ),
    );
  }

  Widget _buildProfileImage(AbstractThemeColors colors, String? profileImageUrl) {
    return Column(
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Stack(
            children: [
              _buildAvatarRing(profileImageUrl, colors),
              Positioned(bottom: 4, right: 4, child: _buildCameraOverlay(colors)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text('change_photo'.tr(), style: TextStyle(fontSize: 13, color: colors.textSecondary)),
      ],
    );
  }

  Widget _buildAvatarRing(String? profileImageUrl, AbstractThemeColors colors) {
    return Container(
      width: 110,
      height: 110,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colors.profileRingColor,
        boxShadow: [
          BoxShadow(
            color: colors.cardShadow.withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Container(
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(shape: BoxShape.circle, color: colors.surface),
        child: CircleAvatar(
          radius: 48,
          backgroundColor: colors.backgroundMain,
          backgroundImage: _pickedImage != null
              ? FileImage(File(_pickedImage!.path)) as ImageProvider
              : (profileImageUrl != null && profileImageUrl.isNotEmpty)
                  ? CachedNetworkImageProvider(profileImageUrl) as ImageProvider
                  : const AssetImage('assets/image/feple_logo.png'),
          child: null,
        ),
      ),
    );
  }

  Widget _buildCameraOverlay(AbstractThemeColors colors) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: colors.activate,
        shape: BoxShape.circle,
        border: Border.all(color: colors.surface, width: 2),
      ),
      child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 15),
    );
  }

  Widget _buildNicknameSection(AbstractThemeColors colors, int? userId) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'nickname'.tr(),
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textSecondary),
        ),
        const SizedBox(height: 8),
        NicknameField(
          key: _nicknameKey,
          excludeUserId: userId,
          initialValue: _originalNickname,
        ),
      ],
    );
  }

  Widget _buildBioSection(AbstractThemeColors colors) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'bio'.tr(),
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: colors.textSecondary),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _bioController,
          maxLength: 150,
          maxLines: 3,
          onChanged: (_) {
            if (_bioError != null) setState(() => _bioError = null);
          },
          decoration: InputDecoration(
            hintText: 'bio_hint'.tr(),
            hintStyle: TextStyle(color: colors.textSecondary, fontSize: 13),
            counterStyle: TextStyle(color: colors.textSecondary, fontSize: 11),
            errorText: _bioError,
            border: OutlineInputBorder(borderSide: BorderSide(color: colors.listDivider)),
            enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: colors.listDivider)),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: colors.activate, width: 1.5),
            ),
            errorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.errorRed, width: 1.5),
            ),
            focusedErrorBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: AppColors.errorRed, width: 2),
            ),
          ),
          style: TextStyle(color: colors.textTitle, fontSize: 14),
        ),
      ],
    );
  }
}

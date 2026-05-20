import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:dio/dio.dart';
import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/common/widget/w_nickname_field.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/user_model.dart';
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

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>().user;
    if (user != null) {
      _originalNickname = user.nickname;
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked != null) setState(() => _pickedImage = picked);
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
      User updated = user;

      final userService = sl<UserService>();

      final pickedImage = _pickedImage;
      if (pickedImage != null) {
        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(
            pickedImage.path,
            filename: pickedImage.name,
          ),
        });
        updated = await userService.updateProfileImage(user.id, formData);
      }

      if (newNickname != user.nickname) {
        updated = await userService.updateNickname(user.id, newNickname);
      }

      await userProvider.setUser(updated);

      if (!mounted) return;
      context.showSuccessSnackbar('profile_updated'.tr());
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      debugPrint('profile save error: $e');
      context.showErrorSnackbar('save_failed'.tr());
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    // profileImageUrl·userId만 구독 — 다른 UserProvider 상태 변경 시 재빌드 안 함
    final (profileImageUrl, userId) = context.select<UserProvider, (String?, int?)>(
      (p) => (p.user?.profileImageUrl, p.user?.id),
    );

    return Scaffold(
      backgroundColor: colors.backgroundMain,
      body: Column(
        children: [
          SecondaryAppBar(
            title: 'edit_profile'.tr(),
            actions: [
              TextButton(
                onPressed: _isSaving ? null : _save,
                child: _isSaving
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'save'.tr(),
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700),
                      ),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Column(
          children: [
            // ── 프로필 사진 ──
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  Container(
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
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.surface,
                      ),
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: colors.backgroundMain,
                        backgroundImage: _pickedImage != null
                            ? FileImage(File(_pickedImage!.path))
                                as ImageProvider
                            : (profileImageUrl != null &&
                                    profileImageUrl.isNotEmpty)
                                ? CachedNetworkImageProvider(profileImageUrl)
                                    as ImageProvider
                                : const AssetImage(
                                    'assets/image/feple_logo.png'),
                        child: null,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 4,
                    right: 4,
                    child: Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: colors.activate,
                        shape: BoxShape.circle,
                        border: Border.all(color: colors.surface, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt_rounded,
                          color: Colors.white, size: 15),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'change_photo'.tr(),
              style: TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
            const SizedBox(height: 36),

            // ── 닉네임 ──
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'nickname'.tr(),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: NicknameField(
                    key: _nicknameKey,
                    excludeUserId: userId,
                    initialValue: _originalNickname,
                    onResult: (_, __) {},
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),

            // ── 저장 버튼 ──
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
}

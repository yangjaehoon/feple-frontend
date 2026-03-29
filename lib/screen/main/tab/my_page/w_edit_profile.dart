import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/model/user_model.dart';
import 'package:fast_app_base/network/dio_client.dart';
import 'package:fast_app_base/provider/user_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class EditProfileWidget extends StatefulWidget {
  const EditProfileWidget({super.key});

  @override
  State<EditProfileWidget> createState() => _EditProfileWidgetState();
}

class _EditProfileWidgetState extends State<EditProfileWidget> {
  final _nicknameController = TextEditingController();
  XFile? _pickedImage;
  bool _isSaving = false;

  // 닉네임 중복 확인 상태
  bool _isCheckingNickname = false;
  bool? _nicknameAvailable; // null=미확인 or 현재 닉네임, true=사용가능, false=불가
  String _nicknameCheckMessage = '';
  String _lastCheckedNickname = '';
  String _originalNickname = '';

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>().user;
    if (user != null) {
      _nicknameController.text = user.nickname;
      _originalNickname = user.nickname;
    }
  }

  @override
  void dispose() {
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked != null) setState(() => _pickedImage = picked);
  }

  Future<void> _checkNickname() async {
    final userProvider = context.read<UserProvider>();
    final user = userProvider.user;
    final nickname = _nicknameController.text.trim();

    if (nickname.isEmpty) {
      setState(() {
        _nicknameAvailable = false;
        _nicknameCheckMessage = '닉네임을 입력해주세요.';
      });
      return;
    }
    if (nickname.length < 2 || nickname.length > 8) {
      setState(() {
        _nicknameAvailable = false;
        _nicknameCheckMessage = '닉네임은 2자 이상 8자 이하로 입력해주세요.';
      });
      return;
    }

    setState(() => _isCheckingNickname = true);
    try {
      final excludeId = user?.id;
      final resp = await DioClient.dio.get(
        '/users/check-nickname',
        queryParameters: {
          'nickname': nickname,
          if (excludeId != null) 'excludeUserId': excludeId,
        },
      );
      final body = resp.data as Map<String, dynamic>;
      setState(() {
        _nicknameAvailable = body['available'] as bool;
        _nicknameCheckMessage = body['message'] as String;
        _lastCheckedNickname = nickname;
      });
    } catch (e) {
      setState(() {
        _nicknameAvailable = false;
        _nicknameCheckMessage = '확인 중 오류가 발생했습니다.';
      });
    } finally {
      if (mounted) setState(() => _isCheckingNickname = false);
    }
  }

  Future<void> _save() async {
    final userProvider = context.read<UserProvider>();
    final user = userProvider.user;
    if (user == null) return;

    final newNickname = _nicknameController.text.trim();
    if (newNickname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.skyBlue,
          content: Text('닉네임을 입력해주세요.'),
        ),
      );
      return;
    }
    if (newNickname.length < 2 || newNickname.length > 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: AppColors.skyBlue,
          content: Text('닉네임은 2자 이상 8자 이하로 입력해주세요.'),
        ),
      );
      return;
    }

    // 닉네임이 변경된 경우 중복 확인 필수
    if (newNickname != _originalNickname) {
      if (_nicknameAvailable == null || _lastCheckedNickname != newNickname) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            backgroundColor: AppColors.skyBlue,
            content: Text('닉네임 중복 확인을 해주세요.'),
          ),
        );
        return;
      }
      if (_nicknameAvailable == false) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: AppColors.skyBlue,
            content: Text(_nicknameCheckMessage),
          ),
        );
        return;
      }
    }

    setState(() => _isSaving = true);
    try {
      User updated = user;

      // 1. 프로필 이미지 변경
      if (_pickedImage != null) {
        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(
            _pickedImage!.path,
            filename: _pickedImage!.name,
          ),
        });
        final resp = await DioClient.dio.post(
          '/users/${user.id}/profile-image',
          data: formData,
        );
        updated = User.fromJson(resp.data as Map<String, dynamic>);
      }

      // 2. 닉네임 변경
      if (newNickname != user.nickname) {
        final resp = await DioClient.dio.put(
          '/users/${user.id}',
          data: {'nickname': newNickname},
        );
        updated = User.fromJson(resp.data as Map<String, dynamic>);
      }

      await userProvider.setUser(updated);

      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.skyBlue,
          content: Text('profile_updated'.tr()),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.skyBlue,
          content: Text('save_failed'.tr(args: [e.toString()])),
        ),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final user = context.watch<UserProvider>().user;

    return Scaffold(
      appBar: AppBar(
        title: Text('edit_profile'.tr()),
        backgroundColor: colors.appBarColor,
        foregroundColor: Colors.white,
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
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w700),
                  ),
          ),
        ],
      ),
      backgroundColor: colors.backgroundMain,
      body: SingleChildScrollView(
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
                          color: colors.cardShadow.withOpacity(0.2),
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
                            : (user != null &&
                                    user.profileImageUrl != null &&
                                    user.profileImageUrl!.isNotEmpty)
                                ? NetworkImage(user.profileImageUrl!)
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
                        color: AppColors.skyBlue,
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
                  child: TextField(
                    controller: _nicknameController,
                    maxLength: 8,
                    onChanged: (_) {
                      if (_nicknameAvailable != null) {
                        setState(() {
                          _nicknameAvailable = null;
                          _nicknameCheckMessage = '';
                        });
                      }
                    },
                    style: TextStyle(fontSize: 16, color: colors.textTitle),
                    decoration: InputDecoration(
                      counterText: '',
                      hintText: 'nickname_hint'.tr(),
                      hintStyle: TextStyle(color: colors.textSecondary),
                      filled: true,
                      fillColor: colors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                            color: AppColors.skyBlueLight.withOpacity(0.4)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: _nicknameAvailable == false
                              ? Colors.red
                              : _nicknameAvailable == true
                                  ? Colors.green
                                  : AppColors.skyBlueLight.withOpacity(0.4),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide:
                            const BorderSide(color: AppColors.skyBlue, width: 2),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isCheckingNickname ? null : _checkNickname,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.skyBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isCheckingNickname
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('중복 확인',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
            if (_nicknameCheckMessage.isNotEmpty)
              Align(
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: const EdgeInsets.only(top: 6, left: 4),
                  child: Text(
                    _nicknameCheckMessage,
                    style: TextStyle(
                      fontSize: 12,
                      color: _nicknameAvailable == true
                          ? Colors.green
                          : Colors.red,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 40),

            // ── 저장 버튼 ──
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.skyBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isSaving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : Text(
                        'save'.tr(),
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

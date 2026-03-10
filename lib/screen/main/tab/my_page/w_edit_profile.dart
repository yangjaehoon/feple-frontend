import 'dart:io';

import 'package:dio/dio.dart';
import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/common/constant/app_colors.dart';
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

  @override
  void initState() {
    super.initState();
    final user = context.read<UserProvider>().user;
    if (user != null) {
      _nicknameController.text = user.nickname;
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
        const SnackBar(
          backgroundColor: AppColors.skyBlue,
          content: Text('프로필이 수정되었습니다.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.skyBlue,
          content: Text('저장에 실패했습니다.\n$e'),
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
        title: const Text('프로필 수정'),
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
                : const Text(
                    '저장',
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
                            ? FileImage(File(_pickedImage!.path)) as ImageProvider
                            : (user != null && user.profileImageUrl != null && user.profileImageUrl!.isNotEmpty)
                                ? NetworkImage(user.profileImageUrl!) as ImageProvider
                                : const AssetImage('assets/image/feple_logo.png'),
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
              '사진 변경',
              style:
                  TextStyle(fontSize: 13, color: colors.textSecondary),
            ),
            const SizedBox(height: 36),

            // ── 닉네임 ──
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '닉네임',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: colors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _nicknameController,
              style: TextStyle(fontSize: 16, color: colors.textTitle),
              decoration: InputDecoration(
                hintText: 'ex) 페벌러',
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
                      color: AppColors.skyBlueLight.withOpacity(0.4)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      const BorderSide(color: AppColors.skyBlue, width: 2),
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
                    : const Text(
                        '저장',
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

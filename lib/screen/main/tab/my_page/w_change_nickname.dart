import 'package:fast_app_base/common/common.dart';
import 'package:fast_app_base/common/constant/app_colors.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../model/user_model.dart';
import '../../../../network/dio_client.dart';
import '../../../../provider/user_provider.dart';

class ChangeNickname extends StatefulWidget {
  const ChangeNickname({super.key});

  @override
  State<ChangeNickname> createState() => _ChangeNicknameState();
}

class _ChangeNicknameState extends State<ChangeNickname> {
  final nicknameController = TextEditingController();

  @override
  void dispose() {
    nicknameController.dispose();
    super.dispose();
  }

  Future<void> _updateNickname(UserProvider userProvider, int id) async {
    final nickname = nicknameController.text.trim();

    final resp = await DioClient.dio.put(
      '/users/$id',
      data: {'nickname': nickname},
    );

    final updated = User.fromJson(resp.data as Map<String, dynamic>);
    await userProvider.setUser(updated);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    UserProvider userProvider = Provider.of<UserProvider>(context);
    User? user = userProvider.user;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('닉네임 변경'),
        backgroundColor: colors.appBarColor,
        foregroundColor: Colors.white,
      ),
      backgroundColor: colors.backgroundMain,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.person_outline_rounded,
              size: 56,
              color: AppColors.skyBlue,
            ),
            const SizedBox(height: 16),
            Text(
              '변경할 닉네임을 입력해주세요',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.textTitle,
              ),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: nicknameController,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                color: colors.textTitle,
                fontWeight: FontWeight.w600,
              ),
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
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: () async {
                  if (nicknameController.text.trim().isEmpty) return;
                  try {
                    await _updateNickname(userProvider, user!.id);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          backgroundColor: AppColors.skyBlue,
                          content: Text('닉네임이 변경되었습니다.')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          backgroundColor: AppColors.skyBlue,
                          content: Text('닉네임 변경에 실패했습니다.\n$e')),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.skyBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  '확인',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

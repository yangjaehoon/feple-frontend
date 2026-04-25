import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_loading_button.dart';
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
  bool _isSaving = false;

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
        title: Text('change_nickname'.tr()),
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
              color: colors.activate,
            ),
            const SizedBox(height: 16),
            Text(
              'enter_new_nickname'.tr(),
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
                hintText: 'nickname_hint'.tr(),
                hintStyle: TextStyle(color: colors.textSecondary),
                filled: true,
                fillColor: colors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                      color: colors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(
                      color: colors.divider),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide:
                      BorderSide(color: colors.focusedBorder, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            LoadingButton(
              label: 'confirm'.tr(),
              isLoading: _isSaving,
              backgroundColor: colors.activate,
              onPressed: () async {
                if (nicknameController.text.trim().isEmpty) return;
                setState(() => _isSaving = true);
                try {
                  if (user == null) return;
                  await _updateNickname(userProvider, user.id);
                  if (!context.mounted) return;
                  context.showSuccessSnackbar('nickname_changed'.tr());
                  Navigator.pop(context);
                } catch (e) {
                  if (!context.mounted) return;
                  context.showErrorSnackbar('nickname_change_failed'.tr(args: [e.toString()]));
                } finally {
                  if (mounted) setState(() => _isSaving = false);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}

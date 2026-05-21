import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_keyboard_dismiss.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:feple/injection.dart';
import 'package:feple/service/user_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../../model/user_model.dart';
import '../../../../provider/user_provider.dart';

class ChangeNickname extends StatefulWidget {
  const ChangeNickname({super.key});

  @override
  State<ChangeNickname> createState() => _ChangeNicknameState();
}

class _ChangeNicknameState extends State<ChangeNickname> {
  final _userService = sl<UserService>();
  final nicknameController = TextEditingController();
  bool _isSaving = false;
  bool _isSuccess = false;
  String? _errorText;

  @override
  void dispose() {
    nicknameController.dispose();
    super.dispose();
  }

  Future<void> _updateNickname(UserProvider userProvider, int id) async {
    final nickname = nicknameController.text.trim();
    await _userService.updateNickname(id, nickname);
    await userProvider.fetchUser(id);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    UserProvider userProvider = Provider.of<UserProvider>(context);
    User? user = userProvider.user;

    return Scaffold(
      backgroundColor: colors.backgroundMain,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: Container(
              height: AppDimens.appBarHeight,
              color: colors.appBarColor,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Text(
                      'change_nickname'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: KeyboardDismiss(
        child: Padding(
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
              onChanged: (_) {
                if (_errorText != null) setState(() => _errorText = null);
              },
              style: TextStyle(
                fontSize: 18,
                color: colors.textTitle,
                fontWeight: FontWeight.w600,
              ),
              decoration: InputDecoration(
                hintText: 'nickname_hint'.tr(),
                hintStyle: TextStyle(color: colors.textSecondary),
                errorText: _errorText,
                filled: true,
                fillColor: colors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.shapeInput),
                  borderSide: BorderSide(color: colors.divider),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.shapeInput),
                  borderSide: BorderSide(color: colors.divider),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.shapeInput),
                  borderSide: const BorderSide(color: AppColors.errorRed, width: 1.5),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.shapeInput),
                  borderSide: const BorderSide(color: AppColors.errorRed, width: 2),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(AppDimens.shapeInput),
                  borderSide: BorderSide(color: colors.focusedBorder, width: 2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            LoadingButton(
              label: 'confirm'.tr(),
              isLoading: _isSaving,
              isSuccess: _isSuccess,
              backgroundColor: colors.activate,
              onPressed: () async {
                if (nicknameController.text.trim().isEmpty) return;
                setState(() => _isSaving = true);
                try {
                  if (user == null) return;
                  await _updateNickname(userProvider, user.id);
                  if (!mounted) return;
                  setState(() { _isSaving = false; _isSuccess = true; });
                  await Future.delayed(AppDimens.animSuccessDelay);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                } catch (e) {
                  if (mounted) {
                    setState(() {
                      _isSaving = false;
                      debugPrint('nickname change error: $e');
                      _errorText = 'nickname_change_failed'.tr();
                    });
                  }
                }
              },
            ),
          ],
        ),
      ),
        ),
          ),
        ],
      ),
    );
  }
}

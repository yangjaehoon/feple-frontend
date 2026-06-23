import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/nickname_check_result.dart';
import 'package:feple/service/user_service.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:flutter/material.dart';

/// signup, edit_profile, change_nickname에서 공통으로 사용하는
/// 닉네임 입력 + 중복확인 위젯.
class NicknameField extends StatefulWidget {
  /// 프로필 수정 시 자기 자신을 제외하기 위한 사용자 ID
  final int? excludeUserId;

  /// 외부에서 초기값을 설정할 때 사용
  final String initialValue;

  const NicknameField({
    super.key,
    this.excludeUserId,
    this.initialValue = '',
  });

  @override
  State<NicknameField> createState() => NicknameFieldState();
}

class NicknameFieldState extends State<NicknameField> {
  final _userService = sl<UserService>();
  late final TextEditingController controller;
  bool _isChecking = false;
  bool? _available;
  String _message = '';
  String _lastChecked = '';

  @override
  void initState() {
    super.initState();
    controller = TextEditingController(text: widget.initialValue);
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  bool? get available => _available;
  String get lastCheckedNickname => _lastChecked;
  String get currentNickname => controller.text.trim();

  void showError(String msg) {
    _setResult(false, msg);
  }

  Future<void> checkNickname() async {
    final nickname = controller.text.trim();
    if (nickname.isEmpty) {
      _setResult(false, 'enter_nickname'.tr());
      return;
    }
    if (nickname.length < NicknameCheckResult.minLength ||
        nickname.length > NicknameCheckResult.maxLength) {
      _setResult(false, 'nickname_length_error'.tr());
      return;
    }

    setState(() => _isChecking = true);
    try {
      final result = await _userService.checkNicknameAvailability(
        nickname,
        excludeUserId: widget.excludeUserId,
      );
      final localizedMsg = result.available
          ? 'nickname_available'.tr()
          : switch (result.code) {
              'DUPLICATE' => 'nickname_already_in_use'.tr(),
              'INVALID_FORMAT' => 'nickname_invalid_chars'.tr(),
              'BAD_WORD' => 'nickname_bad_word'.tr(),
              _ => 'nickname_invalid'.tr(),
            };
      _setResult(result.available, localizedMsg);
      _lastChecked = nickname;
    } catch (e) {
      debugPrint('[NicknameField] check failed: $e');
      _setResult(false, 'nickname_check_error'.tr());
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  void _setResult(bool? avail, String msg) {
    setState(() {
      _available = avail;
      _message = msg;
    });
  }

  void _onTextChanged(String _) {
    if (_available != null) {
      setState(() {
        _available = null;
        _message = '';
      });
    }
  }

  Widget _buildTextField(AbstractThemeColors colors) {
    return TextField(
      controller: controller,
      maxLength: NicknameCheckResult.maxLength,
      onChanged: _onTextChanged,
      style: TextStyle(fontSize: AppDimens.fontSizeLg, color: colors.text),
      decoration: InputDecoration(
        counterText: '',
        prefixIcon: Icon(Icons.badge_outlined, color: colors.activate, size: 22),
        hintText: 'nickname_hint_format'.tr(),
        hintStyle: TextStyle(color: colors.hintText, fontSize: AppDimens.fontSizeLg),
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
          borderSide: BorderSide(color: colors.divider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
          borderSide: BorderSide(
            color: _available == false
                ? colors.error
                : _available == true
                    ? colors.activate
                    : colors.divider,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimens.cardRadiusTiny),
          borderSide: BorderSide(color: colors.focusedBorder, width: 2),
        ),
      ),
    );
  }

  Widget _buildCheckButton(AbstractThemeColors colors) {
    return LoadingButton(
      label: 'check_duplication'.tr(),
      onPressed: _isChecking ? null : checkNickname,
      isLoading: _isChecking,
      backgroundColor: colors.activate,
      height: 52,
      borderRadius: 12,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildTextField(colors)),
            const SizedBox(width: 8),
            IntrinsicWidth(child: _buildCheckButton(colors)),
          ],
        ),
        if (_message.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              _message,
              style: TextStyle(
                fontSize: AppDimens.fontSizeXs,
                color: _available == true ? colors.activate : colors.error,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

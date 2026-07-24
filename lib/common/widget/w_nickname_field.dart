import 'package:feple/common/common.dart';
import 'package:feple/common/widget/app_input_border.dart';
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

  /// 닉네임 가용 여부가 변경될 때마다 호출됨 (null=초기화/수정중, true=사용가능, false=사용불가)
  final void Function(bool? available)? onStateChanged;

  const NicknameField({
    super.key,
    this.excludeUserId,
    this.initialValue = '',
    this.onStateChanged,
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
    if (!NicknameCheckResult.isValidLength(nickname)) {
      _setResult(false, 'nickname_length_error'.tr());
      return;
    }

    setState(() => _isChecking = true);
    try {
      final result = await _userService.checkNicknameAvailability(
        nickname,
        excludeUserId: widget.excludeUserId,
      );
      if (!mounted) return;
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
      if (mounted) _setResult(false, 'nickname_check_error'.tr());
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  void _setResult(bool? avail, String msg) {
    setState(() {
      _available = avail;
      _message = msg;
    });
    widget.onStateChanged?.call(avail);
  }

  void _onTextChanged(String _) {
    if (_available != null) {
      setState(() {
        _available = null;
        _message = '';
      });
      widget.onStateChanged?.call(null);
    }
  }

  Widget _buildTextField(AbstractThemeColors colors) {
    return TextField(
      controller: controller,
      maxLength: NicknameCheckResult.maxLength,
      onChanged: _onTextChanged,
      textInputAction: TextInputAction.next,
      // 이 필드는 다음 필드로 넘어가기 전에 중복확인이 선행돼야 하므로,
      // 키보드의 "다음" 액션은 포커스 이동 대신 중복확인 버튼과 동일한 동작을 트리거
      onSubmitted: (_) {
        if (!_isChecking) checkNickname();
      },
      autofillHints: const [AutofillHints.nickname],
      style: TextStyle(fontSize: AppDimens.fontSizeLg, color: colors.text),
      decoration: InputDecoration(
        counterText: '',
        prefixIcon: Icon(
          Icons.badge_outlined,
          color: colors.activate,
          size: 22,
        ),
        hintText: 'nickname_hint_format'.tr(),
        hintStyle: TextStyle(
          color: colors.hintText,
          fontSize: AppDimens.fontSizeLg,
        ),
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: appInputBorder(colors.divider),
        enabledBorder: appInputBorder(
          _available == false
              ? colors.error
              : _available == true
              ? colors.activate
              : colors.divider,
        ),
        focusedBorder: appInputBorder(colors.focusedBorder, width: 2),
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

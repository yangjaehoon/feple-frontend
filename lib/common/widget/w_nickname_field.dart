import 'package:fast_app_base/common/constant/app_colors.dart';
import 'package:fast_app_base/network/dio_client.dart';
import 'package:flutter/material.dart';

/// signup, edit_profile, change_nickname에서 공통으로 사용하는
/// 닉네임 입력 + 중복확인 위젯.
class NicknameField extends StatefulWidget {
  /// 프로필 수정 시 자기 자신을 제외하기 위한 사용자 ID
  final int? excludeUserId;

  /// 외부에서 초기값을 설정할 때 사용
  final String initialValue;

  /// 중복 확인 결과가 변경될 때 호출됨
  /// - `available == true && nickname` : 사용 가능한 닉네임
  /// - `available == false` : 사용 불가
  /// - `available == null` : 아직 확인 전
  final void Function(bool? available, String nickname) onResult;

  const NicknameField({
    super.key,
    this.excludeUserId,
    this.initialValue = '',
    required this.onResult,
  });

  @override
  State<NicknameField> createState() => NicknameFieldState();
}

class NicknameFieldState extends State<NicknameField> {
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

  /// 닉네임 중복 확인 결과 getter
  bool? get available => _available;
  String get lastCheckedNickname => _lastChecked;
  String get currentNickname => controller.text.trim();

  Future<void> checkNickname() async {
    final nickname = controller.text.trim();
    if (nickname.isEmpty) {
      _setResult(false, '닉네임을 입력해주세요.');
      return;
    }
    if (nickname.length < 2 || nickname.length > 8) {
      _setResult(false, '닉네임은 2자 이상 8자 이하로 입력해주세요.');
      return;
    }

    setState(() => _isChecking = true);
    try {
      final resp = await DioClient.dio.get(
        '/users/check-nickname',
        queryParameters: {
          'nickname': nickname,
          if (widget.excludeUserId != null)
            'excludeUserId': widget.excludeUserId,
        },
      );
      final body = resp.data as Map<String, dynamic>;
      _setResult(body['available'] as bool, body['message'] as String);
      _lastChecked = nickname;
    } catch (e) {
      _setResult(false, '확인 중 오류가 발생했습니다.');
    } finally {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  void _setResult(bool? avail, String msg) {
    setState(() {
      _available = avail;
      _message = msg;
    });
    widget.onResult(avail, controller.text.trim());
  }

  void _onTextChanged(String _) {
    if (_available != null) {
      setState(() {
        _available = null;
        _message = '';
      });
      widget.onResult(null, controller.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                maxLength: 8,
                onChanged: _onTextChanged,
                style: const TextStyle(
                    fontSize: 15, color: AppColors.textMain),
                decoration: InputDecoration(
                  counterText: '',
                  prefixIcon: const Icon(Icons.badge_outlined,
                      color: AppColors.skyBlue, size: 22),
                  hintText: '닉네임 (2~8자)',
                  hintStyle: const TextStyle(
                      color: AppColors.textMuted, fontSize: 15),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                        color:
                            AppColors.skyBlueLight.withValues(alpha: 0.5)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                        color: _available == false
                            ? Colors.red
                            : _available == true
                                ? Colors.green
                                : AppColors.skyBlueLight
                                    .withValues(alpha: 0.4)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(
                        color: AppColors.skyBlue, width: 2),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isChecking ? null : checkNickname,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.skyBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: _isChecking
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
        if (_message.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 6, left: 4),
            child: Text(
              _message,
              style: TextStyle(
                fontSize: 12,
                color: _available == true ? Colors.green : Colors.red,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
      ],
    );
  }
}

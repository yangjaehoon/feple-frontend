import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/widget/w_app_text_field.dart';
import 'package:feple/common/widget/w_loading_button.dart';
import 'package:feple/service/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ForgotPasswordDialog extends StatefulWidget {
  final String initialEmail;

  const ForgotPasswordDialog({super.key, required this.initialEmail});

  @override
  State<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends State<ForgotPasswordDialog> {
  static final _emailRegex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  late final TextEditingController _emailCtrl;
  bool _isSending = false;
  String? _emailError;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(text: widget.initialEmail);
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _onSend() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      setState(() => _emailError = 'enter_email'.tr());
      return;
    }
    if (!_emailRegex.hasMatch(email)) {
      setState(() => _emailError = 'enter_valid_email'.tr());
      return;
    }
    setState(() { _emailError = null; _isSending = true; });
    try {
      await AuthService.instance.sendPasswordReset(email);
      if (!mounted) return;
      context.showSuccessSnackbar('password_reset_sent'.tr());
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      context.showErrorSnackbar(AuthService.instance.firebaseErrorMessage(e.code));
    } catch (e) {
      debugPrint('[ForgotPw] 예외: $e');
      if (mounted) context.showErrorSnackbar('unknown_error'.tr());
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return AlertDialog(
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      title: Text(
        'reset_password'.tr(),
        style: TextStyle(fontWeight: FontWeight.w700, color: colors.textTitle),
      ),
      content: AutofillGroup(
        child: AppTextField(
          controller: _emailCtrl,
          hintText: 'registered_email'.tr(),
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          autofillHints: const [AutofillHints.email],
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => _onSend(),
          errorText: _emailError,
          onChanged: (_) {
            if (_emailError != null) setState(() => _emailError = null);
          },
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('cancel'.tr()),
        ),
        SizedBox(
          width: 80,
          child: LoadingButton(
            label: 'send'.tr(),
            isLoading: _isSending,
            backgroundColor: colors.activate,
            height: 40,
            borderRadius: AppDimens.radiusSmall,
            onPressed: _onSend,
          ),
        ),
      ],
    );
  }
}

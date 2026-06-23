import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
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
  late final TextEditingController _emailCtrl;
  bool _isSending = false;

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
    if (email.isEmpty) return;
    setState(() => _isSending = true);
    try {
      await AuthService.instance.sendPasswordReset(email);
      if (!mounted) return;
      // ScaffoldMessenger는 MaterialApp 레벨이라 팝 전 호출 가능
      context.showSuccessSnackbar('password_reset_sent'.tr());
      Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      setState(() => _isSending = false);
      context.showErrorSnackbar(AuthService.instance.firebaseErrorMessage(e.code));
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
      content: TextField(
        controller: _emailCtrl,
        keyboardType: TextInputType.emailAddress,
        decoration: InputDecoration(
          hintText: 'registered_email'.tr(),
          border: const OutlineInputBorder(),
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

import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:fast_app_base/login/login.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:fast_app_base/controller/auth_controller.dart';
import 'common/data/preference/app_preferences.dart';
import 'package:get/get.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp().then((value) => Get.put(AuthController()));

  await EasyLocalization.ensureInitialized();
  await AppPreferences.init();

  runApp(EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('ko')],
      fallbackLocale: const Locale('en'),
      path: 'assets/translations',
      useOnlyLangCode: true,
      child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      theme: ThemeData(primaryColor: Colors.blue),
      home: const LoginPage(),
    );
  }
}

import 'dart:convert';

import 'package:flutter/services.dart';

import '../../model/open_source_package.dart';

class LocalJson {
  static Future<List<Package>> getPackages(String filePath) async {
    final string = await getJsonString(filePath);
    final json = jsonDecode(string);
    if (json is! List) return [];
    return json.map((e) => Package.fromJson(e as Map<String, dynamic>)).toList();
  }

  static Future<String> getJsonString(String filePath) async {
    return await rootBundle.loadString('assets/$filePath');
  }
}

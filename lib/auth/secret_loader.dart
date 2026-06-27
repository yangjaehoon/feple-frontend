import 'dart:async' show Future;
import 'dart:convert' show json;
import 'package:flutter/services.dart' show rootBundle;

class Secret {
  final Map<String, String> apiKeys;

  Secret({required this.apiKeys});

  factory Secret.fromJson(Map<String, dynamic> jsonMap) {
    final apiKeysJson = jsonMap["api_keys"] as Map<String, dynamic>;
    final Map<String, String> apiKeys = Map<String, String>.from(apiKeysJson);
    return Secret(apiKeys: apiKeys);
  }
}

class SecretLoader {
  final String secretPath;

  SecretLoader({required this.secretPath});
  Future<Secret> load() {
    return rootBundle.loadStructuredData<Secret>(secretPath, (jsonStr) async {
      final secret = Secret.fromJson(json.decode(jsonStr));
      return secret;
    });
  }
}

import 'secret_loader.dart';

Future<String> getApiKey(apiName) async {
  try {
    final secret =
    await SecretLoader(secretPath: 'assets/secrets.json').load();
    final key = secret.apiKeys[apiName];
    if (key == null) throw Exception('API key not found: $apiName');
    return key;
  } catch (e) {
    throw Exception('Error getting API key: $e');
  }
}
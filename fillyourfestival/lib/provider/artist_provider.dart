import 'dart:convert';
import 'package:http/http.dart' as http;
import '../model/artist_model.dart';

const String baseUrl = 'http://<서버주소>:<포트>'; // 너 백엔드 주소로 변경

Future<List<Artist>> fetchArtists() async {
  final res = await http.get(Uri.parse('$baseUrl/artists'));

  if (res.statusCode != 200) {
    throw Exception('Failed to load artists: ${res.statusCode}');
  }

  final decoded = jsonDecode(res.body);

  final list = decoded as List;
  return list.map((e) => Artist.fromJson(e as Map<String, dynamic>)).toList();
}
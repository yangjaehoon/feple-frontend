import 'package:feple/network/dio_client.dart';

class UserActivityService {
  Future<List<dynamic>> fetchPosts(int userId) async {
    final response = await DioClient.dio.get('/users/$userId/posts');
    return response.data as List;
  }

  Future<List<dynamic>> fetchComments(int userId) async {
    final response = await DioClient.dio.get('/users/$userId/comments');
    return response.data as List;
  }

  Future<List<dynamic>> fetchLikedPosts(int userId) async {
    final response = await DioClient.dio.get('/users/$userId/liked-posts');
    return response.data as List;
  }

  Future<Map<String, dynamic>> fetchStats(int userId) async {
    final response = await DioClient.dio.get('/users/$userId/stats');
    return response.data as Map<String, dynamic>;
  }
}

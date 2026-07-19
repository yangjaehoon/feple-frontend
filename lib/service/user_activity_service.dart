import 'package:feple/model/my_comment_model.dart';
import 'package:feple/model/post_model.dart';
import 'package:feple/model/user_stats_model.dart';
import 'package:feple/network/dio_client.dart';

class UserActivityService {
  Future<PostCursorPage> fetchPostsPage(int userId, {int? cursor, int size = 20}) async {
    final response = await DioClient.dio.get('/users/$userId/posts', queryParameters: {
      'cursor': ?cursor,
      'size': size,
    });
    return PostCursorPage.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<MyComment>> fetchComments(int userId) async {
    final response = await DioClient.dio.get('/users/$userId/comments');
    return response.toModelList(MyComment.fromJson);
  }

  Future<List<Post>> fetchLikedPosts(int userId) async {
    final response = await DioClient.dio.get('/users/$userId/liked-posts');
    return response.toModelList(Post.fromJson);
  }

  Future<UserStats> fetchStats(int userId) async {
    final response = await DioClient.dio.get('/users/$userId/stats');
    return UserStats.fromJson(response.data as Map<String, dynamic>);
  }
}

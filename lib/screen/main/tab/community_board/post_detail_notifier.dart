import 'package:feple/injection.dart';
import 'package:feple/network/dio_client.dart';
import 'package:feple/service/scrap_service.dart';
import 'package:flutter/foundation.dart';

class PostDetailNotifier extends ChangeNotifier {
  final int postId;
  final _scrapService = sl<ScrapService>();

  List<Map<String, dynamic>> comments = [];
  bool liked = false;
  bool scraped = false;
  late int heartCount;
  int scrapCount = 0;
  bool isSubmitting = false;
  String? commentError;
  bool isToggling = false;
  bool isScrapping = false;

  void Function(String)? onCommentPosted;
  void Function(String)? onError;

  PostDetailNotifier({required this.postId, required int initialHeartCount}) {
    heartCount = initialHeartCount;
  }

  Future<void> init() async {
    await Future.wait([loadPostState(), fetchComments()]);
  }

  Future<void> loadPostState() async {
    try {
      final results = await Future.wait([
        DioClient.dio.get('/posts/$postId'),
        DioClient.dio.get('/posts/$postId/liked'),
        DioClient.dio.get('/posts/$postId/scraped'),
      ]);
      heartCount = (results[0].data['likeCount'] as num?)?.toInt() ?? heartCount;
      scrapCount = (results[0].data['scrapCount'] as num?)?.toInt() ?? scrapCount;
      liked = results[1].data as bool? ?? liked;
      scraped = results[2].data as bool? ?? scraped;
      notifyListeners();
    } catch (e) {
      debugPrint('loadPostState error: $e');
    }
  }

  Future<void> fetchComments() async {
    try {
      final resp = await DioClient.dio.get('/comments/post/$postId');
      comments = (resp.data as List).map((e) => e as Map<String, dynamic>).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('fetchComments error: $e');
    }
  }

  Future<void> submitComment(String comment, int? userId) async {
    if (comment.isEmpty) {
      commentError = 'enter_comment_please';
      notifyListeners();
      return;
    }
    commentError = null;

    if (userId == null) {
      commentError = 'no_login_info';
      notifyListeners();
      return;
    }

    isSubmitting = true;
    notifyListeners();

    try {
      await DioClient.dio.post('/comments', data: {
        'content': comment,
        'postId': postId,
      });
      await fetchComments();
      onCommentPosted?.call('comment_posted');
    } catch (e) {
      onError?.call('comment_failed:${e.toString()}');
    } finally {
      isSubmitting = false;
      notifyListeners();
    }
  }

  Future<void> toggleLike(int? userId) async {
    if (isToggling || userId == null) return;
    isToggling = true;
    notifyListeners();
    try {
      final resp = await DioClient.dio.post('/posts/$postId/like');
      final bool nowLiked = resp.data as bool;
      liked = nowLiked;
      heartCount = nowLiked ? heartCount + 1 : heartCount - 1;
    } catch (e) {
      onError?.call('like_failed:${e.toString()}');
    } finally {
      isToggling = false;
      notifyListeners();
    }
  }

  Future<void> toggleScrap(int? userId) async {
    if (isScrapping || userId == null) return;
    isScrapping = true;
    notifyListeners();
    try {
      scraped = await _scrapService.toggleScrap(postId);
      scrapCount = scraped ? scrapCount + 1 : scrapCount - 1;
      onCommentPosted?.call(scraped ? 'scrap_done' : 'scrap_cancel');
    } catch (e) {
      onError?.call('scrap_failed:${e.toString()}');
    } finally {
      isScrapping = false;
      notifyListeners();
    }
  }
}

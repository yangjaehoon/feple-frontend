import 'package:feple/common/util/app_route.dart';
import 'package:feple/common/util/login_gate.dart';
import 'package:feple/provider/user_provider.dart';
import 'package:feple/screen/main/tab/my_page/s_other_user_profile.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// 커뮤니티 어디서든 프로필 이미지 탭 시 호출.
/// 본인이면 이동 없음, 타인이면 [OtherUserProfileScreen]으로 이동.
/// 타인 프로필 화면은 계정 전용 정보(인증·차단·신고)를 다루므로 비로그인
/// 게스트에게는 이동 대신 로그인 안내를 띄운다 — 페스티벌 게시판 등 게스트가
/// 볼 수 있는 글에서 작성자를 탭했을 때 401 에러 화면으로 빠지지 않도록.
void navigateToUserProfile(
  BuildContext context, {
  required int? userId,
  required String nickname,
  String? profileImageUrl,
  required int? currentUserId,
}) {
  if (userId == null) return;
  if (userId == currentUserId) return;
  if (!ensureLoggedIn(context)) return;
  Navigator.push(
    context,
    SlideRoute(
      builder: (_) => OtherUserProfileScreen(
        userId: userId,
        nickname: nickname,
        profileImageUrl: profileImageUrl,
      ),
    ),
  );
}

/// 게시글 작성자 프로필로 이동 — [Post]의 userId/nickname/profileImageUrl은
/// 항상 함께 다니는 값이라 호출부마다 currentUserId만 따로 읽지 않도록
/// [navigateToUserProfile]을 감싼 진입점.
void navigateToPostAuthor(
  BuildContext context, {
  required int? userId,
  required String nickname,
  String? profileImageUrl,
}) {
  navigateToUserProfile(
    context,
    userId: userId,
    nickname: nickname,
    profileImageUrl: profileImageUrl,
    currentUserId: context.read<UserProvider>().currentUserId,
  );
}

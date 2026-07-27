import 'dart:async';

import 'package:easy_localization/easy_localization.dart';
import 'package:feple/common/theme/custom_theme.dart';
import 'package:feple/common/theme/custom_theme_holder.dart';
import 'package:feple/common/widget/w_inline_badge.dart';
import 'package:feple/common/widget/w_profile_avatar.dart';
import 'package:feple/model/comment_detail.dart';
import 'package:feple/screen/main/tab/community_board/w_comment_section.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

CommentDetail _comment({
  int id = 1,
  int userId = 10,
  String nickname = '작성자',
  String content = '댓글 내용',
  int likeCount = 0,
  bool liked = false,
  bool anonymous = false,
  bool edited = false,
  int? parentId,
}) {
  final now = DateTime.now();
  return CommentDetail(
    id: id,
    postId: 1,
    userId: userId,
    nickname: nickname,
    content: content,
    createdAt: now.subtract(const Duration(minutes: 5)),
    updatedAt: edited ? now : null,
    certified: false,
    parentId: parentId,
    likeCount: likeCount,
    liked: liked,
    anonymous: anonymous,
  );
}

Future<void> _pump(WidgetTester tester, Widget child) async {
  SharedPreferences.setMockInitialValues({});
  await EasyLocalization.ensureInitialized();
  tester.view.physicalSize = const Size(1080, 2400);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    EasyLocalization(
      supportedLocales: const [Locale('ko'), Locale('en')],
      startLocale: const Locale('ko'),
      fallbackLocale: const Locale('ko'),
      path: 'assets/translations',
      useOnlyLangCode: true,
      child: CustomThemeHolder(
        theme: CustomTheme.light,
        changeTheme: (_) {},
        child: MaterialApp(home: Scaffold(body: SingleChildScrollView(child: child))),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  group('CommentSection 렌더링', () {
    testWidgets('댓글이 없으면 안내 문구를 보여준다', (tester) async {
      await _pump(tester, const CommentSection(rootComments: [], repliesMap: {}));

      expect(find.text('be_first_to_comment'.tr()), findsOneWidget);
    });

    testWidgets('루트 댓글과 대댓글을 함께 보여준다', (tester) async {
      await _pump(
        tester,
        CommentSection(
          rootComments: [_comment(id: 1, nickname: '철수', content: '루트 댓글')],
          repliesMap: {
            1: [_comment(id: 2, nickname: '영희', content: '대댓글', parentId: 1)],
          },
        ),
      );

      expect(find.text('철수'), findsOneWidget);
      expect(find.text('루트 댓글'), findsOneWidget);
      expect(find.text('영희'), findsOneWidget);
      expect(find.text('대댓글'), findsOneWidget);
    });

    testWidgets('수정된 댓글이면 edited 표시를 보여준다', (tester) async {
      await _pump(
        tester,
        CommentSection(
          rootComments: [_comment(edited: true)],
          repliesMap: const {},
        ),
      );

      expect(find.text('edited'.tr()), findsOneWidget);
    });

    testWidgets('익명 댓글이면 역할/인증 뱃지를 보여주지 않는다', (tester) async {
      await _pump(
        tester,
        CommentSection(
          rootComments: [_comment(anonymous: true, nickname: '익명23')],
          repliesMap: const {},
        ),
      );

      expect(find.text('익명23'), findsOneWidget);
      expect(find.byType(InlineBadge), findsNothing);
    });
  });

  group('CommentSection 좋아요', () {
    testWidgets('좋아요를 탭하면 즉시 낙관적으로 반영된다', (tester) async {
      await _pump(
        tester,
        CommentSection(
          rootComments: [_comment(liked: false, likeCount: 3)],
          repliesMap: const {},
          onToggleLike: (_) async => true,
        ),
      );

      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget);
      expect(find.text('3'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.favorite_border_rounded));
      await tester.pump();

      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget);
      expect(find.text('4'), findsOneWidget);
    });

    testWidgets('좋아요 토글이 실패하면 원래 상태로 되돌아간다', (tester) async {
      final completer = Completer<bool>();
      await _pump(
        tester,
        CommentSection(
          rootComments: [_comment(liked: false, likeCount: 3)],
          repliesMap: const {},
          onToggleLike: (_) => completer.future,
        ),
      );

      await tester.tap(find.byIcon(Icons.favorite_border_rounded));
      await tester.pump();
      expect(find.byIcon(Icons.favorite_rounded), findsOneWidget); // 낙관적 반영
      expect(find.text('4'), findsOneWidget);

      completer.complete(false);
      await tester.pump();
      await tester.pump(); // onToggle 완료 대기 (Future 완료 마이크로태스크 + setState 반영 프레임)
      expect(find.byIcon(Icons.favorite_border_rounded), findsOneWidget); // 롤백됨
      expect(find.text('3'), findsOneWidget);
    });

    testWidgets('좋아요 수가 0이면 숫자를 표시하지 않는다', (tester) async {
      await _pump(
        tester,
        CommentSection(rootComments: [_comment(likeCount: 0)], repliesMap: const {}),
      );

      expect(find.text('0'), findsNothing);
    });
  });

  group('CommentSection 답글', () {
    testWidgets('루트 댓글에만 답글 버튼이 보이고 탭하면 콜백이 호출된다', (tester) async {
      int? repliedCommentId;
      String? repliedNickname;
      await _pump(
        tester,
        CommentSection(
          rootComments: [_comment(id: 1, nickname: '철수')],
          repliesMap: {
            1: [_comment(id: 2, nickname: '영희', parentId: 1)],
          },
          onReply: (id, nickname) {
            repliedCommentId = id;
            repliedNickname = nickname;
          },
        ),
      );

      expect(find.text('reply_comment'.tr()), findsOneWidget); // 루트에만 1개

      await tester.tap(find.text('reply_comment'.tr()));
      await tester.pump();

      expect(repliedCommentId, 1);
      expect(repliedNickname, '철수');
    });
  });

  group('CommentSection 작성자 탭', () {
    testWidgets('실명 댓글의 아바타를 탭하면 onAuthorTap이 호출된다', (tester) async {
      int? tappedUserId;
      await _pump(
        tester,
        CommentSection(
          rootComments: [_comment(id: 1, userId: 42, nickname: '철수')],
          repliesMap: const {},
          onAuthorTap: (userId, nickname, imageUrl) => tappedUserId = userId,
        ),
      );

      await tester.tap(find.byType(ProfileAvatar));
      await tester.pump();

      expect(tappedUserId, 42);
    });

    testWidgets('익명 댓글은 onAuthorTap이 있어도 탭해도 호출되지 않는다', (tester) async {
      var tapped = false;
      await _pump(
        tester,
        CommentSection(
          rootComments: [_comment(anonymous: true)],
          repliesMap: const {},
          onAuthorTap: (_, _, _) => tapped = true,
        ),
      );

      await tester.tap(find.byType(ProfileAvatar));
      await tester.pump();

      expect(tapped, false);
    });
  });

  group('CommentSection 본인 댓글 메뉴', () {
    testWidgets('본인 댓글이면 수정/삭제 메뉴가 보인다', (tester) async {
      await _pump(
        tester,
        CommentSection(
          rootComments: [_comment(id: 1, userId: 99)],
          repliesMap: const {},
          currentUserId: 99,
        ),
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('edit_comment'.tr()), findsOneWidget);
      expect(find.text('delete_comment'.tr()), findsOneWidget);
    });

    testWidgets('수정을 탭하면 onEditComment가 댓글 내용과 함께 호출된다', (tester) async {
      int? editedId;
      String? editedContent;
      await _pump(
        tester,
        CommentSection(
          rootComments: [_comment(id: 1, userId: 99, content: '원본 내용')],
          repliesMap: const {},
          currentUserId: 99,
          onEditComment: (id, content) {
            editedId = id;
            editedContent = content;
          },
        ),
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('edit_comment'.tr()));
      await tester.pumpAndSettle();

      expect(editedId, 1);
      expect(editedContent, '원본 내용');
    });

    testWidgets('삭제 확인 다이얼로그에서 확인하면 onDeleteComment가 호출된다', (tester) async {
      var deletedId = -1;
      await _pump(
        tester,
        CommentSection(
          rootComments: [_comment(id: 1, userId: 99)],
          repliesMap: const {},
          currentUserId: 99,
          onDeleteComment: (id) => deletedId = id,
        ),
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('delete_comment'.tr()).last);
      await tester.pumpAndSettle();

      expect(find.text('delete_comment_confirm'.tr()), findsOneWidget);
      await tester.tap(find.text('delete_comment'.tr()).last);
      await tester.pumpAndSettle();

      expect(deletedId, 1);
    });

    testWidgets('삭제 확인 다이얼로그에서 취소하면 onDeleteComment가 호출되지 않는다', (tester) async {
      var deleteCalled = false;
      await _pump(
        tester,
        CommentSection(
          rootComments: [_comment(id: 1, userId: 99)],
          repliesMap: const {},
          currentUserId: 99,
          onDeleteComment: (_) => deleteCalled = true,
        ),
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('delete_comment'.tr()).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('cancel'.tr()));
      await tester.pumpAndSettle();

      expect(deleteCalled, false);
    });
  });

  group('CommentSection 신고 메뉴', () {
    testWidgets('타인 댓글이면 신고 메뉴만 보인다', (tester) async {
      await _pump(
        tester,
        CommentSection(
          rootComments: [_comment(id: 1, userId: 99)],
          repliesMap: const {},
          currentUserId: 1, // 본인이 아님
          onReport: (_) {},
        ),
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();

      expect(find.text('report_comment'.tr()), findsOneWidget);
      expect(find.text('edit_comment'.tr()), findsNothing);
    });

    testWidgets('신고를 탭하면 onReport가 호출된다', (tester) async {
      int? reportedId;
      await _pump(
        tester,
        CommentSection(
          rootComments: [_comment(id: 1, userId: 99)],
          repliesMap: const {},
          currentUserId: 1,
          onReport: (id) => reportedId = id,
        ),
      );

      await tester.tap(find.byIcon(Icons.more_vert));
      await tester.pumpAndSettle();
      await tester.tap(find.text('report_comment'.tr()));
      await tester.pumpAndSettle();

      expect(reportedId, 1);
    });

    testWidgets('onReport도 currentUserId도 없으면 더보기 메뉴가 없다', (tester) async {
      await _pump(
        tester,
        CommentSection(rootComments: [_comment(id: 1, userId: 99)], repliesMap: const {}),
      );

      expect(find.byIcon(Icons.more_vert), findsNothing);
    });
  });
}

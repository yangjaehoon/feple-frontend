import 'package:feple/common/app_events.dart';
import 'package:feple/model/post_changed_event.dart';
import 'package:feple/service/post_service.dart';

/// [WritePost.onSubmit]에 바로 연결하는 "게시글 생성 후 목록 새로고침 브로드캐스트"
/// 콜백. 여러 게시판 진입점(미리보기 카드, 커뮤니티 게시판 탭)에서 반복되던
/// createPost + AppEvents.postChanged 브로드캐스트 패턴을 하나로 묶는다.
Future<void> Function(String, String, bool, List<String>)
createPostSubmitHandler(PostService postService, String boardType) {
  return (title, content, anonymous, imageObjectKeys) async {
    await postService.createPost(
      boardType: boardType,
      draft: PostDraft(
        title: title,
        content: content,
        anonymous: anonymous,
        imageObjectKeys: imageObjectKeys,
      ),
    );
    AppEvents.postChanged.value = PostChangedEvent.refreshAll();
  };
}

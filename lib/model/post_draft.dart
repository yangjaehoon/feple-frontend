/// 게시글 작성 시 함께 다니는 입력값 묶음 (title/content/anonymous/imageObjectKey).
/// [PostService]의 `create*Post` 메서드들이 게시판 종류별로 반복하던
/// 동일 파라미터 그룹을 하나로 묶는다.
class PostDraft {
  final String title;
  final String content;
  final bool anonymous;
  final String? imageObjectKey;

  const PostDraft({
    required this.title,
    required this.content,
    this.anonymous = false,
    this.imageObjectKey,
  });
}

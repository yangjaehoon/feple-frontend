/// 게시판 타입 식별자 상수.
/// 백엔드 API 및 라우팅에서 사용하는 문자열 키.
abstract final class BoardTypes {
  static const String hot = 'HotBoard';
  static const String free = 'FreeBoard';
  static const String mate = 'MateBoard';

  static bool isPaginated(String type) => type == free || type == mate;
  static bool showWriteButton(String type) => type != hot;
}

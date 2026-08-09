import 'package:feple/common/common.dart';
import 'package:feple/common/post_cursor_controller.dart';
import 'package:flutter/widgets.dart';

/// [PostCursorController]를 쓰는 화면마다 반복되던 리스너 콜백
/// (setState + refreshError 1회성 스낵바 표시)을 공통화.
mixin PostCursorControllerListener<T extends StatefulWidget> on State<T> {
  PostCursorController get postCursorController;

  void onPostCursorControllerChanged() {
    setState(() {});
    final refreshError = postCursorController.refreshError;
    if (refreshError != null) {
      postCursorController.clearRefreshError();
      context.showErrorSnackbar(refreshError);
    }
  }
}

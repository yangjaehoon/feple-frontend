import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_empty_state.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:flutter/material.dart';

/// 퓨처 빌더의 보일러플레이트 코드를 줄여주는 공통 위젯
/// 로딩, 에러, 데이터 없음 상태를 통일성 있게 관리합니다.
class AsyncContentBuilder<T> extends StatelessWidget {
  final Future<T>? future;
  
  /// 데이터를 로드했을 때 보여줄 위젯 (필수)
  final Widget Function(BuildContext context, T data) builder;
  
  /// 에러 발생 시 보여줄 커스텀 위젯 (선택)
  final Widget Function(Object? error)? errorBuilder;
  
  /// 데이터가 없을 때 보여줄 커스텀 위젯 (선택)
  final WidgetBuilder? emptyBuilder;
  
  /// 로딩 중일 때 보여줄 커스텀 위젯 (선택)
  final WidgetBuilder? loadingBuilder;

  /// 에러 시 재시도 콜백 (선택) — 넘기면 재시도 버튼이 표시됨
  final VoidCallback? onRetry;
  
  /// 데이터가 비어있는지 판단하는 커스텀 로직 (리스트나 맵 이외의 타입일 경우 주로 사용)
  final bool Function(T data)? isEmpty;
  
  /// ListView.builder 등과 함께 RefreshIndicator를 사용할 때,
  /// 에러/empty 상태에서도 스크롤하여 새로고침이 가능하도록 
  /// ListView로 감쌀지 여부를 결정합니다. 기본값 true.
  final bool useListViewForEmptyState;

  const AsyncContentBuilder({
    super.key,
    required this.future,
    required this.builder,
    this.errorBuilder,
    this.emptyBuilder,
    this.loadingBuilder,
    this.onRetry,
    this.isEmpty,
    this.useListViewForEmptyState = true,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          if (loadingBuilder != null) return loadingBuilder!(context);
          return Center(
            child: CircularProgressIndicator(
              color: context.appColors.activate,
            ),
          );
        }

        if (snapshot.hasError) {
          if (errorBuilder != null) return errorBuilder!(snapshot.error);
          final errorWidget = ErrorState(
            message: 'err_fetch_data'.tr(args: [snapshot.error.toString()]),
            onRetry: onRetry,
          );
          if (useListViewForEmptyState) {
            return ListView(children: [const SizedBox(height: 60), errorWidget]);
          }
          return errorWidget;
        }

        if (!snapshot.hasData) {
          if (emptyBuilder != null) return emptyBuilder!(context);
          return _buildStateWidget(context, 'no_posts_yet'.tr());
        }

        final data = snapshot.data as T;
        
        bool empty = false;
        if (isEmpty != null) {
          empty = isEmpty!(data);
        } else if (data is List) {
          empty = data.isEmpty;
        } else if (data is Map) {
          empty = data.isEmpty;
        } else if (data is String) {
          empty = data.isEmpty;
        }

        if (empty) {
          if (emptyBuilder != null) return emptyBuilder!(context);
          return _buildStateWidget(context, 'no_posts_yet'.tr());
        }

        return builder(context, data);
      },
    );
  }

  Widget _buildStateWidget(BuildContext context, String message) {
    final content = EmptyState(
      icon: Icons.article_outlined,
      title: message,
    );

    if (useListViewForEmptyState) {
      return ListView(
        children: [
          const SizedBox(height: 120),
          content,
        ],
      );
    }

    return content;
  }
}

import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
import 'package:feple/common/util/dio_error_helper.dart';
import 'package:flutter/material.dart';

/// 에러 발생 시 아이콘 + 메시지 + 재시도 버튼을 보여주는 공용 위젯.
/// [onRetry]를 넘기지 않으면 재시도 버튼이 표시되지 않습니다.
/// [icon]을 넘기지 않으면 원인을 특정하지 않는 중립 아이콘을 사용합니다.
/// 네트워크 오프라인이 원인임을 알 때는 `dio_error_helper.dart`의 `isOffline(e)`로
/// 판별해 `Icons.wifi_off_rounded`를 넘겨주세요.
class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline_rounded,
  });

  /// 조회(읽기) 실패 시 원인을 구분해 보여주는 팩토리.
  /// 오프라인/타임아웃이면 와이파이 꺼짐 아이콘 + '연결 오류' 메시지,
  /// 그 외(서버 오류 등)는 기본 아이콘 + [operationErrorKey] 메시지.
  factory ErrorState.network(
    Object error, {
    VoidCallback? onRetry,
    String operationErrorKey = 'err_fetch_data',
  }) {
    return ErrorState(
      message: networkAwareErrorKey(error, operationErrorKey).tr(),
      icon: isOffline(error)
          ? Icons.wifi_off_rounded
          : Icons.error_outline_rounded,
      onRetry: onRetry,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return LayoutBuilder(
      builder: (_, constraints) {
        // constraints.maxHeight가 infinity이면(Column 등 무한 높이 컨텍스트)
        // minHeight: 0으로 설정해 콘텐츠 크기만큼만 차지하게 한다.
        final minH = constraints.hasBoundedHeight ? constraints.maxHeight : 0.0;
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: minH),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 52,
                      color: colors.textSecondary.withValues(alpha: 0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: AppDimens.fontSizeMd,
                        color: colors.textSecondary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    if (onRetry != null) ...[
                      const SizedBox(height: 20),
                      FilledButton.icon(
                        onPressed: onRetry,
                        icon: const Icon(Icons.refresh_rounded, size: 18),
                        label: Text('retry'.tr()),
                        style: FilledButton.styleFrom(
                          backgroundColor: colors.activate,
                          foregroundColor: Theme.of(
                            context,
                          ).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 10,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppDimens.shapeButton,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

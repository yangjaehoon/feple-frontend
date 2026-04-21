import 'package:feple/common/common.dart';
import 'package:feple/model/festival_model.dart';
import 'package:feple/network/dio_client.dart';
import 'package:feple/screen/main/tab/search/festival_information/f_festival_information.dart';
import 'package:feple/service/notification_service.dart';
import 'package:flutter/material.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _service = NotificationService();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  static const _festivalTypes = {'NEW_FESTIVAL', 'FESTIVAL_REMINDER'};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final list = await _service.getMyNotifications();
      if (mounted) setState(() { _items = list; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _loading = false; });
    }
  }

  Future<void> _onTap(int index) async {
    final item = _items[index];
    final id = item['id'];
    final type = item['type'] as String?;
    final referenceId = item['referenceId'];

    // 읽지 않은 경우 로컬 상태 즉시 업데이트 후 서버에 저장
    final isRead = (item['read'] as bool?) ?? (item['isRead'] as bool?) ?? false;
    if (!isRead) {
      setState(() => _items[index] = {...item, 'read': true, 'isRead': true});
      if (id != null) {
        try {
          await _service.markRead(id as int);
        } catch (e) {
          debugPrint('markRead error: $e');
        }
      }
    }

    // 페스티벌 타입이면 상세 페이지로 이동
    if (_festivalTypes.contains(type) && referenceId != null) {
      await _navigateToFestival(referenceId);
    }
  }

  Future<void> _navigateToFestival(dynamic festivalId) async {
    try {
      final res = await DioClient.dio.get('/festivals/$festivalId');
      final d = res.data as Map<String, dynamic>;
      if (!mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FestivalInformationFragment(
            poster: FestivalModel(
              id: d['id'] as int,
              title: d['title'] as String? ?? '',
              description: d['description'] as String? ?? '',
              location: d['location'] as String? ?? '',
              startDate: d['startDate'] as String? ?? '',
              endDate: d['endDate'] as String? ?? '',
              posterUrl: d['posterUrl'] as String? ?? '',
              latitude: (d['latitude'] as num?)?.toDouble(),
              longitude: (d['longitude'] as num?)?.toDouble(),
            ),
          ),
        ),
      );
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.backgroundMain,
      appBar: AppBar(
        backgroundColor: colors.backgroundMain,
        elevation: 0,
        title: Text(
          'notifications'.tr(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: colors.textTitle,
          ),
        ),
        iconTheme: IconThemeData(color: colors.textTitle),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.notifications_none_rounded,
                          size: 56,
                          color: colors.textSecondary.withValues(alpha: 0.4)),
                      const SizedBox(height: 12),
                      Text(
                        'no_notifications'.tr(),
                        style: TextStyle(
                          color: colors.textSecondary,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _NotificationCard(
                    item: _items[i],
                    colors: colors,
                    onTap: () => _onTap(i),
                  ),
                ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final Map<String, dynamic> item;
  final AbstractThemeColors colors;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.item,
    required this.colors,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isRead = item['read'] as bool? ?? false;
    final title = item['title'] as String? ?? '';
    final body = item['body'] as String? ?? '';
    final createdAt = item['createdAt'] as String?;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isRead
              ? Colors.white
              : colors.certRingColor.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isRead
                ? Colors.grey.withValues(alpha: 0.15)
                : colors.certRingColor.withValues(alpha: 0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.cardShadow.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _iconColor(item['type'], colors).withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(_iconData(item['type']),
                  color: _iconColor(item['type'], colors), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
                      color: colors.textTitle,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 13,
                      color: colors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (createdAt != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      createdAt.length >= 10
                          ? createdAt.substring(0, 10)
                          : createdAt,
                      style: TextStyle(
                        fontSize: 11,
                        color: colors.textSecondary.withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!isRead)
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(top: 4, left: 8),
                decoration: BoxDecoration(
                  color: colors.certRingColor,
                  shape: BoxShape.circle,
                ),
              ),
          ],
        ),
      ),
    );
  }

  IconData _iconData(dynamic type) {
    switch (type as String?) {
      case 'CERT_APPROVED':     return Icons.verified_rounded;
      case 'CERT_REJECTED':     return Icons.cancel_outlined;
      case 'NEW_COMMENT':       return Icons.chat_bubble_rounded;
      case 'FESTIVAL_REMINDER': return Icons.event_rounded;
      default:                  return Icons.festival_rounded;
    }
  }

  Color _iconColor(dynamic type, AbstractThemeColors colors) {
    switch (type as String?) {
      case 'CERT_APPROVED':     return colors.certRingColor;
      case 'CERT_REJECTED':     return Colors.grey;
      case 'NEW_COMMENT':       return Colors.blueAccent;
      case 'FESTIVAL_REMINDER': return Colors.deepOrangeAccent;
      default:                  return colors.certRingColor;
    }
  }
}

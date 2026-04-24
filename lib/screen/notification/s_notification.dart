import 'package:feple/common/common.dart';
import 'package:feple/model/festival_model.dart';
import 'package:feple/network/dio_client.dart';
import 'package:feple/screen/main/tab/search/festival_information/f_festival_information.dart';
import 'package:feple/screen/notification/w_notification_card.dart';
import 'package:feple/injection.dart';
import 'package:feple/service/notification_service.dart';
import 'package:flutter/material.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final _service = sl<NotificationService>();
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
                  itemBuilder: (_, i) => NotificationCard(
                    item: _items[i],
                    onTap: () => _onTap(i),
                  ),
                ),
    );
  }
}


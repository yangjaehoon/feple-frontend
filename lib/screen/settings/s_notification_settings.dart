import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_error_state.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
import 'package:feple/common/widget/w_settings_item.dart';
import 'package:feple/common/widget/w_skeleton_box.dart';
import 'package:feple/injection.dart';
import 'package:feple/model/notification_preference_model.dart';
import 'package:feple/service/notification_preference_service.dart';
import 'package:flutter/material.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  NotificationPreferenceModel? _prefs;
  bool _hasError = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    setState(() => _hasError = false);
    try {
      final prefs = await sl<NotificationPreferenceService>().getPreferences();
      if (mounted) setState(() => _prefs = prefs);
    } catch (e) {
      // 실제 서버 상태를 모르는 채 가짜 기본값을 채우면 이후 토글 시 전체
      // 스냅샷을 PUT하는 _togglePref가 서버의 다른 항목 값을 덮어쓸 수 있음
      // → 기본값 대체 대신 재시도를 요구
      debugPrint('[NotificationSettings] prefs load failed: $e');
      if (mounted) setState(() => _hasError = true);
    }
  }

  Future<void> _togglePref(NotificationPreferenceModel newPrefs) async {
    if (_saving) return;
    final old = _prefs;
    setState(() {
      _prefs = newPrefs;
      _saving = true;
    });
    try {
      await sl<NotificationPreferenceService>().updatePreferences(newPrefs);
    } catch (_) {
      if (mounted) {
        setState(() => _prefs = old);
        context.showErrorSnackbar('save_failed'.tr());
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: colors.backgroundMain,
      body: Column(
        children: [
          SecondaryAppBar(title: 'notif_settings'.tr()),
          Expanded(
            child: _hasError
                ? Center(child: ErrorState(message: 'load_error'.tr(), onRetry: _loadPrefs))
                : _buildList(),
          ),
        ],
      ),
    );
  }

  Widget _buildList() {
    return ListView(
      padding: const EdgeInsets.only(top: 16, bottom: 40),
      children: [
        if (_prefs == null)
          const _NotificationSettingsSkeleton()
        else ...[
          _buildToggleItem(
            icon: Icons.verified_rounded,
            label: 'notif_cert'.tr(),
            value: _prefs!.certEnabled,
            onChanged: (_) => _togglePref(_prefs!.toggleCert()),
          ),
          const SettingsItemDivider(),
          _buildToggleItem(
            icon: Icons.chat_bubble_rounded,
            label: 'notif_comment'.tr(),
            value: _prefs!.commentEnabled,
            onChanged: (_) => _togglePref(_prefs!.toggleComment()),
          ),
          const SettingsItemDivider(),
          _buildToggleItem(
            icon: Icons.festival_rounded,
            label: 'notif_festival'.tr(),
            value: _prefs!.festivalEnabled,
            onChanged: (_) => _togglePref(_prefs!.toggleFestival()),
          ),
          const SettingsItemDivider(),
          _buildToggleItem(
            icon: Icons.music_note_rounded,
            label: 'notif_song_request'.tr(),
            value: _prefs!.songRequestEnabled,
            onChanged: (_) => _togglePref(_prefs!.toggleSongRequest()),
          ),
          const SettingsItemDivider(),
          _buildToggleItem(
            icon: Icons.bedtime_rounded,
            label: 'notif_quiet_hours'.tr(),
            value: _prefs!.quietHoursEnabled,
            onChanged: (_) => _togglePref(_prefs!.toggleQuietHours()),
          ),
        ],
      ],
    );
  }

  Widget _buildToggleItem({
    required IconData icon,
    required String label,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colors = context.appColors;
    return SettingsItem(
      icon: icon,
      label: label,
      trailing: Switch(
        value: value,
        onChanged: _saving ? null : onChanged,
        activeThumbColor: colors.activate,
      ),
    );
  }
}

class _NotificationSettingsSkeleton extends StatelessWidget {
  const _NotificationSettingsSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(children: List.generate(5, (index) => _buildRow(index, colors)));
  }

  Widget _buildRow(int index, AbstractThemeColors colors) {
    return Column(
      children: [
        Container(
          color: colors.surface,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: const Row(
            children: [
              SkeletonBox(width: 20, height: 20, borderRadius: BorderRadius.all(Radius.circular(4))),
              SizedBox(width: 14),
              Expanded(child: SkeletonBox(height: 15)),
              SizedBox(width: 14),
              SkeletonBox(width: 44, height: 26, borderRadius: BorderRadius.all(Radius.circular(13))),
            ],
          ),
        ),
        if (index < 4)
          Divider(height: 1, indent: 50, color: colors.listDivider),
      ],
    );
  }
}

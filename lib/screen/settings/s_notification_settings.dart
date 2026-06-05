import 'package:feple/common/common.dart';
import 'package:feple/common/widget/w_secondary_app_bar.dart';
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

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    try {
      final prefs = await sl<NotificationPreferenceService>().getPreferences();
      if (mounted) setState(() => _prefs = prefs);
    } catch (e) {
      debugPrint('[NotifSettings] prefs load failed: $e');
      if (mounted) {
        setState(() => _prefs = const NotificationPreferenceModel(
          certEnabled: true,
          commentEnabled: true,
          festivalEnabled: true,
          songRequestEnabled: true,
        ));
      }
    }
  }

  Future<void> _togglePref(NotificationPreferenceModel newPrefs) async {
    final old = _prefs;
    setState(() => _prefs = newPrefs);
    try {
      final updated = await sl<NotificationPreferenceService>().updatePreferences(newPrefs);
      if (mounted) setState(() => _prefs = updated);
    } catch (_) {
      if (mounted) {
        setState(() => _prefs = old);
        context.showErrorSnackbar('save_failed'.tr());
      }
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
            child: ListView(
              padding: const EdgeInsets.only(top: 16, bottom: 40),
              children: [
                if (_prefs == null)
                  _NotifSkeleton(colors: colors)
                else ...[
                  _NotifItem(
                    icon: Icons.verified_rounded,
                    label: 'notif_cert'.tr(),
                    value: _prefs!.certEnabled,
                    colors: colors,
                    onChanged: (_) => _togglePref(_prefs!.copyWith(certEnabled: !_prefs!.certEnabled)),
                  ),
                  _Divider(colors: colors),
                  _NotifItem(
                    icon: Icons.chat_bubble_rounded,
                    label: 'notif_comment'.tr(),
                    value: _prefs!.commentEnabled,
                    colors: colors,
                    onChanged: (_) => _togglePref(_prefs!.copyWith(commentEnabled: !_prefs!.commentEnabled)),
                  ),
                  _Divider(colors: colors),
                  _NotifItem(
                    icon: Icons.festival_rounded,
                    label: 'notif_festival'.tr(),
                    value: _prefs!.festivalEnabled,
                    colors: colors,
                    onChanged: (_) => _togglePref(_prefs!.copyWith(festivalEnabled: !_prefs!.festivalEnabled)),
                  ),
                  _Divider(colors: colors),
                  _NotifItem(
                    icon: Icons.music_note_rounded,
                    label: 'notif_song_request'.tr(),
                    value: _prefs!.songRequestEnabled,
                    colors: colors,
                    onChanged: (_) => _togglePref(_prefs!.copyWith(songRequestEnabled: !_prefs!.songRequestEnabled)),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _NotifItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final AbstractThemeColors colors;
  final ValueChanged<bool> onChanged;

  const _NotifItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.colors,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      color: colors.surface,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: colors.activate),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: colors.textTitle,
              ),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: colors.activate,
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final AbstractThemeColors colors;

  const _Divider({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, indent: 50, color: colors.listDivider);
  }
}

class _NotifSkeleton extends StatelessWidget {
  final AbstractThemeColors colors;

  const _NotifSkeleton({required this.colors});

  @override
  Widget build(BuildContext context) {
    return Column(children: List.generate(4, _buildRow));
  }

  Widget _buildRow(int index) {
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
        if (index < 3)
          Divider(height: 1, indent: 50, color: colors.listDivider),
      ],
    );
  }
}

import 'package:feple/common/common.dart';
import 'package:feple/common/constant/app_dimensions.dart';
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
      await sl<NotificationPreferenceService>().updatePreferences(newPrefs);
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
                  const _NotifSkeleton()
                else ...[
                  _NotifItem(
                    icon: Icons.verified_rounded,
                    label: 'notif_cert'.tr(),
                    value: _prefs!.certEnabled,
                    onChanged: (_) => _togglePref(_prefs!.toggleCert()),
                  ),
                  const _Divider(),
                  _NotifItem(
                    icon: Icons.chat_bubble_rounded,
                    label: 'notif_comment'.tr(),
                    value: _prefs!.commentEnabled,
                    onChanged: (_) => _togglePref(_prefs!.toggleComment()),
                  ),
                  const _Divider(),
                  _NotifItem(
                    icon: Icons.festival_rounded,
                    label: 'notif_festival'.tr(),
                    value: _prefs!.festivalEnabled,
                    onChanged: (_) => _togglePref(_prefs!.toggleFestival()),
                  ),
                  const _Divider(),
                  _NotifItem(
                    icon: Icons.music_note_rounded,
                    label: 'notif_song_request'.tr(),
                    value: _prefs!.songRequestEnabled,
                    onChanged: (_) => _togglePref(_prefs!.toggleSongRequest()),
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
  final ValueChanged<bool> onChanged;

  const _NotifItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
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
                fontSize: AppDimens.fontSizeLg,
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
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return Divider(height: 1, indent: 50, color: context.appColors.listDivider);
  }
}

class _NotifSkeleton extends StatelessWidget {
  const _NotifSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(children: List.generate(4, (index) => _buildRow(index, colors)));
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
        if (index < 3)
          Divider(height: 1, indent: 50, color: colors.listDivider),
      ],
    );
  }
}

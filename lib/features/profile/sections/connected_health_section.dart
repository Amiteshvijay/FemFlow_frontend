import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/FemLyra_colors.dart';

class ConnectedHealthSection extends StatefulWidget {
  final Map<String, dynamic> initialData;
  final Function(Map<String, dynamic>) onChanged;

  const ConnectedHealthSection({
    super.key,
    required this.initialData,
    required this.onChanged,
  });

  @override
  State<ConnectedHealthSection> createState() => _ConnectedHealthSectionState();
}

class _ConnectedHealthSectionState extends State<ConnectedHealthSection> {
  late Map<String, dynamic> _data;

  @override
  void initState() {
    super.initState();
    _data = Map<String, dynamic>.from(widget.initialData);
  }

  void _updateField(String key, dynamic value) {
    setState(() => _data[key] = value);
    widget.onChanged(_data);
  }

  @override
  Widget build(BuildContext context) {
    final isAndroid = !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
    final isIOS = !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (isAndroid) ...[
          _buildSyncItem('Android Health Connect', 'health_connect_sync', Icons.health_and_safety_outlined),
        ],
        if (isIOS) ...[
          _buildSyncItem('Apple Health', 'apple_health_sync', Icons.favorite_outline),
        ],
        if (kIsWeb)
          const Center(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Health device syncing is available on our mobile app.',
                style: TextStyle(color: FemLyraColors.textSecondary, fontStyle: FontStyle.italic),
              ),
            ),
          ),
        const SizedBox(height: 32),
        const Center(
          child: Text(
            'Sync with your favorite devices for personalized wellness insights.\nYour data is secure and private.',
            textAlign: TextAlign.center,
            style: TextStyle(color: FemLyraColors.textMuted, fontSize: 12, height: 1.5),
          ),
        ),
      ],
    );
  }

  Widget _buildSyncItem(String label, String key, IconData icon) {
    return SwitchListTile(
      secondary: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: FemLyraColors.primary.withValues(alpha: 0.1), shape: BoxShape.circle),
        child: Icon(icon, color: FemLyraColors.primary, size: 20),
      ),
      title: Text(label, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
      value: _data[key] == true,
      onChanged: (val) => _updateField(key, val),
      activeThumbColor: FemLyraColors.primary,
      activeTrackColor: FemLyraColors.primary.withValues(alpha: 0.5),
      contentPadding: EdgeInsets.zero,
    );
  }
}

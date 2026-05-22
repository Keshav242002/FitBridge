import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/logger.dart';

// Global toggle — bypasses the 10-min window check when true (debug only)
bool allowJoiningCallsAnytime = false;

/// Wraps [child] with a floating ⋮ DevPanel button visible in kDebugMode only.
class DevPanelOverlay extends StatelessWidget {
  const DevPanelOverlay({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!kDebugMode) return child;
    return Stack(
      children: [
        child,
        Positioned(
          right: 12,
          bottom: 80,
          child: _DevFab(),
        ),
      ],
    );
  }
}

class _DevFab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton.small(
      heroTag: 'dev_panel_fab',
      backgroundColor: Colors.black87,
      foregroundColor: Colors.white,
      onPressed: () => _showPanel(context),
      child: const Icon(Icons.more_vert),
    );
  }

  void _showPanel(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1A1A1A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => const _DevSheet(),
    );
  }
}

class _DevSheet extends StatefulWidget {
  const _DevSheet();

  @override
  State<_DevSheet> createState() => _DevSheetState();
}

class _DevSheetState extends State<_DevSheet> {
  late List<String> _logs;
  bool _allowAnytime = allowJoiningCallsAnytime;

  @override
  void initState() {
    super.initState();
    _logs = List.from(Log.buffer);
  }

  void _copyLogs() {
    Clipboard.setData(ClipboardData(text: Log.copyable()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Logs copied to clipboard')),
    );
  }

  void _clearLogs() {
    Log.clear();
    setState(() => _logs = []);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      builder: (_, ctrl) => SingleChildScrollView(
        controller: ctrl,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade700,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _SectionLabel('Dev Panel'),
              const SizedBox(height: 12),
              _InfoRow('Build mode', kDebugMode ? 'DEBUG' : 'RELEASE'),
              _InfoRow('App', 'WTF Fitness v1.0.0'),
              _InfoRow(
                'API Base',
                const String.fromEnvironment('API_BASE_URL',
                    defaultValue: 'http://localhost:8787'),
              ),
              _InfoRow('HMS_APP_ID', _masked('HMS_APP_ID_SET', 'HMS_APP_ID')),
              const SizedBox(height: 16),
              _SectionLabel('Flags'),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Allow joining calls anytime',
                  style: TextStyle(color: Colors.white, fontSize: 14),
                ),
                subtitle: const Text(
                  'Bypasses 10-min window check',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                value: _allowAnytime,
                activeThumbColor: Colors.greenAccent,
                onChanged: (v) {
                  setState(() => _allowAnytime = v);
                  allowJoiningCallsAnytime = v;
                },
              ),
              const SizedBox(height: 16),
              _SectionLabel('Last ${_logs.length} log lines'),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.black,
                  borderRadius: BorderRadius.circular(8),
                ),
                constraints: const BoxConstraints(maxHeight: 220),
                child: _logs.isEmpty
                    ? const Text('No logs.', style: TextStyle(color: Colors.grey, fontSize: 12))
                    : SingleChildScrollView(
                        child: Text(
                          _logs.join('\n'),
                          style: const TextStyle(
                            color: Colors.greenAccent,
                            fontSize: 11,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _copyLogs,
                      icon: const Icon(Icons.copy, size: 16, color: Colors.white),
                      label: const Text('Copy logs',
                          style: TextStyle(color: Colors.white)),
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.white38)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _clearLogs,
                      icon: const Icon(Icons.delete_outline, size: 16, color: Colors.redAccent),
                      label: const Text('Clear logs',
                          style: TextStyle(color: Colors.redAccent)),
                      style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.redAccent)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _masked(String envKey, String displayKey) {
    final val = const String.fromEnvironment('HMS_APP_ID', defaultValue: '');
    if (val.isEmpty) return '$displayKey=(not set)';
    final visible = val.length > 4 ? val.substring(0, 4) : val;
    return '$displayKey=$visible****';
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        color: Colors.grey,
        fontSize: 11,
        letterSpacing: 1.2,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.key_, this.value);
  final String key_;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(key_,
                style: const TextStyle(color: Colors.grey, fontSize: 13)),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

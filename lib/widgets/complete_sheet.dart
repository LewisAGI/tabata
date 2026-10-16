import 'package:flutter/material.dart';

import '../export/format.dart';
import '../models/session_log.dart';
import '../services/share_text.dart';
import '../theme/app_theme.dart';
import 'icon_tip.dart';

enum ExportKind { session, day, week }

Future<void> showCompleteSheet(
  BuildContext context, {
  required SessionLog log,
  required List<SessionLog> history,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => CompleteSheet(log: log, history: history),
  );
}

class CompleteSheet extends StatefulWidget {
  const CompleteSheet({super.key, required this.log, required this.history});

  final SessionLog log;
  final List<SessionLog> history;

  @override
  State<CompleteSheet> createState() => _CompleteSheetState();
}

class _CompleteSheetState extends State<CompleteSheet> {
  ExportKind _kind = ExportKind.session;

  String get _text {
    return switch (_kind) {
      ExportKind.session => exportSession(widget.log),
      ExportKind.day => exportDay(widget.log.startedAt, widget.history),
      ExportKind.week => exportWeek(widget.log.startedAt, widget.history),
    };
  }

  String get _scope {
    return switch (_kind) {
      ExportKind.session => 'SESSION',
      ExportKind.day => 'DAY',
      ExportKind.week => 'WEEK',
    };
  }

  Future<void> _pickScope() async {
    final box = context.findRenderObject();
    if (box is! RenderBox || !box.hasSize) {
      return;
    }
    final overlay = Navigator.of(context).overlay?.context.findRenderObject();
    if (overlay is! RenderBox) {
      return;
    }
    final origin = box.localToGlobal(Offset.zero, ancestor: overlay);
    final selected = await showMenu<ExportKind>(
      context: context,
      position: RelativeRect.fromRect(
        origin & const Size(40, 40),
        Offset.zero & overlay.size,
      ),
      items: const [
        PopupMenuItem(value: ExportKind.session, child: Text('Session')),
        PopupMenuItem(value: ExportKind.day, child: Text('Day')),
        PopupMenuItem(value: ExportKind.week, child: Text('Week')),
      ],
    );
    if (selected != null && mounted) {
      setState(() => _kind = selected);
    }
  }

  @override
  Widget build(BuildContext context) {
    final log = widget.log;
    final when =
        '${fmtWeekdayDate(log.startedAt)} · ${fmtHm(log.startedAt.hour, log.startedAt.minute)}';
    final maxHeight = MediaQuery.sizeOf(context).height * 0.92;
    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxHeight),
      child: SingleChildScrollView(
        child: Padding(
          key: const ValueKey('complete-sheet'),
          padding: const EdgeInsets.fromLTRB(20, 10, 12, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.hairline,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  Tooltip(
                    message: 'Scope',
                    child: InkWell(
                      onTap: _pickScope,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          _scope,
                          key: const ValueKey('export-scope'),
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.6,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconTip(
                    icon: Icons.close,
                    message: 'Close',
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Text(
                log.presetName,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                when,
                style: const TextStyle(color: AppColors.muted, fontSize: 15),
              ),
              const SizedBox(height: 12),
              if (log.prep > 0) _stat('Prep', '${log.prep}s'),
              _stat('Work', '${log.work}s'),
              _stat('Rest', '${log.rest}s'),
              _stat('Rounds', '${log.rounds}'),
              _stat('Sets', '${log.sets}'),
              if (log.setRest > 0)
                _stat('Rest between sets', '${log.setRest}s'),
              if (log.cooldown > 0) _stat('Cooldown', '${log.cooldown}s'),
              _stat('Total time', fmtClock(log.totalSeconds)),
              _stat('Status', log.statusLabel),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _action(
                    icon: Icons.copy,
                    message: 'Copy',
                    filled: false,
                    onPressed: (_) async {
                      await copyPlainText(_text);
                    },
                  ),
                  const SizedBox(width: 22),
                  _action(
                    icon: Icons.auto_awesome,
                    message: 'Grok',
                    filled: true,
                    onPressed: (button) => sharePlainText(button, _text),
                  ),
                  const SizedBox(width: 22),
                  _action(
                    icon: Icons.ios_share,
                    message: 'Share',
                    filled: false,
                    onPressed: (button) =>
                        sharePlainText(button, _text, asFile: true),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 16, color: AppColors.muted),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }

  Widget _action({
    required IconData icon,
    required String message,
    required bool filled,
    required Future<void> Function(BuildContext button) onPressed,
  }) {
    return Tooltip(
      message: message,
      child: Builder(
        builder: (button) => Material(
          color: filled ? AppColors.accent : AppColors.accentSoft,
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: () => onPressed(button),
            child: SizedBox(
              width: 56,
              height: 56,
              child: Icon(
                icon,
                color: filled ? Colors.white : AppColors.accent,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

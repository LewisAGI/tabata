import 'package:flutter/material.dart';

import '../export/format.dart';
import '../models/session_log.dart';
import '../theme/app_theme.dart';
import '../widgets/complete_sheet.dart';
import 'scope.dart';

class LogScreen extends StatefulWidget {
  const LogScreen({super.key});

  @override
  State<LogScreen> createState() => _LogScreenState();
}

class _LogScreenState extends State<LogScreen> {
  List<SessionLog> _sessions = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _sessions = _sorted();
  }

  List<SessionLog> _sorted() {
    final items = TabataScope.of(context).store.sessions();
    items.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Log')),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: _sessions.length,
        separatorBuilder: (_, _) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final session = _sessions[index];
          final when =
              '${fmtWeekdayDate(session.startedAt)} · ${fmtHm(session.startedAt.hour, session.startedAt.minute)}';
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(22),
              onTap: () => showCompleteSheet(
                context,
                log: session,
                history: TabataScope.of(context).store.sessions(),
              ),
              child: Ink(
                decoration: cardBox(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.presetName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            when,
                            style: const TextStyle(color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          fmtClock(session.totalSeconds),
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          session.statusLabel,
                          style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

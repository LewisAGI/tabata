import 'package:flutter/material.dart';

import '../models/preset.dart';
import '../theme/app_theme.dart';
import '../widgets/icon_tip.dart';
import '../widgets/ruler_sheet.dart';
import 'scope.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, required this.preset});

  final Preset preset;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  late final TextEditingController _name;
  late int _prep;
  late int _work;
  late int _rest;
  late int _rounds;
  late int _sets;
  late int _setRest;
  late int _cooldown;

  @override
  void initState() {
    super.initState();
    final preset = widget.preset;
    _name = TextEditingController(text: preset.name);
    _prep = preset.prep;
    _work = preset.work;
    _rest = preset.rest;
    _rounds = preset.rounds;
    _sets = preset.sets;
    _setRest = preset.setRest;
    _cooldown = preset.cooldown;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  int _value(String field) {
    return switch (field) {
      'prep' => _prep,
      'work' => _work,
      'rest' => _rest,
      'rounds' => _rounds,
      'sets' => _sets,
      'setRest' => _setRest,
      _ => _cooldown,
    };
  }

  void _assign(String field, int value) {
    setState(() {
      switch (field) {
        case 'prep':
          _prep = value;
        case 'work':
          _work = value;
        case 'rest':
          _rest = value;
        case 'rounds':
          _rounds = value;
        case 'sets':
          _sets = value;
        case 'setRest':
          _setRest = value;
        default:
          _cooldown = value;
      }
    });
  }

  void _bump(String field, int min, int max, int step, int direction) {
    _assign(field, (_value(field) + direction * step).clamp(min, max));
  }

  Future<void> _ruler({
    required String field,
    required String title,
    required int min,
    required int max,
  }) {
    return showRuler(
      context: context,
      title: title,
      value: _value(field),
      min: min,
      max: max,
      onChanged: (value) => _assign(field, value),
    );
  }

  Future<void> _save() async {
    final preset = widget.preset
        .copyWith(
          name: _name.text,
          prep: _prep,
          work: _work,
          rest: _rest,
          rounds: _rounds,
          sets: _sets,
          setRest: _setRest,
          cooldown: _cooldown,
        )
        .normalized();
    await TabataScope.read(context).store.savePreset(preset);
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.preset.name.trim().isEmpty
        ? 'Preset'
        : widget.preset.name;
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          IconTip(icon: Icons.check, message: 'Save', onPressed: () => _save()),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
        children: [
          TextField(
            key: const ValueKey('preset-name'),
            controller: _name,
            textCapitalization: TextCapitalization.words,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.6,
            ),
            decoration: const InputDecoration(
              hintText: 'Name',
              border: InputBorder.none,
              isCollapsed: true,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _BigStepper(
                  field: 'work',
                  unit: 'work',
                  value: _work,
                  onMinus: () => _bump('work', 5, 300, 5, -1),
                  onPlus: () => _bump('work', 5, 300, 5, 1),
                  onValue: () =>
                      _ruler(field: 'work', title: 'Work', min: 5, max: 300),
                ),
              ),
              const Padding(
                padding: EdgeInsets.only(top: 28),
                child: Text(
                  '–',
                  style: TextStyle(
                    fontSize: 28,
                    color: AppColors.muted,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Expanded(
                child: _BigStepper(
                  field: 'rest',
                  unit: 'rest',
                  value: _rest,
                  onMinus: () => _bump('rest', 0, 180, 5, -1),
                  onPlus: () => _bump('rest', 0, 180, 5, 1),
                  onValue: () =>
                      _ruler(field: 'rest', title: 'Rest', min: 0, max: 180),
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          _CountRow(
            field: 'rounds',
            label: 'Rounds',
            value: _rounds,
            onMinus: () => _bump('rounds', 1, 30, 1, -1),
            onPlus: () => _bump('rounds', 1, 30, 1, 1),
            onValue: () =>
                _ruler(field: 'rounds', title: 'Rounds', min: 1, max: 30),
          ),
          _CountRow(
            field: 'sets',
            label: 'Sets',
            value: _sets,
            onMinus: () => _bump('sets', 1, 10, 1, -1),
            onPlus: () => _bump('sets', 1, 10, 1, 1),
            onValue: () =>
                _ruler(field: 'sets', title: 'Sets', min: 1, max: 10),
          ),
          _CountRow(
            field: 'prep',
            label: 'Prep',
            value: _prep,
            onMinus: () => _bump('prep', 0, 120, 5, -1),
            onPlus: () => _bump('prep', 0, 120, 5, 1),
            onValue: () =>
                _ruler(field: 'prep', title: 'Prep', min: 0, max: 120),
          ),
          _CountRow(
            field: 'setRest',
            label: 'Set rest',
            value: _setRest,
            onMinus: () => _bump('setRest', 0, 300, 5, -1),
            onPlus: () => _bump('setRest', 0, 300, 5, 1),
            onValue: () =>
                _ruler(field: 'setRest', title: 'Set rest', min: 0, max: 300),
          ),
          _CountRow(
            field: 'cooldown',
            label: 'Cooldown',
            value: _cooldown,
            onMinus: () => _bump('cooldown', 0, 180, 5, -1),
            onPlus: () => _bump('cooldown', 0, 180, 5, 1),
            onValue: () =>
                _ruler(field: 'cooldown', title: 'Cooldown', min: 0, max: 180),
          ),
        ],
      ),
    );
  }
}

class _BigStepper extends StatelessWidget {
  const _BigStepper({
    required this.field,
    required this.unit,
    required this.value,
    required this.onMinus,
    required this.onPlus,
    required this.onValue,
  });

  final String field;
  final String unit;
  final int value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onValue;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onValue,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              '$value',
              key: ValueKey('$field-value'),
              style: const TextStyle(
                fontSize: 64,
                fontWeight: FontWeight.w700,
                height: 1,
                letterSpacing: -2,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          unit,
          style: const TextStyle(color: AppColors.muted, fontSize: 16),
        ),
        const SizedBox(height: 12),
        DecoratedBox(
          decoration: BoxDecoration(
            color: AppColors.field,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              Expanded(
                child: IconTip(
                  key: ValueKey('$field-less'),
                  icon: Icons.remove,
                  message: 'Less',
                  color: AppColors.ink,
                  onPressed: onMinus,
                ),
              ),
              Container(width: 1, height: 22, color: AppColors.hairline),
              Expanded(
                child: IconTip(
                  key: ValueKey('$field-more'),
                  icon: Icons.add,
                  message: 'More',
                  color: AppColors.ink,
                  onPressed: onPlus,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CountRow extends StatelessWidget {
  const _CountRow({
    required this.field,
    required this.label,
    required this.value,
    required this.onMinus,
    required this.onPlus,
    required this.onValue,
  });

  final String field;
  final String label;
  final int value;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final VoidCallback onValue;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          IconTip(
            key: ValueKey('$field-less'),
            icon: Icons.remove,
            message: 'Less',
            color: AppColors.ink,
            onPressed: onMinus,
          ),
          GestureDetector(
            onTap: onValue,
            child: SizedBox(
              width: 56,
              child: Text(
                '$value',
                key: ValueKey('$field-value'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          IconTip(
            key: ValueKey('$field-more'),
            icon: Icons.add,
            message: 'More',
            color: AppColors.ink,
            onPressed: onPlus,
          ),
        ],
      ),
    );
  }
}

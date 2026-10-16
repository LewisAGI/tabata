class Preset {
  const Preset({
    required this.id,
    required this.name,
    required this.prep,
    required this.work,
    required this.rest,
    required this.rounds,
    required this.sets,
    required this.setRest,
    required this.cooldown,
  });

  final String id;
  final String name;
  final int prep;
  final int work;
  final int rest;
  final int rounds;
  final int sets;
  final int setRest;
  final int cooldown;

  static const classic = Preset(
    id: 'classic',
    name: 'Classic',
    prep: 10,
    work: 20,
    rest: 10,
    rounds: 8,
    sets: 1,
    setRest: 0,
    cooldown: 0,
  );

  factory Preset.draft() {
    return Preset(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: '',
      prep: 10,
      work: 20,
      rest: 10,
      rounds: 8,
      sets: 1,
      setRest: 0,
      cooldown: 0,
    );
  }

  /// `20/10 × 8`, with the set count when there is more than one.
  String get cardLine {
    final base = '$work/$rest × $rounds';
    if (sets > 1) {
      return '$base · $sets';
    }
    return base;
  }

  Preset normalized() {
    final trimmed = name.trim();
    return copyWith(
      name: trimmed.isEmpty ? 'Tabata' : trimmed,
      prep: prep.clamp(0, 3600),
      work: work.clamp(1, 3600),
      rest: rest.clamp(0, 3600),
      rounds: rounds.clamp(1, 99),
      sets: sets.clamp(1, 99),
      setRest: setRest.clamp(0, 3600),
      cooldown: cooldown.clamp(0, 3600),
    );
  }

  Preset copyWith({
    String? id,
    String? name,
    int? prep,
    int? work,
    int? rest,
    int? rounds,
    int? sets,
    int? setRest,
    int? cooldown,
  }) {
    return Preset(
      id: id ?? this.id,
      name: name ?? this.name,
      prep: prep ?? this.prep,
      work: work ?? this.work,
      rest: rest ?? this.rest,
      rounds: rounds ?? this.rounds,
      sets: sets ?? this.sets,
      setRest: setRest ?? this.setRest,
      cooldown: cooldown ?? this.cooldown,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'prep': prep,
    'work': work,
    'rest': rest,
    'rounds': rounds,
    'sets': sets,
    'setRest': setRest,
    'cooldown': cooldown,
  };

  factory Preset.fromJson(Map<String, dynamic> json) {
    return Preset(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Tabata',
      prep: _int(json['prep']),
      work: _int(json['work'], fallback: 20),
      rest: _int(json['rest']),
      rounds: _int(json['rounds'], fallback: 8),
      sets: _int(json['sets'], fallback: 1),
      setRest: _int(json['setRest']),
      cooldown: _int(json['cooldown']),
    ).normalized();
  }
}

int _int(Object? value, {int fallback = 0}) {
  if (value is num) {
    return value.toInt();
  }
  return fallback;
}

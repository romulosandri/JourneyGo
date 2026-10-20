import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/journey.dart';

class JourneyStoreException implements Exception {
  const JourneyStoreException(this.message);

  final String message;

  @override
  String toString() => message;
}

class JourneyRepository {
  JourneyRepository(this._preferences);

  static const storageKey = 'journeys.v1';

  final SharedPreferences _preferences;

  /// Returns null when nothing has been saved yet.
  Future<List<Journey>?> read() async {
    final raw = _preferences.getString(storageKey);
    if (raw == null) {
      return null;
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        throw const FormatException('Journeys were not a list.');
      }
      return [
        for (final item in decoded)
          if (item is Map)
            Journey.fromJson(Map<String, Object?>.from(item))
          else
            throw const FormatException('A journey was not an object.'),
      ];
    } on FormatException {
      throw const JourneyStoreException('Could not read your journeys.');
    }
  }

  Future<void> write(List<Journey> journeys) async {
    final encoded = jsonEncode([
      for (final journey in journeys) journey.toJson(),
    ]);
    final saved = await _preferences.setString(storageKey, encoded);
    if (!saved) {
      throw const JourneyStoreException('Could not save your journeys.');
    }
  }
}

import 'package:flutter/foundation.dart';

import '../data/journey_repository.dart';
import '../data/sample_journeys.dart';
import '../models/journey.dart';

class JourneyController extends ChangeNotifier {
  JourneyController(this._repository, {DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  final JourneyRepository _repository;
  final DateTime Function() _clock;

  List<Journey> journeys = const [];
  bool loading = true;
  String? error;

  DateTime get today => _clock();

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final stored = await _repository.read();
      if (stored == null) {
        journeys = sortJourneys(sampleJourneys(today), today);
        await _repository.write(journeys);
      } else {
        journeys = sortJourneys(stored, today);
      }
    } on JourneyStoreException catch (exception) {
      journeys = const [];
      error = exception.message;
    } catch (_) {
      journeys = const [];
      error = 'Could not open your journeys.';
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Journey? find(String id) {
    for (final journey in journeys) {
      if (journey.id == id) {
        return journey;
      }
    }
    return null;
  }

  Future<void> saveJourney(Journey journey) async {
    final index = journeys.indexWhere((item) => item.id == journey.id);
    if (index == -1) {
      journeys = [...journeys, journey];
    } else {
      journeys = [
        for (var i = 0; i < journeys.length; i++)
          if (i == index) journey else journeys[i],
      ];
    }
    journeys = sortJourneys(journeys, today);
    await _persist();
  }

  Future<void> deleteJourney(String id) async {
    journeys = [
      for (final journey in journeys)
        if (journey.id != id) journey,
    ];
    await _persist();
  }

  Future<void> saveStop(String journeyId, Stop stop) async {
    journeys = [
      for (final journey in journeys)
        if (journey.id != journeyId)
          journey
        else
          journey.copyWith(stops: _upsertStop(journey.stops, stop)),
    ];
    await _persist();
  }

  Future<void> toggleStop(String journeyId, String stopId) async {
    journeys = [
      for (final journey in journeys)
        if (journey.id != journeyId)
          journey
        else
          journey.copyWith(
            stops: [
              for (final stop in journey.stops)
                if (stop.id == stopId)
                  stop.copyWith(done: !stop.done)
                else
                  stop,
            ],
          ),
    ];
    await _persist();
  }

  Future<void> deleteStop(String journeyId, String stopId) async {
    journeys = [
      for (final journey in journeys)
        if (journey.id != journeyId)
          journey
        else
          journey.copyWith(
            stops: [
              for (final stop in journey.stops)
                if (stop.id != stopId) stop,
            ],
          ),
    ];
    await _persist();
  }

  Future<void> moveStop(String journeyId, String stopId, int delta) async {
    journeys = [
      for (final journey in journeys)
        if (journey.id != journeyId)
          journey
        else
          journey.copyWith(stops: _moveStop(journey.stops, stopId, delta)),
    ];
    await _persist();
  }

  Future<void> restoreSamples() async {
    error = null;
    journeys = sortJourneys(sampleJourneys(today), today);
    await _persist();
  }

  Future<void> _persist() async {
    try {
      await _repository.write(journeys);
      error = null;
    } on JourneyStoreException catch (exception) {
      error = exception.message;
    } catch (_) {
      error = 'Could not save your journeys.';
    }
    notifyListeners();
  }

  List<Stop> _upsertStop(List<Stop> stops, Stop stop) {
    final index = stops.indexWhere((item) => item.id == stop.id);
    if (index == -1) {
      return [...stops, stop];
    }
    return [
      for (var i = 0; i < stops.length; i++)
        if (i == index) stop else stops[i],
    ];
  }

  List<Stop> _moveStop(List<Stop> stops, String stopId, int delta) {
    final index = stops.indexWhere((stop) => stop.id == stopId);
    final target = index + delta;
    if (index < 0 || target < 0 || target >= stops.length) {
      return stops;
    }
    final next = [...stops];
    final stop = next.removeAt(index);
    next.insert(target, stop);
    return next;
  }
}

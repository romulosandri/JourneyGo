import '../models/journey.dart';

List<Journey> sampleJourneys(DateTime now) {
  final today = dateOnly(now);
  return [
    Journey(
      id: 'sample-lisbon',
      title: 'A long weekend by the river',
      place: 'Lisbon',
      start: today.subtract(const Duration(days: 1)),
      end: today.add(const Duration(days: 2)),
      note: 'Trams in the morning, a miradouro before the light goes.',
      accent: JourneyAccent.terracotta,
      stops: const [
        Stop(
          id: 'lx-market',
          name: 'Time Out Market',
          detail: 'Lunch before the hills',
          done: true,
        ),
        Stop(
          id: 'lx-alfama',
          name: 'Alfama',
          detail: 'Wander until a tram appears',
          done: true,
        ),
        Stop(
          id: 'lx-factory',
          name: 'LX Factory',
          detail: 'Bookshops under the bridge',
        ),
        Stop(id: 'lx-belem', name: 'Belém', detail: 'Pastéis, then the river'),
        Stop(
          id: 'lx-monte',
          name: 'Senhora do Monte',
          detail: 'Sunset if the wind is kind',
        ),
      ],
    ),
    Journey(
      id: 'sample-oaxaca',
      title: 'Markets, mezcal, and the hills',
      place: 'Oaxaca',
      start: today.add(const Duration(days: 18)),
      end: today.add(const Duration(days: 22)),
      note: 'Markets first, then the ruins once the day cools.',
      accent: JourneyAccent.gold,
      stops: const [
        Stop(
          id: 'ox-market',
          name: 'Mercado 20 de Noviembre',
          detail: 'Grill smoke and chocolate',
        ),
        Stop(
          id: 'ox-monte',
          name: 'Monte Albán',
          detail: 'Go before the tour buses',
        ),
        Stop(
          id: 'ox-hierve',
          name: 'Hierve el Agua',
          detail: 'Mineral pools over the valley',
        ),
      ],
    ),
    Journey(
      id: 'sample-kyoto',
      title: 'Temples before the crowds',
      place: 'Kyoto',
      start: today.subtract(const Duration(days: 17)),
      end: today.subtract(const Duration(days: 12)),
      note: 'Walked the shrines early and ate in Nishiki after.',
      accent: JourneyAccent.sea,
      stops: const [
        Stop(
          id: 'ky-inari',
          name: 'Fushimi Inari',
          detail: 'Gates at opening time',
          done: true,
        ),
        Stop(
          id: 'ky-nishiki',
          name: 'Nishiki Market',
          detail: 'Pick one thing and eat it there',
          done: true,
        ),
        Stop(
          id: 'ky-arashiyama',
          name: 'Arashiyama',
          detail: 'Bamboo, then the river path',
          done: true,
        ),
        Stop(
          id: 'ky-path',
          name: "Philosopher's Path",
          detail: 'Slow walk, no plan',
          done: true,
        ),
      ],
    ),
  ];
}

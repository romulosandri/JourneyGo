# JourneyGo

JourneyGo is a travel planner for Android and iOS. Keep a journey for each trip, put the places in the order you want to meet them, and tick a stop off when you have been there. Journeys stay on the phone.

The first launch includes three example routes — Lisbon, Oaxaca, and Kyoto — so there is something to edit immediately. Deleting them is permanent until you add your own.

## Run

This project targets Android and iOS only.

```bash
python3 tool/restore_assets.py
flutter pub get
flutter run
```

`restore_assets.py` writes the bundled Fraunces and Outfit fonts and the launcher icons. Run it once after cloning. Use a connected phone or an emulator. `flutter run` will ask you to pick a device when more than one is available.

## Tests

```bash
flutter analyze
flutter test
```

## Fonts

Fraunces and Outfit are bundled under `assets/fonts` and used under the SIL Open Font License. The license text sits next to each family.

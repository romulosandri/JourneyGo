# JourneyGo

JourneyGo is a phone-sized playground for planning a trip with a group. There is no backend. A trip moves through five timed decisions — destination, dates, budget, activities, and stay — and then a commitment that is never assumed.

The people and places are fictional: Ana, Bruno, Caio, Duda, Leo, and Mari, heading toward Costa Lumen, Vale Alto, Lake Marrow, or Ilha Sereno.

## Run

```bash
python3 tool/restore_assets.py
flutter pub get
flutter run -d chrome
```

`restore_assets.py` downloads Fraunces and Outfit (Fontsource 5.2.8, SIL Open Font License). The font files stay out of git. The playground bar above the phone frame switches the viewer, jumps to a sample trip, advances a deadline, and toggles offline.

## Tests

```bash
flutter analyze
flutter test
```

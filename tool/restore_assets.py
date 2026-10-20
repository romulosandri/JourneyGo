"""Download the OFL fonts and draw the JourneyGo launcher mark.

The TrueType files come from Fontsource on jsDelivr. The mark is drawn
locally, so a clone does not need the binary files checked in.
"""

import urllib.request
from pathlib import Path

import make_icon

ROOT = Path(__file__).resolve().parents[1]
FONTS = ROOT / "assets" / "fonts"

FONT_URLS = {
    "Fraunces-Regular.ttf": (
        "https://cdn.jsdelivr.net/fontsource/fonts/fraunces@5.2.8/latin-400-normal.ttf"
    ),
    "Fraunces-SemiBold.ttf": (
        "https://cdn.jsdelivr.net/fontsource/fonts/fraunces@5.2.8/latin-600-normal.ttf"
    ),
    "Outfit-Regular.ttf": (
        "https://cdn.jsdelivr.net/fontsource/fonts/outfit@5.2.8/latin-400-normal.ttf"
    ),
    "Outfit-Medium.ttf": (
        "https://cdn.jsdelivr.net/fontsource/fonts/outfit@5.2.8/latin-500-normal.ttf"
    ),
    "Outfit-SemiBold.ttf": (
        "https://cdn.jsdelivr.net/fontsource/fonts/outfit@5.2.8/latin-600-normal.ttf"
    ),
}

TRUE_TYPE = b"\x00\x01\x00\x00"


def main() -> None:
    FONTS.mkdir(parents=True, exist_ok=True)
    for name, url in FONT_URLS.items():
        destination = FONTS / name
        urllib.request.urlretrieve(url, destination)
        header = destination.read_bytes()[:4]
        if header != TRUE_TYPE:
            raise SystemExit(f"{name} did not download as a TrueType font.")
        print(f"Wrote assets/fonts/{name}")
    make_icon.main()
    print("Drew assets/brand/app_icon.png and app_icon_foreground.png.")
    print("Next: flutter pub get && dart run flutter_launcher_icons")


if __name__ == "__main__":
    main()

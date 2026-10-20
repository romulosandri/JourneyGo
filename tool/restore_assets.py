"""Write the fonts and launcher icons stored in tool/payloads."""

import base64
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PAYLOADS = Path(__file__).resolve().parent / "payloads"


def main() -> None:
    count = 0
    for payload in sorted(PAYLOADS.glob("*.json")):
        manifest = json.loads(payload.read_text())
        for relative, encoded in manifest.items():
            destination = ROOT / relative
            destination.parent.mkdir(parents=True, exist_ok=True)
            destination.write_bytes(base64.b64decode(encoded))
            count += 1
    print(f"Restored {count} fonts and icons.")


if __name__ == "__main__":
    main()

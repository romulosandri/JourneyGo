"""Draw the JourneyGo launcher mark."""

from pathlib import Path

from PIL import Image, ImageDraw

ROOT = Path(__file__).resolve().parents[1]
BRAND = ROOT / "assets" / "brand"
INK = (30, 26, 22, 255)
PAPER = (243, 238, 228, 255)
TERRA = (224, 122, 76, 255)


def curve(start, control, end, steps=48):
    points = []
    for index in range(steps + 1):
        t = index / steps
        x = (1 - t) ** 2 * start[0] + 2 * (1 - t) * t * control[0] + t**2 * end[0]
        y = (1 - t) ** 2 * start[1] + 2 * (1 - t) * t * control[1] + t**2 * end[1]
        points.append((x, y))
    return points


def draw(size, background):
    image = Image.new("RGBA", (size, size), background)
    canvas = ImageDraw.Draw(image)
    start = (size * 0.24, size * 0.70)
    mid = (size * 0.50, size * 0.50)
    end = (size * 0.76, size * 0.32)
    points = curve(start, (size * 0.42, size * 0.64), mid) + curve(
        mid, (size * 0.60, size * 0.36), end
    )
    width = max(8, int(size * 0.045))
    radius = width / 2
    for x, y in points:
        canvas.ellipse((x - radius, y - radius, x + radius, y + radius), fill=PAPER)
    radius = int(size * 0.055)
    for point, color in ((start, TERRA), (end, PAPER)):
        box = (
            point[0] - radius,
            point[1] - radius,
            point[0] + radius,
            point[1] + radius,
        )
        canvas.ellipse(box, fill=color)
    return image


def main():
    BRAND.mkdir(parents=True, exist_ok=True)
    icon = draw(1024, INK)
    icon.save(BRAND / "app_icon.png")
    draw(1024, (0, 0, 0, 0)).save(BRAND / "app_icon_foreground.png")


if __name__ == "__main__":
    main()

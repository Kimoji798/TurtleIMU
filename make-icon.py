# -*- coding: utf-8 -*-
"""TurtleIMU app icon: dark rounded square + 3-axis sensor (X/Y/Z) + turtle hub."""
import math
import os
from PIL import Image, ImageDraw

BASE = os.path.dirname(os.path.abspath(__file__))
WWW = os.path.join(BASE, "www")

SIZE = 1024
SS = 4
W = SIZE * SS
CX = W / 2.0
CY = W / 2.0

RING_R = W * 0.36
AXIS_R0 = W * 0.10
AXIS_LEN = W * 0.22
HUB_R = W * 0.095


def pt(angle_deg, r):
    a = math.radians(angle_deg)
    return (CX + r * math.cos(a), CY + r * math.sin(a))


def vertical_gradient(img, top, bottom):
    d = ImageDraw.Draw(img)
    h = img.size[1]
    for y in range(h):
        t = y / (h - 1)
        c = tuple(int(top[i] + (bottom[i] - top[i]) * t) for i in range(3))
        d.line([(0, y), (img.size[0], y)], fill=c)


def arrow(d, angle_deg, color, width):
    p1 = pt(angle_deg, AXIS_R0)
    p2 = pt(angle_deg, AXIS_R0 + AXIS_LEN)
    d.line([p1, p2], fill=color, width=width)
    hl = AXIS_LEN * 0.30
    tip = pt(angle_deg, AXIS_R0 + AXIS_LEN + hl)
    b1 = pt(angle_deg + 152, AXIS_R0 + AXIS_LEN)
    b2 = pt(angle_deg - 152, AXIS_R0 + AXIS_LEN)
    d.polygon([tip, b1, b2], fill=color)


def draw_t(d, cx, cy, s, color):
    bar_w = s * 1.05
    bar_h = s * 0.34
    d.rectangle([cx - bar_w / 2, cy - s * 0.52, cx + bar_w / 2, cy - s * 0.52 + bar_h], fill=color)
    stem_w = s * 0.36
    d.rectangle([cx - stem_w / 2, cy - s * 0.52, cx + stem_w / 2, cy + s * 0.60], fill=color)


def main():
    img = Image.new("RGB", (W, W), (13, 13, 15))
    vertical_gradient(img, (32, 32, 38), (7, 7, 9))
    d = ImageDraw.Draw(img)

    d.ellipse([CX - RING_R - 8, CY - RING_R - 8, CX + RING_R + 8, CY + RING_R + 8],
              outline=(235, 235, 240), width=8)

    arrow(d, 0, (255, 69, 58), 26)     # X right (red)
    arrow(d, -90, (48, 209, 88), 26)   # Y up (green)
    arrow(d, 210, (10, 132, 255), 26)  # Z down-left (blue)

    hub = [pt(90 + 60 * i, HUB_R) for i in range(6)]
    d.polygon(hub, fill=(46, 158, 99), outline=(18, 80, 50), width=10)
    draw_t(d, CX, CY, HUB_R * 1.15, (255, 255, 255))

    mask = Image.new("L", (W, W), 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, W - 1, W - 1], radius=int(W * 0.2237), fill=255)
    out = Image.new("RGBA", (W, W), (0, 0, 0, 0))
    out.paste(img, (0, 0), mask)
    master = out.resize((SIZE, SIZE), Image.LANCZOS)

    paths = [
        os.path.join(WWW, "icon-1024.png"),
        os.path.join(WWW, "icon-180.png"),
        os.path.join(WWW, "favicon-32.png"),
        os.path.join(BASE, "icon-1024.png"),
    ]
    master.save(paths[0], "PNG")
    master.resize((180, 180), Image.LANCZOS).save(paths[1], "PNG")
    master.resize((32, 32), Image.LANCZOS).save(paths[2], "PNG")
    master.save(paths[3], "PNG")
    for p in paths:
        print(p, os.path.getsize(p))


if __name__ == "__main__":
    main()
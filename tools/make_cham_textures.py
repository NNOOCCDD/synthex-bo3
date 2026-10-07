"""Generate the zombie-cham textures (mod/synthex/images/sx_*.tif): hex grid, glitch scanlines, plasma, flow map.
White/grey patterns - the materials tint them. Run with any Python that has Pillow."""
import math, os, random
from PIL import Image, ImageDraw, ImageFilter

OUT = os.path.join(os.path.dirname(__file__), "..", "mod", "synthex", "images")
N = 256
random.seed(7)

def save(img, name):
    img.convert("RGBA").save(os.path.join(OUT, name + ".tif"), compression=None)

# hex grid: glowing white lines on black
img = Image.new("L", (N, N), 0)
d = ImageDraw.Draw(img)
r = 16
h = math.sqrt(3) * r
for row in range(-2, int(N / h) + 3):
    for col in range(-2, int(N / (1.5 * r)) + 3):
        cx, cy = col * 1.5 * r, row * h + (h / 2 if col % 2 else 0)
        d.line([(cx + r * math.cos(math.radians(60 * k)), cy + r * math.sin(math.radians(60 * k))) for k in range(7)], fill=255, width=2)
img = Image.eval(Image.blend(img.filter(ImageFilter.GaussianBlur(3)), img, 0.6), lambda v: min(255, int(v * 1.6)))
save(img, "sx_hex")

# glitch: faint scanlines plus bright horizontal bands (wrapping, so it tiles)
img = Image.new("L", (N, N), 0)
d = ImageDraw.Draw(img)
for y in range(0, N, 4):
    d.line([(0, y), (N, y)], fill=90)
for _ in range(14):
    y, hgt, x0, w = random.randrange(N), random.randrange(2, 14), random.randrange(N), random.randrange(40, N)
    v = random.randrange(160, 256)
    d.rectangle([x0, y, x0 + w, y + hgt], fill=v)
    d.rectangle([x0 - N, y, x0 + w - N, y + hgt], fill=v)
save(img, "sx_scan")

# plasma: soft tileable blobs
big = Image.new("L", (N * 3, N * 3), 0)
d = ImageDraw.Draw(big)
for _ in range(60):
    x, y, rr, v = random.randrange(N), random.randrange(N), random.randrange(10, 50), random.randrange(80, 256)
    for ox in (0, N, 2 * N):
        for oy in (0, N, 2 * N):
            d.ellipse([x + ox - rr, y + oy - rr, x + ox + rr, y + oy + rr], fill=v)
img = big.filter(ImageFilter.GaussianBlur(14)).crop((N, N, 2 * N, 2 * N))
save(Image.eval(img, lambda v: min(255, max(0, int((v - 70) * 1.8)))), "sx_plasma")

# flow map: smooth direction field in R/G (128 = still)
rch, gch = Image.new("L", (N, N)), Image.new("L", (N, N))
rp, gp = rch.load(), gch.load()
for y in range(N):
    for x in range(N):
        a = math.sin(2 * math.pi * x / N * 2) + math.cos(2 * math.pi * y / N * 3)
        rp[x, y], gp[x, y] = int(128 + 100 * math.cos(a)), int(128 + 100 * math.sin(a))
Image.merge("RGBA", (rch, gch, Image.new("L", (N, N), 128), Image.new("L", (N, N), 255))).save(os.path.join(OUT, "sx_flow.tif"), compression=None)

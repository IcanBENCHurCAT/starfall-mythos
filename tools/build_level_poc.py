#!/usr/bin/env python3
"""POC: Level 1 'Crash Field Approach' tilemap for STARFALL MYTHOS.

Not playable. Renders correctly-mapped tiles for the first level so the
look, tile mapping, and night palette can be judged before engine work.

Tiles: Superpowers Medieval Fantasy pack (CC0, Pixel-boy / sparklinlabs),
  assets/third-party/superpowers-medieval-fantasy/background-elements/0-tileset.png
  Sheet grid: 20x12 cells of 16x16. Indices below are cell numbers (row*20+col).
Custom: the three signal-fragment crystal tiles are drawn here in the same
  chunky 16x16 style (teal glow crystals); everything else is curated, not generated.

Tile map used:
    21  ground (night-graded grass -> alien soil)
    29  dirt path
    86  tent (bg keyed out)
    92  round tree      112 pine tree      196 big tree
   116  crate            156 campfire (bg keyed out)
  F1/F2/F3  custom fragment crystals (large/medium/small)

Run: python3 tools/build_level_poc.py
Out: concept/level1-poc.png (2x, 1280x736)
"""
import math, os, random
from collections import deque
from PIL import Image

T = 16
W, H = 40, 23
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SHEET = os.path.join(ROOT, 'assets/third-party/superpowers-medieval-fantasy',
                     'background-elements/0-tileset.png')
OUT = os.path.join(ROOT, 'concept/level1-poc.png')

GROUND, PATH = 21, 29
TENT, FIRE, CRATE = 86, 156, 116
TREES = (92, 112, 196)


def cell(sheet, idx):
    c, r = idx % 20, idx // 20
    return sheet.crop((c * T, r * T, c * T + T, r * T + T))


def key_background(tile, tol=48):
    """Flood-fill transparent from the edges through near-corner-color pixels."""
    tile = tile.convert('RGBA')
    px = tile.load()
    target = px[0, 0][:3]
    seen = set()
    q = deque()
    for x in range(T):
        q += [(x, 0), (x, T - 1)]
    for y in range(T):
        q += [(0, y), (T - 1, y)]
    while q:
        x, y = q.popleft()
        if (x, y) in seen or not (0 <= x < T and 0 <= y < T):
            continue
        seen.add((x, y))
        r, g, b, a = px[x, y]
        if a < 128:
            continue
        if abs(r - target[0]) + abs(g - target[1]) + abs(b - target[2]) > tol * 3:
            continue
        px[x, y] = (r, g, b, 0)
        q += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
    return tile


def night_grade(tile, kind='ground'):
    """Indigo night grade: crush daylight, lift blues."""
    tile = tile.convert('RGBA')
    r, g, b, a = tile.split()
    import numpy as np
    if kind == 'path':
        mult, lift = (0.38, 0.30, 0.52), (14, 9, 22)
    else:
        mult, lift = (0.20, 0.24, 0.82), (10, 12, 36)
    R = np.asarray(r, dtype=float) * mult[0] + lift[0]
    G = np.asarray(g, dtype=float) * mult[1] + lift[1]
    B = np.asarray(b, dtype=float) * mult[2] + lift[2]
    rgb = Image.merge('RGB', [Image.fromarray(R.clip(0, 255).astype('uint8')),
                              Image.fromarray(G.clip(0, 255).astype('uint8')),
                              Image.fromarray(B.clip(0, 255).astype('uint8'))])
    rgb.putalpha(a)
    return rgb


def fragment_tile(kind):
    """Hand-drawn 16x16 teal crystal cluster in chunky pixel style."""
    img = Image.new('RGBA', (T, T), (0, 0, 0, 0))
    d = img.load()
    OUTL, MID, LITE, HOT = (6, 40, 58, 255), (22, 140, 165, 255), (120, 230, 235, 255), (220, 255, 250, 255)
    def crystal(x0, y0, wdt, hgt):
        for y in range(hgt):
            for x in range(wdt):
                edge = x == 0 or y == 0 or x == wdt - 1 or y == hgt - 1
                tip = y < 2
                d[x0 + x, y0 + y] = OUTL if edge else (HOT if tip else (LITE if (x + y) % 3 == 0 else MID))
    if kind == 'large':
        crystal(2, 4, 5, 12); crystal(8, 7, 4, 9); crystal(11, 9, 3, 7)
    elif kind == 'medium':
        crystal(3, 6, 5, 10); crystal(9, 9, 4, 7)
    else:
        crystal(6, 7, 5, 9)
    return img


def glow_sprite(radius, color):
    s = radius * 2
    img = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    px = img.load()
    for y in range(s):
        for x in range(s):
            dist = math.hypot(x - radius, y - radius) / radius
            if dist < 1:
                f = (1 - dist) ** 3
                px[x, y] = (color[0], color[1], color[2], int(70 * f))
    return img


def main():
    sheet = Image.open(SHEET).convert('RGBA')
    ground = night_grade(cell(sheet, GROUND))
    ground_b = night_grade(cell(sheet, 22))
    path = night_grade(cell(sheet, PATH), kind='path')
    tent = night_grade(key_background(cell(sheet, TENT)))
    fire = night_grade(key_background(cell(sheet, FIRE)))
    crate = night_grade(cell(sheet, CRATE))
    trees = [night_grade(cell(sheet, i)) for i in TREES]
    frags = {'large': fragment_tile('large'), 'medium': fragment_tile('medium'),
             'small': fragment_tile('small')}

    rng = random.Random(7)
    level = Image.new('RGBA', (W * T, H * T), (0, 0, 0, 255))
    # ground (slight variation)
    for y in range(H):
        for x in range(W):
            g = ground_b if rng.random() < 0.08 else ground
            level.paste(g, (x * T, y * T))
    # scorch rings under craters
    craters = [(20, 3, 'large', 4), (10, 5, 'medium', 3), (30, 5, 'small', 3)]
    scorch = Image.new('RGBA', level.size, (0, 0, 0, 0))
    spx = scorch.load()
    for cx, cy, _k, rad in craters:
        for y in range(H * T):
            for x in range(W * T):
                dist = math.hypot(x - (cx * T + 8), y - (cy * T + 8)) / (rad * T)
                if dist < 1:
                    f = (1 - dist) * 110
                    r, g, b, a = spx[x, y]
                    spx[x, y] = (0, 0, 0, min(255, int(a + f)))
    level = Image.alpha_composite(level, scorch)
    # path polyline
    def line(a, b):
        pts = []
        x0, y0, x1, y1 = a[0], a[1], b[0], b[1]
        n = max(abs(x1 - x0), abs(y1 - y0))
        for i in range(n + 1):
            t = i / max(n, 1)
            pts.append((round(x0 + (x1 - x0) * t), round(y0 + (y1 - y0) * t)))
        return pts
    waypoints = [(20, 22), (20, 18), (19, 17), (19, 13), (19, 9), (19, 6),
                 (15, 5), (10, 5)]
    path_cells = set()
    for a, b in zip(waypoints, waypoints[1:]):
        path_cells.update(line(a, b))
    for a, b in [((19, 6), (24, 5)), ((24, 5), (30, 5)), ((19, 6), (20, 4)), ((20, 4), (20, 3))]:
        path_cells.update(line(a, b))
    # widen path slightly
    widened = set(path_cells)
    for x, y in path_cells:
        if rng.random() < 0.35:
            widened.add((x + rng.choice([-1, 1]), y))
    for x, y in widened:
        if 0 <= x < W and 0 <= y < H:
            level.paste(path, (x * T, y * T))
    occupied = set(widened) | {(x, y) for x, y, _k, _r in craters}
    # border trees
    for y in range(H):
        for x in range(W):
            edge = x < 2 or x > W - 3 or y < 1
            if edge and not (y == H - 1 and 18 <= x <= 21):
                t = rng.choice(trees)
                level.paste(t, (x * T, y * T), t)
                occupied.add((x, y))
    # interior scatter trees (avoid features)
    for _ in range(26):
        x, y = rng.randrange(2, W - 2), rng.randrange(2, H - 2)
        if (x, y) in occupied:
            continue
        if any(abs(x - cx) + abs(y - cy) < 5 for cx, cy, _k, _r in craters):
            continue
        if 13 <= x <= 25 and 9 <= y <= 15:
            continue
        t = rng.choice(trees)
        level.paste(t, (x * T, y * T), t)
        occupied.add((x, y))
    # camp halcyon
    level.paste(tent, (16 * T, 11 * T), tent)
    level.paste(tent, (22 * T, 11 * T), tent)
    level.paste(fire, (19 * T, 13 * T), fire)
    level.paste(crate, (15 * T, 13 * T), crate)
    level.paste(crate, (24 * T, 13 * T), crate)
    # glows (additive, under the fragments): amber camp, teal fragments
    glow_layer = Image.new('RGBA', level.size, (0, 0, 0, 0))
    glow_layer.alpha_composite(glow_sprite(24, (255, 170, 70)),
                               (19 * T + 8 - 24, 13 * T + 8 - 24))
    glow_layer.alpha_composite(glow_sprite(18, (255, 170, 70)),
                               (16 * T + 8 - 18, 11 * T + 8 - 18))
    for cx, cy, kind, _r in craters:
        rad = {'large': 26, 'medium': 22, 'small': 18}[kind]
        g = glow_sprite(rad, (70, 235, 230))
        glow_layer.alpha_composite(g, (cx * T + 8 - rad, cy * T + 8 - rad))
    from PIL import ImageChops
    level = ImageChops.add(level.convert('RGB'), glow_layer.convert('RGB'))
    # fragments on top so the crystals pop through their own glow
    for cx, cy, kind, _r in craters:
        f = frags[kind]
        if kind == 'large':
            f = f.resize((32, 32), Image.NEAREST)
            level.paste(f, (cx * T + 8 - 16, cy * T - 20), f)
        else:
            level.paste(f, (cx * T, cy * T - 4), f)

    level = level.resize((W * T * 2, H * T * 2), Image.NEAREST)
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    level.save(OUT)
    print('wrote', OUT, level.size)


if __name__ == '__main__':
    main()

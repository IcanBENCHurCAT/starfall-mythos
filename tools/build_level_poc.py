#!/usr/bin/env python3
"""POC v2: Level 1 'Crash Field Approach' tilemap for STARFALL MYTHOS.

Fixes the v1 mapping bug: every sprite larger than one tile is now assembled
from ALL of its cells per assets/third-party/superpowers-medieval-fantasy/
tile-metadata.json (verified by visual inspection with index overlays).
v1 placed single cells of multi-tile sprites (92/112/196 as lone "trees",
156 as a "campfire" when it is a rock, 86 as a "tent" when it is a shack).

Background keying: the pack uses THREE bg colors depending on the tile
(white / maroon / light-blue), so keying floods from the tile edges through
any bg-colored pixel instead of assuming one key color.

Custom pixels (same chunky 16x16 style, drawn here not generated):
  - dirt path tiles (no dirt tile exists in the sheet; 29 is a solid block)
  - the three signal-fragment crystal tiles (teal glow crystals)

Run: python3 tools/build_level_poc.py
Out: concept/level1-poc-v2.png (2x, 1280x736)
"""
import json, math, os, random
from collections import deque
from PIL import Image

T = 16
W, H = 40, 23
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
META = os.path.join(ROOT, 'assets/third-party/superpowers-medieval-fantasy',
                    'tile-metadata.json')
OUT = os.path.join(ROOT, 'concept/level1-poc-v2.png')

with open(META) as f:
    META_DATA = json.load(f)
SHEET = os.path.join(ROOT, META_DATA['sheet'])
BG = [tuple(c) for c in META_DATA['bg_key_colors']]
COLS = META_DATA['grid_cols']


def cell(sheet, idx):
    c, r = idx % COLS, idx // COLS
    return sheet.crop((c * T, r * T, c * T + T, r * T + T))


def key_background(tile, tol=36):
    """Flood-fill transparent from the edges through ANY bg-colored pixel.

    The pack mixes white, maroon and light-blue backgrounds per tile, so a
    single key color fails. Flooding (instead of flat color-keying) keeps
    interior detail pixels (flame highlights, eyes) that happen to be
    near-white, because they are enclosed by non-bg pixels.
    """
    tile = tile.convert('RGBA')
    px = tile.load()

    def is_bg(r, g, b):
        return any(abs(r - br) + abs(g - bg) + abs(b - bb) <= tol * 3
                   for br, bg, bb in BG)

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
        if a < 128 or not is_bg(r, g, b):
            continue
        px[x, y] = (r, g, b, 0)
        q += [(x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)]
    return tile


def night_grade(tile, kind='ground'):
    """Indigo night grade: crush daylight, lift blues.

    kinds: ground (darkest, for terrain), sprite (readable cool grade for
    vegetation/props), warm (camp structures keep their amber/orange read),
    path (dirt).
    """
    tile = tile.convert('RGBA')
    r, g, b, a = tile.split()
    import numpy as np
    grades = {
        'ground': ((0.20, 0.24, 0.82), (10, 12, 36)),
        'sprite': ((0.42, 0.48, 0.90), (16, 18, 42)),
        'warm':   ((0.55, 0.42, 0.50), (24, 16, 24)),
        'path':   ((0.42, 0.30, 0.32), (18, 11, 12)),
    }
    mult, lift = grades[kind]
    R = np.asarray(r, dtype=float) * mult[0] + lift[0]
    G = np.asarray(g, dtype=float) * mult[1] + lift[1]
    B = np.asarray(b, dtype=float) * mult[2] + lift[2]
    rgb = Image.merge('RGB', [Image.fromarray(R.clip(0, 255).astype('uint8')),
                              Image.fromarray(G.clip(0, 255).astype('uint8')),
                              Image.fromarray(B.clip(0, 255).astype('uint8'))])
    rgb.putalpha(a)
    return rgb


# per-object night grade: camp structures stay warm, vegetation stays readable
WARM_OBJECTS = {'tent_orange', 'shack', 'campfire', 'crate', 'woodbox',
                'chest', 'barrel'}


def build_object(sheet, name):
    """Assemble a multi-tile object from every cell in its metadata layout."""
    spec = META_DATA['objects'][name]
    rows = spec['tiles']
    h, w = len(rows), len(rows[0])
    spr = Image.new('RGBA', (w * T, h * T), (0, 0, 0, 0))
    for ry, row in enumerate(rows):
        for cx, idx in enumerate(row):
            t = cell(sheet, idx)
            if not spec.get('full_bleed'):
                t = key_background(t)
            spr.alpha_composite(t.convert('RGBA'), (cx * T, ry * T))
    kind = 'warm' if name in WARM_OBJECTS else 'sprite'
    return night_grade(spr, kind=kind), w, h


def dirt_tile(base, seed):
    """Hand-drawn dirt: warm-shifted grass hues + speckle, same chunky style."""
    rng = random.Random(seed)
    img = base.convert('RGBA')
    px = img.load()
    for y in range(T):
        for x in range(T):
            r, g, b, a = px[x, y]
            r2 = min(255, int(r * 1.30))
            g2 = int(g * 0.92)
            b2 = int(b * 0.52)
            n = rng.random()
            if n < 0.20:
                f = 0.70 + rng.random() * 0.15
                r2, g2, b2 = int(r2 * f), int(g2 * f), int(b2 * f)
            elif n < 0.28:
                f = 1.14
                r2, g2, b2 = min(255, int(r2 * f)), min(255, int(g2 * f)), min(255, int(b2 * f))
            px[x, y] = (r2, g2, b2, a)
    return night_grade(img, kind='path')


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


def glow_sprite(radius, color, alpha=70):
    s = radius * 2
    img = Image.new('RGBA', (s, s), (0, 0, 0, 0))
    px = img.load()
    for y in range(s):
        for x in range(s):
            dist = math.hypot(x - radius, y - radius) / radius
            if dist < 1:
                f = (1 - dist) ** 3
                px[x, y] = (color[0], color[1], color[2], int(alpha * f))
    return img


def main():
    sheet = Image.open(SHEET).convert('RGBA')
    ground = night_grade(cell(sheet, META_DATA['ground_singles']['grass']))
    ground_b = night_grade(cell(sheet, META_DATA['ground_singles']['grass_alt']))
    dirt = [dirt_tile(cell(sheet, META_DATA['ground_singles']['grass']), s)
            for s in (99, 100)]

    sprites = {}
    for name in META_DATA['objects']:
        sprites[name] = build_object(sheet, name)

    frags = {'large': fragment_tile('large'), 'medium': fragment_tile('medium'),
             'small': fragment_tile('small')}

    rng = random.Random(7)
    level = Image.new('RGBA', (W * T, H * T), (0, 0, 0, 255))
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

    # path polyline (same route as v1)
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
    widened = set(path_cells)
    for x, y in path_cells:
        if rng.random() < 0.35:
            widened.add((x + rng.choice([-1, 1]), y))
    for x, y in widened:
        if 0 <= x < W and 0 <= y < H:
            level.paste(rng.choice(dirt), (x * T, y * T))
    occupied = set(widened) | {(x, y) for x, y, _k, _r in craters}

    def place(name, gx, gy):
        spr, w, h = sprites[name]
        if gx < 0 or gy < 0 or gx + w > W or gy + h > H:
            return False
        for dy in range(h):
            for dx in range(w):
                if (gx + dx, gy + dy) in occupied:
                    return False
        level.paste(spr, (gx * T, gy * T), spr)
        for dy in range(h):
            for dx in range(w):
                occupied.add((gx + dx, gy + dy))
        return True

    # border forest: 2-wide trees step along the edges, entrance gap at bottom
    border_trees = ['round_tree', 'pine_tree', 'big_tree', 'round_tree',
                    'pine_tree', 'dead_tree']
    for y in range(0, H - 1, 2):
        for gx in (0, W - 2):
            name = rng.choice(border_trees)
            _w = META_DATA['objects'][name]['size'][0]
            place(name, gx if _w == 2 else (0 if gx == 0 else W - 3), y)
    for x in range(0, W - 1, 2):
        place(rng.choice(border_trees), x, 0)
        if not any(18 <= x + dx <= 21 for dx in range(3)):
            place(rng.choice(border_trees), x, H - 2)
    # interior scatter
    scatter = (['round_tree'] * 6 + ['pine_tree'] * 6 + ['big_tree'] * 4 +
               ['dead_tree'] * 2 + ['bush'] * 6 + ['rock'] * 3)
    for _ in range(30):
        name = rng.choice(scatter)
        w, h = META_DATA['objects'][name]['size']
        x, y = rng.randrange(2, W - 2 - w), rng.randrange(2, H - 2 - h)
        if any(abs(x - cx) + abs(y - cy) < 5 for cx, cy, _k, _r in craters):
            continue
        if 13 <= x <= 26 and 8 <= y <= 16:
            continue
        place(name, x, y)

    # Camp Halcyon: real 1x3 tents, real campfire, crates + barrel
    place('tent_orange', 16, 10)
    place('tent_orange', 22, 10)
    place('campfire', 19, 13)
    place('crate', 15, 13)
    place('woodbox', 24, 13)
    place('barrel', 25, 12)

    # glows (additive, under the fragments): amber camp, teal fragments.
    # The campfire glow is small and dim so it never washes out the fire;
    # the fire sprite is re-pasted on top after the glow pass.
    glow_layer = Image.new('RGBA', level.size, (0, 0, 0, 0))
    glow_layer.alpha_composite(glow_sprite(16, (255, 170, 70), alpha=45),
                               (19 * T + 8 - 16, 13 * T + 8 - 16))
    glow_layer.alpha_composite(glow_sprite(14, (255, 170, 70), alpha=40),
                               (16 * T + 8 - 14, 10 * T + 8 - 14))
    for cx, cy, kind, _r in craters:
        rad = {'large': 26, 'medium': 22, 'small': 18}[kind]
        g = glow_sprite(rad, (70, 235, 230))
        glow_layer.alpha_composite(g, (cx * T + 8 - rad, cy * T + 8 - rad))
    from PIL import ImageChops
    level = ImageChops.add(level.convert('RGB'), glow_layer.convert('RGB'))
    # campfire back on top of its own glow
    fire_spr, _fw, _fh = sprites['campfire']
    level.paste(fire_spr, (19 * T, 13 * T), fire_spr)
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

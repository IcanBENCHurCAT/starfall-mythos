#!/usr/bin/env python3
"""Generate placeholder SNES-style assets so the project runs out of the box.

Replace these with real CC0 art (see ../ASSET_SOURCES.md). The generator
documents the exact sheet layout the engine code expects:

player.png : 64x128, cells 32x32
    row 0 = down, row 1 = left, row 2 = right, row 3 = up
    col 0 = idle frame, col 1 = walk frame
ground.png : 32x16, two 16x16 tiles (grass, grass-dark)
"""
import random
from pathlib import Path
from PIL import Image, ImageDraw

HERE = Path(__file__).resolve().parent
SPRITES = HERE / "../assets/sprites"
TILES = HERE / "../assets/tiles"

# SNES-ish constrained palette
SKIN = (255, 203, 164)
HAIR = (120, 72, 40)
SHIRT = (64, 120, 200)
SHIRT_D = (48, 92, 160)
PANTS = (60, 50, 90)
BOOTS = (40, 30, 25)
EYE = (20, 20, 30)
GRASS = (74, 140, 70)
GRASS_D = (64, 124, 62)
GRASS_SPECK = (90, 158, 84)


def draw_humanoid(d: ImageDraw.Draw, ox: int, oy: int, facing: str, walk: bool):
    """Draw a simple 32x32 humanoid. ox/oy = top-left of cell."""
    # shadow
    d.ellipse([ox + 10, oy + 26, ox + 22, oy + 29], fill=(0, 0, 0, 90))
    leg_spread = 4 if walk else 2
    # legs
    d.rectangle([ox + 12 - leg_spread, oy + 21, ox + 14 - leg_spread, oy + 27], fill=PANTS)
    d.rectangle([ox + 18 + leg_spread, oy + 21, ox + 20 + leg_spread, oy + 27], fill=PANTS)
    # boots
    d.rectangle([ox + 11 - leg_spread, oy + 26, ox + 14 - leg_spread, oy + 29], fill=BOOTS)
    d.rectangle([ox + 18 + leg_spread, oy + 26, ox + 21 + leg_spread, oy + 29], fill=BOOTS)
    # torso
    d.rectangle([ox + 11, oy + 13, ox + 21, oy + 22], fill=SHIRT)
    d.rectangle([ox + 11, oy + 19, ox + 21, oy + 22], fill=SHIRT_D)
    # arms
    arm_out = 3 if walk and facing in ("left", "right") else 1
    d.rectangle([ox + 8 - arm_out, oy + 14, ox + 10 - arm_out, oy + 21], fill=SHIRT_D)
    d.rectangle([ox + 22 + arm_out, oy + 14, ox + 24 + arm_out, oy + 21], fill=SHIRT_D)
    # head
    d.rectangle([ox + 11, oy + 4, ox + 21, oy + 13], fill=SKIN)
    # hair cap
    d.rectangle([ox + 10, oy + 2, ox + 22, oy + 6], fill=HAIR)
    if facing in ("down", "left", "right"):
        d.rectangle([ox + 10, oy + 2, ox + 22, oy + 4], fill=HAIR)
    # face direction cues
    if facing == "down":
        d.rectangle([ox + 13, oy + 9, ox + 15, oy + 11], fill=EYE)
        d.rectangle([ox + 18, oy + 9, ox + 20, oy + 11], fill=EYE)
    elif facing == "left":
        d.rectangle([ox + 11, oy + 9, ox + 14, oy + 11], fill=EYE)
    elif facing == "right":
        d.rectangle([ox + 19, oy + 9, ox + 22, oy + 11], fill=EYE)
    # up: back of head, no face


def make_player() -> Image.Image:
    img = Image.new("RGBA", (64, 128), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for row, facing in enumerate(["down", "left", "right", "up"]):
        for col, walk in enumerate([False, True]):
            draw_humanoid(d, col * 32, row * 32, facing, walk)
    return img


def make_ground() -> Image.Image:
    rng = random.Random(7)
    img = Image.new("RGBA", (32, 16), (0, 0, 0, 0))
    d = ImageDraw.Draw(img)
    for i, base in enumerate([GRASS, GRASS_D]):
        ox = i * 16
        d.rectangle([ox, 0, ox + 15, 15], fill=base)
        for _ in range(14):
            x, y = ox + rng.randrange(16), rng.randrange(16)
            d.rectangle([x, y, x + 1, y + 1], fill=GRASS_SPECK)
    return img


def main() -> None:
    SPRITES.mkdir(parents=True, exist_ok=True)
    TILES.mkdir(parents=True, exist_ok=True)
    make_player().save(SPRITES / "player.png")
    make_ground().save(TILES / "ground.png")
    print("wrote", SPRITES / "player.png", "and", TILES / "ground.png")


if __name__ == "__main__":
    main()

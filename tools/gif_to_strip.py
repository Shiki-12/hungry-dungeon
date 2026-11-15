#!/usr/bin/env python3
"""Convert GIF to horizontal PNG strip. Requires Pillow."""
from pathlib import Path
import sys
from PIL import Image

def main() -> int:
    if len(sys.argv) < 3:
        print("usage: gif_to_strip.py input.gif output.png")
        return 2
    src, dst = Path(sys.argv[1]), Path(sys.argv[2])
    with Image.open(src) as gif:
        frames = []
        for i in range(getattr(gif, "n_frames", 1)):
            gif.seek(i)
            frames.append(gif.convert("RGBA"))
        out = Image.new("RGBA", (sum(x.width for x in frames), max(x.height for x in frames)))
        x = 0
        for frame in frames:
            out.alpha_composite(frame, (x, 0)); x += frame.width
        out.save(dst)
    return 0
if __name__ == "__main__":
    raise SystemExit(main())

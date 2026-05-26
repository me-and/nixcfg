#!/usr/bin/env python3
import sys

RESET = "\x1b[0m"

def gradient_rgb(t):
    """
    Map t in [0.0, 1.0] to an RGB tuple along green → yellow → red.
    Green = (0, 200, 0), Yellow = (255, 200, 0), Red = (220, 0, 0).
    Using a muted green/red rather than pure to avoid harshness.
    """
    if t <= 0.5:
        # Green to yellow: ramp red up from 0 to 255
        s = t * 2
        return (round(s * 255), 200, 0)
    else:
        # Yellow to red: ramp green down from 200 to 0
        s = (t - 0.5) * 2
        return (255, round((1 - s) * 200), 0)


def colour_for(value, lo, hi):
    if hi == lo:
        return ""
    t = max(0.0, min(1.0, (value - lo) / (hi - lo)))
    r, g, b = gradient_rgb(t)
    return f"\x1b[38;2;{r};{g};{b}m"

lo = hi = None
total = 0
sizes = []

for line in sys.stdin:
    size_str, path = line.split('\t')
    size = int(size_str.strip())
    path = path.strip()
    if lo is None and hi is None:
        lo = hi = size
    else:
        lo = min(lo, size)
        hi = max(hi, size)
    total += size
    sizes.append((size, path))


for size, path in sizes:
    # Leading tab separates colour code from size, so `numfmt` doesn't get
    # confused by the non-digit characters.  It'll be stripped after the
    # `numfmt` stage.
    print(f'{colour_for(size, lo, hi)}\t{size}\t{path}{RESET}')

# Leading tab so we can just strip the first tab from every line regardless of
# whether it has any colour codes.
print(f'\t{total}\ttotal')

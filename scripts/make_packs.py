#!/usr/bin/env python3
"""Build the exact itsclear™ packaging assets from the user's reference screenshot.

Source: docs/reference-packaging.png (the real itsclear.in hero screenshot).
Output: six transparent PNG pack shots in public/images/, all derived from the
same black/cream Khapli Atta pouch. No AI imagery and no invented packaging.

Requires ImageMagick's `convert` binary.
"""
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parent.parent
REF = ROOT / "docs" / "reference-packaging.png"
OUT = ROOT / "public" / "images"
OUT.mkdir(parents=True, exist_ok=True)

if not REF.exists():
    raise SystemExit(f"Missing reference screenshot: {REF}")


def im(args):
    subprocess.run(["convert", *args], check=True)


with tempfile.TemporaryDirectory() as td:
    tmp = Path(td)
    crop = tmp / "crop.png"
    mask = tmp / "mask.png"
    isolated = tmp / "isolated.png"
    base = tmp / "base.png"

    # Crop the 360° viewer from the 1920×1080 screenshot.
    im([str(REF), "-crop", "760x820+990+180", "+repage", str(crop)])

    # Hand-traced pouch silhouette. The handle is punched out as transparent.
    im([
        "-size", "760x820", "xc:black",
        "-fill", "white",
        "-draw", "polygon 175,103 566,103 568,312 590,700 580,715 500,725 350,730 200,725 145,715 140,312",
        "-fill", "black",
        "-draw", "roundrectangle 300,145 425,185 20,20",
        "-blur", "0x0.6",
        str(mask),
    ])
    im([str(crop), "-alpha", "on", str(mask), "-alpha", "off",
        "-compose", "CopyOpacity", "-composite", str(isolated)])
    im([str(isolated), "-trim", "+repage", "-bordercolor", "none",
        "-border", "18", "-strip", str(base)])

    # 1 — the exact front pack.
    im([str(base), str(OUT / "pack-khapli.png")])

    # 2 — same pack with a small 36g protein UI seal (outside the pouch print).
    im([
        str(base),
        "-fill", "#b9603e", "-draw", "circle 420,570 420,532",
        "-fill", "white", "-font", "DejaVu-Sans-Bold", "-pointsize", "20",
        "-annotate", "+398+577", "36g",
        str(OUT / "pack-protein.png"),
    ])

    # 3 — 1kg / 5kg / 10kg family lineup, all using the exact same pouch.
    im([
        "-size", "820x720", "xc:none",
        "(", str(base), "-resize", "58%", ")", "-gravity", "south", "-geometry", "-230+0", "-composite",
        "(", str(base), "-resize", "78%", ")", "-gravity", "south", "-geometry", "+0+0", "-composite",
        "(", str(base), "-resize", "98%", ")", "-gravity", "south", "-geometry", "+230+0", "-composite",
        "-trim", "+repage", "-bordercolor", "none", "-border", "18", "-strip",
        str(OUT / "pack-lineup.png"),
    ])

    # 4 — exact pack surrounded by four lab-verification seals.
    im([
        "-size", "660x720", "xc:none",
        "(", str(base), "-resize", "82%", ")", "-gravity", "center", "-composite",
        "-fill", "#c79a3a",
        "-draw", "circle 78,140 78,112 circle 582,140 582,112 circle 78,580 78,552 circle 582,580 582,552",
        "-stroke", "white", "-strokewidth", "4", "-fill", "none",
        "-draw", "polyline 66,140 75,149 91,127",
        "-draw", "polyline 570,140 579,149 595,127",
        "-draw", "polyline 66,580 75,589 91,567",
        "-draw", "polyline 570,580 579,589 595,567",
        "-strip", str(OUT / "pack-badges.png"),
    ])

    # 5 — two-pouch protein duo.
    im([
        "-size", "780x720", "xc:none",
        "(", str(base), "-resize", "82%", ")", "-gravity", "south", "-geometry", "-140+0", "-composite",
        "(", str(base), "-resize", "94%", ")", "-gravity", "south", "-geometry", "+140+0", "-composite",
        "-trim", "+repage", "-bordercolor", "none", "-border", "18", "-strip",
        str(OUT / "pack-duo.png"),
    ])

    # 6 — zoomed carry-handle / wordmark detail from the same pack.
    im([
        str(base), "-resize", "128%", "-gravity", "north",
        "-crop", "491x668+0+0", "+repage", "-strip",
        str(OUT / "pack-handle.png"),
    ])

print("Generated exact itsclear packaging PNGs in public/images/")

# Keep the repository light: 8-bit, maximally compressed PNGs.
subprocess.run([
    "mogrify", "-depth", "8", "-define", "png:compression-level=9",
    *[str(p) for p in sorted(OUT.glob("pack-*.png"))],
], check=True)

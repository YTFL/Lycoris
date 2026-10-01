"""
Universal Android Launcher Icon Generator for Lycoris
Adheres to the Universal Android Launcher Icon Blueprint:
- Android 13+ (API 33+) : Material You / Monochrome Theming
- Android 8.0 - 12 (API 26-32) : Adaptive Icons & Safe Zone (108dp canvas, 66dp safe-zone circle)
- Android 7.1 & below (API <26) : Pre-Cropped Legacy Mipmaps (alpha = 0 outside circle)
- Direct Drawable Resolution: Bitmap/Shape drawables for 3rd-party launchers & widgets
- White & Black Background Support: Master assets and day/night splash configurations
"""

import os
import math
import numpy as np
from PIL import Image
from scipy import ndimage

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SOURCE_ICON_PATH = os.path.join(ROOT_DIR, "assets", "icons", "icon.png")
TRANSPARENT_ICON_PATH = os.path.join(ROOT_DIR, "assets", "icons", "icon_transparent.png")
MONOCHROME_ICON_PATH = os.path.join(ROOT_DIR, "assets", "icons", "icon_monochrome.png")
BLACK_ICON_PATH = os.path.join(ROOT_DIR, "assets", "icons", "icon_black.png")
WHITE_ICON_PATH = os.path.join(ROOT_DIR, "assets", "icons", "icon_white.png")
RES_DIR = os.path.join(ROOT_DIR, "android", "app", "src", "main", "res")

BG_COLOR_HEX = "#121212"
BG_COLOR_RGB = (18, 18, 18)
WHITE_COLOR_RGB = (255, 255, 255)

# Density mappings
# Adaptive Canvas: 108dp x 108dp
ADAPTIVE_SIZES = {
    "drawable-mdpi": 108,
    "drawable-hdpi": 162,
    "drawable-xhdpi": 216,
    "drawable-xxhdpi": 324,
    "drawable-xxxhdpi": 432,
}

# Legacy Mipmaps: 48dp x 48dp
LEGACY_SIZES = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

# Splash Launch Images
SPLASH_SIZES = {
    "drawable-mdpi": 96,
    "drawable-hdpi": 144,
    "drawable-xhdpi": 192,
    "drawable-xxhdpi": 288,
    "drawable-xxxhdpi": 384,
}


def extract_master_transparent_icon(src_path: str) -> Image.Image:
    """Extracts transparent emblem from source icon with anti-aliasing and zero edge-bleed."""
    print(f"Extracting transparent emblem from {src_path}...")
    img = Image.open(src_path).convert("RGBA")
    arr = np.array(img, dtype=float)

    # Redness signal: R channel minus maximum of G and B
    redness = np.clip(arr[:, :, 0] - np.maximum(arr[:, :, 1], arr[:, :, 2]), 0, None)

    # Morphological mask: identify largest connected component of high redness
    binary = redness > 15.0
    labeled, num_features = ndimage.label(binary)
    if num_features > 0:
        sizes = ndimage.sum(binary, labeled, range(num_features + 1))
        largest_label = np.argmax(sizes[1:]) + 1
        flower_mask = (labeled == largest_label)
        # Dilate mask to encompass anti-aliased edge transitions
        dilated_mask = ndimage.binary_dilation(flower_mask, iterations=6)
    else:
        dilated_mask = np.ones_like(redness, dtype=bool)

    # Alpha ramp based on redness inside dilated mask
    alpha = np.zeros_like(redness)
    alpha[dilated_mask] = np.clip(redness[dilated_mask] / 120.0, 0.0, 1.0)
    alpha[~dilated_mask] = 0.0

    # Flower line color: vibrant coral red [240, 102, 92]
    fg = np.zeros_like(arr)
    true_color = np.array([240.0, 102.0, 92.0])
    fg[dilated_mask, :3] = true_color
    fg[:, :, 3] = alpha * 255.0

    out_img = Image.fromarray(fg.astype(np.uint8), mode="RGBA")

    # Crop tightly to emblem bounding box, then place centered on a 2048x2048 canvas
    bbox = out_img.getbbox()
    if bbox:
        cropped = out_img.crop(bbox)
        w, h = cropped.size
        dim = max(w, h)
        # Create 2048x2048 master transparent asset
        master = Image.new("RGBA", (2048, 2048), (0, 0, 0, 0))
        # Keep aspect ratio, scale to occupy ~75% of 2048 (1536px)
        scale = 1536.0 / dim
        new_w, new_h = int(round(w * scale)), int(round(h * scale))
        resized = cropped.resize((new_w, new_h), Image.Resampling.LANCZOS)
        offset_x = (2048 - new_w) // 2
        offset_y = (2048 - new_h) // 2
        master.paste(resized, (offset_x, offset_y), resized)
        return master
    return out_img


def create_monochrome_master_icon(transparent_img: Image.Image) -> Image.Image:
    """Creates a Material You compatible monochrome master icon with tonal detail."""
    print("Creating monochrome master icon...")
    arr = np.array(transparent_img, dtype=float)
    alpha = arr[:, :, 3] / 255.0

    # Output pure white RGB with modulated alpha
    mono = np.zeros_like(arr)
    mono[:, :, 0] = 255  # White R
    mono[:, :, 1] = 255  # White G
    mono[:, :, 2] = 255  # White B

    # Tonal alpha: clean silhouette opacity
    mono[:, :, 3] = np.clip(alpha * 255.0, 0, 255)

    return Image.fromarray(mono.astype(np.uint8), mode="RGBA")


def create_master_solid_icon(transparent_img: Image.Image, bg_rgb: tuple) -> Image.Image:
    """Creates a 2048x2048 master icon composited onto a solid background color."""
    canvas = Image.new("RGBA", transparent_img.size, bg_rgb + (255,))
    canvas.paste(transparent_img, (0, 0), transparent_img)
    return canvas


def generate_adaptive_icon(emblem_img: Image.Image, canvas_size: int) -> Image.Image:
    """Generates an adaptive icon layer on a canvas_size x canvas_size transparent canvas.
    Scales emblem radially so every pixel and corner fits strictly inside the 66dp safe-zone circle.
    """
    canvas = Image.new("RGBA", (canvas_size, canvas_size), (0, 0, 0, 0))
    bbox = emblem_img.getbbox()
    if not bbox:
        return canvas

    cropped = emblem_img.crop(bbox)
    w, h = cropped.size

    # Compute radial distance of non-transparent emblem pixels from emblem center
    arr = np.array(cropped)
    mask = arr[:, :, 3] > 10
    if not np.any(mask):
        return canvas

    cy, cx = (h - 1.0) / 2.0, (w - 1.0) / 2.0
    y, x = np.ogrid[:h, :w]
    radial_dist = np.sqrt((x - cx) ** 2 + (y - cy) ** 2)
    max_radial_dist = radial_dist[mask].max()

    # Safe zone: circle of diameter 66dp on 108dp canvas
    safe_radius = (66.0 / 108.0) * (canvas_size / 2.0)
    # Fit comfortably inside safe zone with slight safety buffer (96% of safe radius)
    scale = (safe_radius * 0.96) / max_radial_dist
    new_w = max(1, int(round(w * scale)))
    new_h = max(1, int(round(h * scale)))

    resized = cropped.resize((new_w, new_h), Image.Resampling.LANCZOS)
    pos_x = (canvas_size - new_w) // 2
    pos_y = (canvas_size - new_h) // 2
    canvas.paste(resized, (pos_x, pos_y), resized)
    return canvas


def generate_legacy_square_icon(emblem_img: Image.Image, size: int, bg_rgb: tuple) -> Image.Image:
    """Generates a legacy square/squircle icon with specified background."""
    bg = Image.new("RGBA", (size, size), bg_rgb + (255,))
    bbox = emblem_img.getbbox()
    if not bbox:
        return bg

    cropped = emblem_img.crop(bbox)
    w, h = cropped.size
    target_dim = int(round(size * 0.68))
    scale = target_dim / max(w, h)
    new_w = max(1, int(round(w * scale)))
    new_h = max(1, int(round(h * scale)))

    resized = cropped.resize((new_w, new_h), Image.Resampling.LANCZOS)
    pos_x = (size - new_w) // 2
    pos_y = (size - new_h) // 2
    bg.paste(resized, (pos_x, pos_y), resized)
    return bg


def generate_legacy_round_icon(emblem_img: Image.Image, size: int, bg_rgb: tuple) -> Image.Image:
    """Generates a pre-cropped circular legacy icon with alpha = 0 outside circle radius."""
    # Render at 4x supersampling for ultra-crisp anti-aliased edge
    hi_size = size * 4
    canvas = Image.new("RGBA", (hi_size, hi_size), (0, 0, 0, 0))

    # Create high-res circular background plate
    center = hi_size / 2.0
    radius = (hi_size - 1.0) / 2.0
    y, x = np.ogrid[:hi_size, :hi_size]
    dist_from_center = np.sqrt((x - center + 0.5) ** 2 + (y - center + 0.5) ** 2)

    # Anti-aliased circle edge
    circle_alpha = np.clip((radius - dist_from_center) + 0.5, 0.0, 1.0)

    plate_arr = np.zeros((hi_size, hi_size, 4), dtype=np.uint8)
    plate_arr[:, :, 0] = bg_rgb[0]
    plate_arr[:, :, 1] = bg_rgb[1]
    plate_arr[:, :, 2] = bg_rgb[2]
    plate_arr[:, :, 3] = (circle_alpha * 255.0).astype(np.uint8)
    plate_img = Image.fromarray(plate_arr, mode="RGBA")

    # Scale and paste emblem inside circle
    bbox = emblem_img.getbbox()
    if bbox:
        cropped = emblem_img.crop(bbox)
        w, h = cropped.size
        target_dim = int(round(hi_size * 0.64))
        scale = target_dim / max(w, h)
        new_w = max(1, int(round(w * scale)))
        new_h = max(1, int(round(h * scale)))
        resized = cropped.resize((new_w, new_h), Image.Resampling.LANCZOS)
        pos_x = (hi_size - new_w) // 2
        pos_y = (hi_size - new_h) // 2
        plate_img.paste(resized, (pos_x, pos_y), resized)

    # Downsample to target size with Lanczos
    result = plate_img.resize((size, size), Image.Resampling.LANCZOS)

    # Strictly enforce alpha = 0 outside circle to eliminate "square-inside-circle" bug
    res_arr = np.array(result)
    r_center = (size - 1.0) / 2.0
    r_radius = size / 2.0
    ry, rx = np.ogrid[:size, :size]
    rdist = np.sqrt((rx - r_center) ** 2 + (ry - r_center) ** 2)
    # Outside radius: strictly alpha = 0
    res_arr[rdist >= (r_radius + 0.2), 3] = 0

    return Image.fromarray(res_arr, mode="RGBA")


def generate_splash_image(emblem_img: Image.Image, size: int) -> Image.Image:
    """Generates splash launch_image.png with centered transparent emblem."""
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    bbox = emblem_img.getbbox()
    if not bbox:
        return canvas

    cropped = emblem_img.crop(bbox)
    w, h = cropped.size
    target_dim = int(round(size * 0.82))
    scale = target_dim / max(w, h)
    new_w = max(1, int(round(w * scale)))
    new_h = max(1, int(round(h * scale)))

    resized = cropped.resize((new_w, new_h), Image.Resampling.LANCZOS)
    pos_x = (size - new_w) // 2
    pos_y = (size - new_h) // 2
    canvas.paste(resized, (pos_x, pos_y), resized)
    return canvas


def main():
    print("=== Generating Universal Android Launcher Icons for Lycoris ===")

    # 1. Extract Master Transparent Icon
    transparent_master = extract_master_transparent_icon(SOURCE_ICON_PATH)
    os.makedirs(os.path.dirname(TRANSPARENT_ICON_PATH), exist_ok=True)
    transparent_master.save(TRANSPARENT_ICON_PATH, "PNG")
    print(f"[OK] Saved master transparent icon: {TRANSPARENT_ICON_PATH}")

    # 2. Extract Master Monochrome Icon
    monochrome_master = create_monochrome_master_icon(transparent_master)
    monochrome_master.save(MONOCHROME_ICON_PATH, "PNG")
    print(f"[OK] Saved master monochrome icon: {MONOCHROME_ICON_PATH}")

    # 3. Generate Master Black & White Background Icons
    black_master = create_master_solid_icon(transparent_master, BG_COLOR_RGB)
    black_master.save(BLACK_ICON_PATH, "PNG")
    print(f"[OK] Saved master black background icon: {BLACK_ICON_PATH}")

    white_master = create_master_solid_icon(transparent_master, WHITE_COLOR_RGB)
    white_master.save(WHITE_ICON_PATH, "PNG")
    print(f"[OK] Saved master white background icon: {WHITE_ICON_PATH}")

    # 4. Generate Adaptive Foreground & Monochrome Drawables
    for density, size in ADAPTIVE_SIZES.items():
        density_dir = os.path.join(RES_DIR, density)
        os.makedirs(density_dir, exist_ok=True)

        # Foreground
        fg_icon = generate_adaptive_icon(transparent_master, size)
        fg_path = os.path.join(density_dir, "ic_launcher_foreground.png")
        fg_icon.save(fg_path, "PNG")

        # Monochrome
        mono_icon = generate_adaptive_icon(monochrome_master, size)
        mono_path = os.path.join(density_dir, "ic_launcher_monochrome.png")
        mono_icon.save(mono_path, "PNG")

        print(f"[OK] {density} ({size}x{size}): ic_launcher_foreground.png, ic_launcher_monochrome.png")

    # 5. Generate Legacy Mipmaps (Square & Pre-Cropped Round)
    for density, size in LEGACY_SIZES.items():
        density_dir = os.path.join(RES_DIR, density)
        os.makedirs(density_dir, exist_ok=True)

        # Legacy Square
        sq_icon = generate_legacy_square_icon(transparent_master, size, BG_COLOR_RGB)
        sq_path = os.path.join(density_dir, "ic_launcher.png")
        sq_icon.save(sq_path, "PNG")

        # Legacy Round
        rd_icon = generate_legacy_round_icon(transparent_master, size, BG_COLOR_RGB)
        rd_path = os.path.join(density_dir, "ic_launcher_round.png")
        rd_icon.save(rd_path, "PNG")

        print(f"[OK] {density} ({size}x{size}): ic_launcher.png, ic_launcher_round.png")

    # 6. Generate Splash Screen Launch Images
    for density, size in SPLASH_SIZES.items():
        density_dir = os.path.join(RES_DIR, density)
        os.makedirs(density_dir, exist_ok=True)

        splash_img = generate_splash_image(transparent_master, size)
        splash_path = os.path.join(density_dir, "launch_image.png")
        splash_img.save(splash_path, "PNG")
        print(f"[OK] {density} ({size}x{size}): launch_image.png")

    print("=== All Bitmap Assets Successfully Generated ===")


if __name__ == "__main__":
    main()

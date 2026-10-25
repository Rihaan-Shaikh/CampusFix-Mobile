from PIL import Image, ImageDraw
import os

src_path = r"C:\Users\shaik\.gemini\antigravity-ide\brain\16dbbf49-a1c2-4a5e-b1b5-12094cddd0d9\.user_uploaded\media_1792174657490.png"
out_dir = r"C:\Users\shaik\Desktop\CampusFix-Mobile"
src = Image.open(src_path).convert("RGBA")

# 1. Exact crop box of the dark card
crop_box = (11, 9, 191, 189) # 180x180
cropped = src.crop(crop_box)

# 2. Apply smooth rounded corner mask to eliminate the outer white/drop shadow pixels
# Use 4x supersampling for high-quality antialiasing
mask_size = (180 * 4, 180 * 4)
mask = Image.new("L", mask_size, 0)
draw = ImageDraw.Draw(mask)
# corner radius = 32 * 4 = 128
draw.rounded_rectangle([(0, 0), (mask_size[0], mask_size[1])], radius=128, fill=255)
mask = mask.resize((180, 180), Image.Resampling.LANCZOS)

# Apply mask to cropped image
clean_tile = cropped.copy()
clean_tile.putalpha(mask)

# High-res clean tile for app asset:
assets_dir = os.path.join(out_dir, "assets", "images")
os.makedirs(assets_dir, exist_ok=True)
clean_tile_path = os.path.join(assets_dir, "campusfix_logo.png")
clean_tile.save(clean_tile_path, "PNG")
print("Saved clean tile to:", clean_tile_path)

# Android launcher sizes
launcher_sizes = {
    "mipmap-mdpi": 48,
    "mipmap-hdpi": 72,
    "mipmap-xhdpi": 96,
    "mipmap-xxhdpi": 144,
    "mipmap-xxxhdpi": 192,
}

res_dir = os.path.join(out_dir, "android", "app", "src", "main", "res")

# 3. Generate standard ic_launcher.png (legacy icon)
for folder, size in launcher_sizes.items():
    folder_path = os.path.join(res_dir, folder)
    os.makedirs(folder_path, exist_ok=True)
    resized = clean_tile.resize((size, size), Image.Resampling.LANCZOS)
    resized.save(os.path.join(folder_path, "ic_launcher.png"), "PNG")

# 4. Generate adaptive icon foreground (108x108 viewport, safe zone is 72x72 inner 66%)
adaptive_sizes = {
    "mipmap-mdpi": 108,
    "mipmap-hdpi": 162,
    "mipmap-xhdpi": 216,
    "mipmap-xxhdpi": 324,
    "mipmap-xxxhdpi": 432,
}

for folder, total_size in adaptive_sizes.items():
    folder_path = os.path.join(res_dir, folder)
    # The logo should occupy ~68% of the total size to sit comfortably in the safe zone
    icon_size = int(total_size * 0.68)
    resized_icon = clean_tile.resize((icon_size, icon_size), Image.Resampling.LANCZOS)
    
    fg_canvas = Image.new("RGBA", (total_size, total_size), (0, 0, 0, 0))
    offset = ((total_size - icon_size) // 2, (total_size - icon_size) // 2)
    fg_canvas.paste(resized_icon, offset, resized_icon)
    fg_canvas.save(os.path.join(folder_path, "ic_launcher_foreground.png"), "PNG")

# 5. Generate splash_logo.png in drawable directories
drawable_dirs = [
    os.path.join(res_dir, "drawable"),
    os.path.join(res_dir, "drawable-v21")
]
for d in drawable_dirs:
    os.makedirs(d, exist_ok=True)
    splash_logo = clean_tile.resize((140, 140), Image.Resampling.LANCZOS)
    splash_logo.save(os.path.join(d, "splash_logo.png"), "PNG")

print("All Android launcher and splash assets successfully generated.")

from pathlib import Path
from PIL import Image

SOURCE = Path('/home/ubuntu/upload/20260916_231307.png')
RES = Path('/home/ubuntu/amansoon/aman_app/android/app/src/main/res')
SIZES = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}

image = Image.open(SOURCE).convert('RGBA')
if image.width != image.height:
    raise ValueError(f'Icon source must be square, got {image.size}')
for density, size in SIZES.items():
    target = RES / density / 'ic_launcher.png'
    target.parent.mkdir(parents=True, exist_ok=True)
    resized = image.resize((size, size), Image.Resampling.LANCZOS)
    resized.save(target, format='PNG', optimize=True)
print(f'Generated {len(SIZES)} Android launcher icons from {SOURCE}')
for density, size in SIZES.items():
    print(f'{density}: {size}x{size}')

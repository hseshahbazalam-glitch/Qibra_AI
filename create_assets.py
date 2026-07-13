import os
import json

# Minimal 1x1 transparent PNG
png = bytes([
    0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A,
    0x00, 0x00, 0x00, 0x0D, 0x49, 0x48, 0x44, 0x52,
    0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
    0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4,
    0x89, 0x00, 0x00, 0x00, 0x0B, 0x49, 0x44, 0x41,
    0x54, 0x08, 0xD7, 0x63, 0x60, 0x60, 0x60, 0x60,
    0x00, 0x00, 0x00, 0x05, 0x00, 0x01, 0xA5, 0xF6,
    0x45, 0x40, 0x00, 0x00, 0x00, 0x00, 0x49, 0x45,
    0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82
])

# Simple SVG
svg = '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24"><circle cx="12" cy="12" r="10" fill="#00A86B"/></svg>'

# Minimal Lottie JSON
lottie = {
    'v': '5.7.4',
    'fr': 30,
    'ip': 0,
    'op': 60,
    'w': 200,
    'h': 200,
    'nm': 'Placeholder',
    'ddd': 0,
    'assets': [],
    'layers': []
}

# File names
images = [
    'logo', 'logo_white', 'logo_icon',
    'splash_bg', 'splash_logo',
    'onboarding_1', 'onboarding_2', 'onboarding_3', 'onboarding_4',
    'quran_bg', 'quran_cover',
    'mosque', 'compass_bg',
    'islamic_pattern_1', 'islamic_pattern_2', 'pattern_overlay'
]

icons = ['quran', 'prayer', 'qibla', 'hadith', 'ai', 'calendar', 'tasbih', 'dua']

animations = ['loading', 'success', 'error', 'prayer', 'quran', 'ai_thinking']

# Create folders
os.makedirs('assets/images', exist_ok=True)
os.makedirs('assets/icons', exist_ok=True)
os.makedirs('assets/animations', exist_ok=True)

# Create images
for name in images:
    with open(f'assets/images/{name}.png', 'wb') as f:
        f.write(png)
    print(f'Created: assets/images/{name}.png')

# Create icons
for name in icons:
    with open(f'assets/icons/{name}.svg', 'w') as f:
        f.write(svg)
    print(f'Created: assets/icons/{name}.svg')

# Create animations
for name in animations:
    with open(f'assets/animations/{name}.json', 'w') as f:
        json.dump(lottie, f)
    print(f'Created: assets/animations/{name}.json')

print('\n✅ All 30 placeholder assets created successfully!')
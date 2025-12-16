#!/usr/bin/env python3
"""
Generate a simple app icon for Smart Aid
"""
from PIL import Image, ImageDraw, ImageFont
import os

# Create icon directory if it doesn't exist
os.makedirs('assets/icon', exist_ok=True)

# Create 1024x1024 icon
size = 1024
icon = Image.new('RGB', (size, size), color='#2196F3')
draw = ImageDraw.Draw(icon)

# Draw a white circle in the center
center = size // 2
radius = size // 3
draw.ellipse(
    [(center - radius, center - radius), (center + radius, center + radius)],
    fill='white',
    outline='white',
    width=10
)

# Try to use a font, fallback to default if not available
try:
    # Try to use a bold font
    font_size = size // 3
    font = ImageFont.truetype("arial.ttf", font_size)
except:
    try:
        font = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", font_size)
    except:
        font = ImageFont.load_default()

# Draw "SA" text in the center
text = "SA"
bbox = draw.textbbox((0, 0), text, font=font)
text_width = bbox[2] - bbox[0]
text_height = bbox[3] - bbox[1]
text_x = center - text_width // 2
text_y = center - text_height // 2

draw.text(
    (text_x, text_y),
    text,
    fill='#2196F3',
    font=font,
    anchor='mm'
)

# Save the icon
icon.save('assets/icon/app_icon.png', 'PNG')
print("Icon generated: assets/icon/app_icon.png")

# Create foreground icon (same as main icon for adaptive icon)
icon.save('assets/icon/app_icon_foreground.png', 'PNG')
print("Foreground icon generated: assets/icon/app_icon_foreground.png")


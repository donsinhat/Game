#!/usr/bin/env python3
"""
Game Asset Generator using Google Gemini AI
Generates pixel art style images for the Arabic survival game "Gold or Blood"
"""

import os
import base64
import io
import json
from pathlib import Path

try:
    import google.generativeai as genai
    from PIL import Image
    GENAI_AVAILABLE = True
except ImportError:
    GENAI_AVAILABLE = False
    print("Warning: google-generativeai or PIL not available, using fallback generation")

# Asset output directories
ASSETS_DIR = Path("assets")
CHARACTERS_DIR = ASSETS_DIR / "characters"
ENEMIES_DIR = ASSETS_DIR / "enemies"
PICKUPS_DIR = ASSETS_DIR / "pickups"
BACKGROUNDS_DIR = ASSETS_DIR / "backgrounds"

# Create directories
for dir_path in [CHARACTERS_DIR, ENEMIES_DIR, PICKUPS_DIR, BACKGROUNDS_DIR]:
    dir_path.mkdir(parents=True, exist_ok=True)

# Asset definitions with detailed prompts for Gemini
ASSET_PROMPTS = {
    "characters": {
        "abu_sulaiman": {
            "prompt": "Pixel art game sprite of an Arab wealthy merchant man, wearing white thobe (traditional Saudi dress), red and white shemagh headscarf with black agal, has a short beard, standing pose, front view, 64x64 pixels, retro game style, transparent background, vibrant colors",
            "size": (64, 64),
            "description": "Abu Sulaiman - Wealthy Merchant"
        },
        "jayzen": {
            "prompt": "Pixel art game sprite of a tough Arab fighter man with afro hair, wearing sunglasses, messy red shemagh, purple shirt and grey pants, confident pose, front view, 64x64 pixels, retro game style, transparent background, vibrant colors",
            "size": (64, 64),
            "description": "Jayzen - Tough Fighter"
        },
        "noura": {
            "prompt": "Pixel art game sprite of a strong Arab woman wearing white hijab and blue traditional dress, elegant and powerful stance, front view, 64x64 pixels, retro game style, transparent background, vibrant colors",
            "size": (64, 64),
            "description": "Noura - Strong Woman"
        }
    },
    "enemies": {
        "wolf": {
            "prompt": "Pixel art game sprite of a desert wolf enemy, grey fur, yellow glowing eyes, aggressive pose, side view slightly angled, 48x48 pixels, retro game style, transparent background",
            "size": (48, 48),
            "description": "Desert Wolf Enemy"
        },
        "dhub": {
            "prompt": "Pixel art game sprite of a dhub lizard (spiny-tailed lizard), green scales, red eyes, desert reptile, side view, 48x48 pixels, retro game style, transparent background",
            "size": (48, 48),
            "description": "Dhub Lizard Enemy"
        },
        "scorpion": {
            "prompt": "Pixel art game sprite of a large orange desert scorpion, red stinger, pincers raised, aggressive pose, top-down view, 40x40 pixels, retro game style, transparent background",
            "size": (40, 40),
            "description": "Desert Scorpion Enemy"
        }
    },
    "pickups": {
        "xp_gem": {
            "prompt": "Pixel art game sprite of a glowing green experience gem, diamond shape, bright green glow effect, 24x24 pixels, retro game style, transparent background",
            "size": (24, 24),
            "description": "XP Gem Pickup"
        },
        "gold_coin": {
            "prompt": "Pixel art game sprite of a shiny gold coin, Arabic style design, golden glow, 24x24 pixels, retro game style, transparent background",
            "size": (24, 24),
            "description": "Gold Coin Pickup"
        }
    },
    "backgrounds": {
        "sand_tile": {
            "prompt": "Pixel art seamless desert sand texture tile, warm sand colors, subtle variations, can be tiled, 64x64 pixels, retro game style",
            "size": (64, 64),
            "description": "Sand Background Tile"
        }
    }
}


def create_fallback_sprite(name: str, size: tuple, category: str) -> Image.Image:
    """Create a simple fallback sprite using PIL when Gemini is not available"""
    from PIL import Image, ImageDraw
    
    width, height = size
    img = Image.new('RGBA', (width, height), (0, 0, 0, 0))
    draw = ImageDraw.Draw(img)
    
    # Color schemes based on character/enemy
    color_schemes = {
        # Characters
        "abu_sulaiman": {"primary": (245, 245, 245), "secondary": (204, 0, 0), "skin": (212, 165, 116)},
        "jayzen": {"primary": (106, 27, 154), "secondary": (204, 51, 51), "skin": (212, 165, 116)},
        "noura": {"primary": (30, 136, 229), "secondary": (245, 245, 245), "skin": (232, 213, 196)},
        # Enemies
        "wolf": {"primary": (106, 106, 106), "secondary": (58, 58, 58), "accent": (255, 255, 0)},
        "dhub": {"primary": (90, 138, 90), "secondary": (58, 90, 58), "accent": (255, 0, 0)},
        "scorpion": {"primary": (255, 165, 0), "secondary": (138, 106, 0), "accent": (255, 0, 0)},
        # Pickups
        "xp_gem": {"primary": (0, 255, 0), "secondary": (0, 170, 0), "accent": (170, 255, 170)},
        "gold_coin": {"primary": (255, 221, 0), "secondary": (170, 136, 0), "accent": (255, 255, 255)},
        # Background
        "sand_tile": {"primary": (210, 180, 140), "secondary": (190, 160, 120), "accent": (230, 200, 160)},
    }
    
    colors = color_schemes.get(name, {"primary": (128, 128, 128), "secondary": (64, 64, 64), "accent": (255, 255, 255)})
    
    if category == "characters":
        # Draw character sprite
        # Head
        head_y = height // 6
        head_size = width // 3
        draw.ellipse([width//2 - head_size//2, head_y, width//2 + head_size//2, head_y + head_size], 
                     fill=colors["skin"])
        
        # Body
        body_top = head_y + head_size
        body_height = height // 2
        draw.rectangle([width//4, body_top, 3*width//4, body_top + body_height], 
                      fill=colors["primary"])
        
        # Headwear
        draw.rectangle([width//2 - head_size//2 - 2, head_y - 4, width//2 + head_size//2 + 2, head_y + 4], 
                      fill=colors["secondary"])
        
        # Legs
        leg_top = body_top + body_height
        leg_width = width // 6
        draw.rectangle([width//3 - leg_width//2, leg_top, width//3 + leg_width//2, height - 4], 
                      fill=colors.get("legs", (85, 85, 85)))
        draw.rectangle([2*width//3 - leg_width//2, leg_top, 2*width//3 + leg_width//2, height - 4], 
                      fill=colors.get("legs", (85, 85, 85)))
        
    elif category == "enemies":
        # Draw enemy sprite
        if name == "wolf":
            # Wolf body
            draw.ellipse([4, height//3, width-4, height-8], fill=colors["primary"])
            # Head
            draw.ellipse([width//2 - 8, 4, width//2 + 12, height//2], fill=colors["primary"])
            # Eyes
            draw.ellipse([width//2 + 2, height//4, width//2 + 6, height//4 + 4], fill=colors["accent"])
            # Ears
            draw.polygon([(width//2 - 6, 8), (width//2 - 2, 2), (width//2 + 2, 8)], fill=colors["secondary"])
            draw.polygon([(width//2 + 8, 8), (width//2 + 12, 2), (width//2 + 16, 8)], fill=colors["secondary"])
            
        elif name == "dhub":
            # Lizard body
            draw.ellipse([8, height//4, width-8, 3*height//4], fill=colors["primary"])
            # Head
            draw.ellipse([2, height//3, width//3, 2*height//3], fill=colors["primary"])
            # Eye
            draw.ellipse([6, height//2 - 2, 10, height//2 + 2], fill=colors["accent"])
            # Tail
            draw.polygon([(width-8, height//2), (width-2, height//3), (width-2, 2*height//3)], fill=colors["secondary"])
            
        elif name == "scorpion":
            # Body
            draw.ellipse([width//4, height//4, 3*width//4, 3*height//4], fill=colors["primary"])
            # Pincers
            draw.ellipse([2, height//4, width//4, height//2], fill=colors["primary"])
            draw.ellipse([3*width//4, height//4, width-2, height//2], fill=colors["primary"])
            # Tail
            for i in range(4):
                y = height//2 + i * 4
                draw.ellipse([width//2 - 3, y, width//2 + 3, y + 6], fill=colors["secondary"])
            # Stinger
            draw.polygon([(width//2, height-8), (width//2 - 3, height-2), (width//2 + 3, height-2)], fill=colors["accent"])
            
    elif category == "pickups":
        if name == "xp_gem":
            # Diamond shape
            center = (width // 2, height // 2)
            points = [
                (center[0], 2),
                (width - 2, center[1]),
                (center[0], height - 2),
                (2, center[1])
            ]
            draw.polygon(points, fill=colors["primary"])
            # Inner highlight
            inner_points = [
                (center[0], 6),
                (width - 6, center[1]),
                (center[0], height - 6),
                (6, center[1])
            ]
            draw.polygon(inner_points, fill=colors["accent"])
            
        elif name == "gold_coin":
            # Outer circle
            draw.ellipse([2, 2, width-2, height-2], fill=colors["primary"])
            # Inner circle
            draw.ellipse([4, 4, width-4, height-4], fill=colors["secondary"])
            # Shine
            draw.ellipse([6, 6, width//2 - 2, height//2 - 2], fill=colors["accent"])
            
    elif category == "backgrounds":
        # Sand tile with noise
        import random
        for y in range(height):
            for x in range(width):
                noise = random.randint(-20, 20)
                r = min(255, max(0, colors["primary"][0] + noise))
                g = min(255, max(0, colors["primary"][1] + noise))
                b = min(255, max(0, colors["primary"][2] + noise))
                img.putpixel((x, y), (r, g, b, 255))
    
    return img


def generate_with_gemini(prompt: str, size: tuple, api_key: str) -> Image.Image:
    """Generate an image using Google Gemini"""
    if not GENAI_AVAILABLE:
        raise RuntimeError("Google Generative AI not available")
    
    genai.configure(api_key=api_key)
    
    # Use Gemini's image generation capability
    # Note: As of the knowledge cutoff, Gemini's image generation might be limited
    # We'll use the model to generate a detailed description and then create pixel art
    
    try:
        # Try using Imagen through Gemini if available
        model = genai.ImageGenerationModel("imagen-3.0-generate-001")
        
        result = model.generate_images(
            prompt=prompt,
            number_of_images=1,
            aspect_ratio="1:1",
            safety_filter_level="block_only_high",
            person_generation="allow_adult"
        )
        
        if result.images:
            image = result.images[0]._pil_image
            # Resize to desired size
            image = image.resize(size, Image.NEAREST)
            return image
            
    except Exception as e:
        print(f"Gemini image generation failed: {e}")
        raise


def generate_all_assets(api_key: str = None):
    """Generate all game assets"""
    
    print("=" * 60)
    print("  Game Asset Generator - Gold or Blood")
    print("=" * 60)
    
    use_gemini = api_key is not None and GENAI_AVAILABLE
    
    if use_gemini:
        print(f"\nUsing Gemini AI for image generation")
    else:
        print(f"\nUsing fallback pixel art generation")
        print("(Set GEMINI_API_KEY environment variable for AI generation)")
    
    generated_assets = []
    
    for category, assets in ASSET_PROMPTS.items():
        print(f"\n--- Generating {category} ---")
        
        output_dir = ASSETS_DIR / category
        
        for asset_name, asset_info in assets.items():
            output_path = output_dir / f"{asset_name}.png"
            print(f"  Creating {asset_info['description']}...", end=" ")
            
            try:
                if use_gemini:
                    try:
                        img = generate_with_gemini(
                            asset_info["prompt"],
                            asset_info["size"],
                            api_key
                        )
                    except Exception as e:
                        print(f"(Gemini failed, using fallback)")
                        img = create_fallback_sprite(asset_name, asset_info["size"], category)
                else:
                    img = create_fallback_sprite(asset_name, asset_info["size"], category)
                
                # Save the image
                img.save(output_path, "PNG")
                generated_assets.append(str(output_path))
                print("✓")
                
            except Exception as e:
                print(f"✗ Error: {e}")
    
    print(f"\n{'=' * 60}")
    print(f"  Generated {len(generated_assets)} assets")
    print(f"{'=' * 60}")
    
    # Create an asset manifest
    manifest = {
        "version": "1.0",
        "assets": {}
    }
    
    for category, assets in ASSET_PROMPTS.items():
        manifest["assets"][category] = {}
        for asset_name, asset_info in assets.items():
            manifest["assets"][category][asset_name] = {
                "path": f"assets/{category}/{asset_name}.png",
                "size": asset_info["size"],
                "description": asset_info["description"]
            }
    
    manifest_path = ASSETS_DIR / "manifest.json"
    with open(manifest_path, "w") as f:
        json.dump(manifest, f, indent=2)
    
    print(f"\nAsset manifest saved to: {manifest_path}")
    
    return generated_assets


def create_enhanced_pixel_sprites():
    """Create enhanced pixel art sprites with more detail"""
    from PIL import Image, ImageDraw
    
    print("\n--- Creating Enhanced Pixel Art Sprites ---\n")
    
    # Abu Sulaiman - Wealthy Merchant with detailed sprite
    def create_abu_sulaiman():
        img = Image.new('RGBA', (64, 64), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        # Define pixel colors
        colors = {
            'black_agal': (26, 26, 26),
            'red_shemagh': (204, 0, 0),
            'skin': (212, 165, 116),
            'skin_shadow': (196, 149, 106),
            'eyes': (42, 42, 42),
            'beard': (58, 42, 26),
            'white_thobe': (245, 245, 245),
            'bisht': (139, 105, 20),
            'sandals': (42, 42, 42),
        }
        
        # Pixel matrix (simplified for brevity - actual game uses full matrix)
        # Draw the sprite using the defined colors
        
        # Head/Shemagh area
        for y in range(8, 16):
            for x in range(24, 40):
                draw.point((x, y), colors['red_shemagh'])
        
        # Agal (black ring)
        for x in range(22, 42):
            draw.point((x, 6), colors['black_agal'])
            draw.point((x, 7), colors['black_agal'])
        
        # Face
        for y in range(16, 24):
            for x in range(26, 38):
                draw.point((x, y), colors['skin'])
        
        # Eyes
        draw.point((29, 18), colors['eyes'])
        draw.point((35, 18), colors['eyes'])
        
        # Beard
        for y in range(22, 26):
            for x in range(28, 36):
                draw.point((x, y), colors['beard'])
        
        # White Thobe (body)
        for y in range(26, 52):
            for x in range(20, 44):
                draw.point((x, y), colors['white_thobe'])
        
        # Bisht (cloak) on sides
        for y in range(30, 48):
            for x in range(16, 22):
                draw.point((x, y), colors['bisht'])
            for x in range(42, 48):
                draw.point((x, y), colors['bisht'])
        
        # Arms
        for y in range(30, 44):
            for x in range(18, 22):
                draw.point((x, y), colors['skin'])
            for x in range(42, 46):
                draw.point((x, y), colors['skin'])
        
        # Feet/Sandals
        for y in range(52, 58):
            for x in range(24, 32):
                draw.point((x, y), colors['sandals'])
            for x in range(32, 40):
                draw.point((x, y), colors['sandals'])
        
        return img
    
    # Jayzen - Tough Fighter
    def create_jayzen():
        img = Image.new('RGBA', (64, 64), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        colors = {
            'afro': (42, 26, 10),
            'red_shemagh': (204, 51, 51),
            'skin': (212, 165, 116),
            'sunglasses': (26, 26, 26),
            'sunglasses_lens': (51, 51, 51),
            'purple_shirt': (106, 27, 154),
            'grey_pants': (85, 85, 85),
            'shoes': (58, 58, 58),
        }
        
        # Afro hair
        for y in range(4, 14):
            for x in range(22, 42):
                if (x - 32) ** 2 + (y - 9) ** 2 < 100:
                    draw.point((x, y), colors['afro'])
        
        # Face
        for y in range(14, 24):
            for x in range(26, 38):
                draw.point((x, y), colors['skin'])
        
        # Messy shemagh
        for y in range(10, 16):
            for x in range(20, 26):
                draw.point((x, y), colors['red_shemagh'])
            for x in range(38, 44):
                draw.point((x, y), colors['red_shemagh'])
        
        # Sunglasses
        for x in range(27, 32):
            draw.point((x, 17), colors['sunglasses'])
            draw.point((x, 18), colors['sunglasses_lens'])
        for x in range(33, 38):
            draw.point((x, 17), colors['sunglasses'])
            draw.point((x, 18), colors['sunglasses_lens'])
        
        # Purple shirt
        for y in range(26, 44):
            for x in range(22, 42):
                draw.point((x, y), colors['purple_shirt'])
        
        # Arms
        for y in range(28, 42):
            for x in range(18, 24):
                draw.point((x, y), colors['skin'])
            for x in range(40, 46):
                draw.point((x, y), colors['skin'])
        
        # Grey pants
        for y in range(44, 56):
            for x in range(24, 40):
                draw.point((x, y), colors['grey_pants'])
        
        # Shoes
        for y in range(56, 60):
            for x in range(24, 32):
                draw.point((x, y), colors['shoes'])
            for x in range(32, 40):
                draw.point((x, y), colors['shoes'])
        
        return img
    
    # Noura - Strong Woman
    def create_noura():
        img = Image.new('RGBA', (64, 64), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        colors = {
            'hijab': (245, 245, 245),
            'skin': (232, 213, 196),
            'eyes': (26, 26, 26),
            'lips': (212, 164, 164),
            'blue_dress': (30, 136, 229),
            'shoes': (21, 101, 192),
        }
        
        # Hijab
        for y in range(4, 20):
            for x in range(20, 44):
                if (x - 32) ** 2 + (y - 12) ** 2 < 144:
                    draw.point((x, y), colors['hijab'])
        
        # Face (visible through hijab)
        for y in range(14, 22):
            for x in range(26, 38):
                draw.point((x, y), colors['skin'])
        
        # Eyes
        draw.point((29, 17), colors['eyes'])
        draw.point((35, 17), colors['eyes'])
        
        # Lips
        for x in range(30, 34):
            draw.point((x, 20), colors['lips'])
        
        # Hijab covering neck
        for y in range(20, 28):
            for x in range(22, 42):
                draw.point((x, y), colors['hijab'])
        
        # Blue dress
        for y in range(28, 54):
            for x in range(18, 46):
                draw.point((x, y), colors['blue_dress'])
        
        # Hands
        for y in range(38, 44):
            for x in range(16, 20):
                draw.point((x, y), colors['skin'])
            for x in range(44, 48):
                draw.point((x, y), colors['skin'])
        
        # Shoes
        for y in range(54, 60):
            for x in range(24, 32):
                draw.point((x, y), colors['shoes'])
            for x in range(32, 40):
                draw.point((x, y), colors['shoes'])
        
        return img
    
    # Create and save enhanced sprites
    sprites = {
        'abu_sulaiman': create_abu_sulaiman(),
        'jayzen': create_jayzen(),
        'noura': create_noura(),
    }
    
    for name, img in sprites.items():
        output_path = CHARACTERS_DIR / f"{name}.png"
        img.save(output_path, "PNG")
        print(f"  Created enhanced sprite: {output_path}")
    
    return sprites


def create_enemy_sprites():
    """Create detailed enemy sprites"""
    from PIL import Image, ImageDraw
    
    print("\n--- Creating Enemy Sprites ---\n")
    
    def create_wolf():
        img = Image.new('RGBA', (48, 48), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        grey = (106, 106, 106)
        dark_grey = (58, 58, 58)
        yellow = (255, 255, 0)
        
        # Body
        draw.ellipse([8, 18, 40, 40], fill=grey, outline=dark_grey)
        
        # Head
        draw.ellipse([4, 8, 24, 28], fill=grey, outline=dark_grey)
        
        # Ears
        draw.polygon([(6, 8), (10, 2), (14, 8)], fill=grey, outline=dark_grey)
        draw.polygon([(14, 8), (18, 2), (22, 8)], fill=grey, outline=dark_grey)
        
        # Eyes
        draw.ellipse([8, 14, 12, 18], fill=yellow)
        draw.ellipse([14, 14, 18, 18], fill=yellow)
        
        # Nose
        draw.ellipse([10, 20, 14, 24], fill=dark_grey)
        
        # Legs
        for x_offset in [12, 20, 28, 36]:
            draw.rectangle([x_offset, 38, x_offset + 4, 46], fill=grey, outline=dark_grey)
        
        # Tail
        draw.arc([32, 20, 48, 36], 180, 360, fill=grey, width=4)
        
        return img
    
    def create_dhub():
        img = Image.new('RGBA', (48, 48), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        green = (90, 138, 90)
        dark_green = (58, 90, 58)
        red = (255, 0, 0)
        brown = (138, 106, 58)
        
        # Body
        draw.ellipse([12, 16, 40, 32], fill=green, outline=dark_green)
        
        # Head
        draw.ellipse([2, 18, 16, 30], fill=green, outline=dark_green)
        
        # Eye
        draw.ellipse([6, 22, 10, 26], fill=red)
        
        # Tail with spikes
        for i in range(4):
            x = 36 + i * 3
            draw.ellipse([x, 22, x + 4, 26], fill=brown)
        
        # Legs
        for pos in [(14, 30), (22, 30), (30, 30), (38, 30)]:
            draw.rectangle([pos[0], pos[1], pos[0] + 4, pos[1] + 8], fill=green, outline=dark_green)
        
        # Scales pattern
        for y in range(18, 30, 4):
            for x in range(16, 38, 4):
                draw.point((x, y), dark_green)
        
        return img
    
    def create_scorpion():
        img = Image.new('RGBA', (40, 40), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        orange = (255, 165, 0)
        dark_orange = (138, 106, 0)
        red = (255, 0, 0)
        
        # Body
        draw.ellipse([12, 12, 28, 28], fill=orange, outline=dark_orange)
        
        # Head
        draw.ellipse([14, 6, 26, 14], fill=orange, outline=dark_orange)
        
        # Eyes
        draw.ellipse([16, 8, 19, 11], fill=red)
        draw.ellipse([21, 8, 24, 11], fill=red)
        
        # Pincers
        draw.ellipse([2, 8, 12, 18], fill=orange, outline=dark_orange)
        draw.ellipse([28, 8, 38, 18], fill=orange, outline=dark_orange)
        draw.line([(4, 10), (2, 8)], fill=dark_orange, width=2)
        draw.line([(36, 10), (38, 8)], fill=dark_orange, width=2)
        
        # Tail segments
        for i in range(4):
            y = 26 + i * 3
            draw.ellipse([18, y, 22, y + 4], fill=dark_orange)
        
        # Stinger
        draw.polygon([(20, 38), (18, 40), (22, 40)], fill=red)
        
        # Legs
        for i in range(3):
            draw.line([(10 - i*2, 20 + i*2), (6 - i*2, 24 + i*2)], fill=dark_orange, width=2)
            draw.line([(30 + i*2, 20 + i*2), (34 + i*2, 24 + i*2)], fill=dark_orange, width=2)
        
        return img
    
    sprites = {
        'wolf': create_wolf(),
        'dhub': create_dhub(),
        'scorpion': create_scorpion(),
    }
    
    for name, img in sprites.items():
        output_path = ENEMIES_DIR / f"{name}.png"
        img.save(output_path, "PNG")
        print(f"  Created enemy sprite: {output_path}")
    
    return sprites


def create_pickup_sprites():
    """Create pickup item sprites"""
    from PIL import Image, ImageDraw
    
    print("\n--- Creating Pickup Sprites ---\n")
    
    def create_xp_gem():
        img = Image.new('RGBA', (24, 24), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        # Diamond shape with glow effect
        center = (12, 12)
        
        # Outer glow
        for offset in range(3, 0, -1):
            alpha = 100 - offset * 30
            points = [
                (center[0], 2 - offset),
                (22 + offset, center[1]),
                (center[0], 22 + offset),
                (2 - offset, center[1])
            ]
            draw.polygon(points, fill=(0, 255, 0, alpha))
        
        # Main gem
        points = [
            (center[0], 4),
            (20, center[1]),
            (center[0], 20),
            (4, center[1])
        ]
        draw.polygon(points, fill=(0, 255, 0))
        
        # Inner highlight
        inner_points = [
            (center[0], 8),
            (16, center[1]),
            (center[0], 16),
            (8, center[1])
        ]
        draw.polygon(inner_points, fill=(170, 255, 170))
        
        # Bright center
        draw.ellipse([10, 10, 14, 14], fill=(255, 255, 255))
        
        return img
    
    def create_gold_coin():
        img = Image.new('RGBA', (24, 24), (0, 0, 0, 0))
        draw = ImageDraw.Draw(img)
        
        gold = (255, 215, 0)
        dark_gold = (170, 136, 0)
        light_gold = (255, 235, 100)
        
        # Outer glow
        draw.ellipse([1, 1, 23, 23], fill=(255, 215, 0, 100))
        
        # Outer ring
        draw.ellipse([3, 3, 21, 21], fill=dark_gold)
        
        # Main coin
        draw.ellipse([5, 5, 19, 19], fill=gold)
        
        # Inner detail
        draw.ellipse([8, 8, 16, 16], fill=dark_gold)
        draw.ellipse([9, 9, 15, 15], fill=gold)
        
        # Shine
        draw.ellipse([6, 6, 10, 10], fill=light_gold)
        draw.point((7, 7), (255, 255, 255))
        
        return img
    
    sprites = {
        'xp_gem': create_xp_gem(),
        'gold_coin': create_gold_coin(),
    }
    
    for name, img in sprites.items():
        output_path = PICKUPS_DIR / f"{name}.png"
        img.save(output_path, "PNG")
        print(f"  Created pickup sprite: {output_path}")
    
    return sprites


def create_background_tile():
    """Create sand background tile"""
    from PIL import Image
    import random
    
    print("\n--- Creating Background Tile ---\n")
    
    img = Image.new('RGBA', (64, 64), (0, 0, 0, 255))
    
    base_r, base_g, base_b = 210, 180, 140
    
    for y in range(64):
        for x in range(64):
            # Add noise for natural sand look
            noise = random.randint(-15, 15)
            r = min(255, max(0, base_r + noise))
            g = min(255, max(0, base_g + noise))
            b = min(255, max(0, base_b + noise))
            img.putpixel((x, y), (r, g, b, 255))
    
    # Add some small rocks/pebbles
    for _ in range(5):
        rx = random.randint(4, 60)
        ry = random.randint(4, 60)
        rock_color = (90 + random.randint(-20, 20), 90 + random.randint(-20, 20), 90 + random.randint(-20, 20), 255)
        for dy in range(-2, 3):
            for dx in range(-2, 3):
                if dx*dx + dy*dy <= 4:
                    px, py = rx + dx, ry + dy
                    if 0 <= px < 64 and 0 <= py < 64:
                        img.putpixel((px, py), rock_color)
    
    output_path = BACKGROUNDS_DIR / "sand_tile.png"
    img.save(output_path, "PNG")
    print(f"  Created background tile: {output_path}")
    
    return img


if __name__ == "__main__":
    import sys
    
    # Check for API key
    api_key = os.environ.get("GEMINI_API_KEY") or os.environ.get("GOOGLE_API_KEY")
    
    if len(sys.argv) > 1:
        api_key = sys.argv[1]
    
    print("\n" + "=" * 60)
    print("  Gold or Blood - Game Asset Generator")
    print("=" * 60)
    
    if api_key:
        print(f"\n  Using Gemini AI with provided API key")
        print(f"  Generating AI-powered game assets...")
        generate_all_assets(api_key)
    else:
        print(f"\n  No Gemini API key found")
        print(f"  Creating enhanced pixel art sprites...")
        
        # Create all sprites using PIL
        create_enhanced_pixel_sprites()
        create_enemy_sprites()
        create_pickup_sprites()
        create_background_tile()
        
        # Create manifest
        manifest = {
            "version": "1.0",
            "generator": "pixel_art_fallback",
            "assets": {
                "characters": {
                    "abu_sulaiman": {"path": "assets/characters/abu_sulaiman.png", "size": [64, 64]},
                    "jayzen": {"path": "assets/characters/jayzen.png", "size": [64, 64]},
                    "noura": {"path": "assets/characters/noura.png", "size": [64, 64]}
                },
                "enemies": {
                    "wolf": {"path": "assets/enemies/wolf.png", "size": [48, 48]},
                    "dhub": {"path": "assets/enemies/dhub.png", "size": [48, 48]},
                    "scorpion": {"path": "assets/enemies/scorpion.png", "size": [40, 40]}
                },
                "pickups": {
                    "xp_gem": {"path": "assets/pickups/xp_gem.png", "size": [24, 24]},
                    "gold_coin": {"path": "assets/pickups/gold_coin.png", "size": [24, 24]}
                },
                "backgrounds": {
                    "sand_tile": {"path": "assets/backgrounds/sand_tile.png", "size": [64, 64]}
                }
            }
        }
        
        with open(ASSETS_DIR / "manifest.json", "w") as f:
            json.dump(manifest, f, indent=2)
    
    print("\n" + "=" * 60)
    print("  Asset generation complete!")
    print("  Assets saved to: ./assets/")
    print("=" * 60 + "\n")

import os
from PIL import Image, ImageOps, ImageFilter, ImageDraw
import math

BRAIN_DIR = r"C:\Users\User\.gemini\antigravity\brain\e9c56e7e-5266-417e-b6b9-4e8cf4635ad2"
ASSETS_DIR = r"d:\DProjects\Potato-War\main\assets"

def remove_white_bg(img, threshold=245, feather=3):
    """Converts white/near-white pixels to transparent with smooth edge antialiasing."""
    img = img.convert("RGBA")
    r, g, b, a = img.split()
    
    # Calculate whiteness
    # Pixels where r, g, b are all high are background
    whiteness = ImageOps.invert(ImageOps.grayscale(img))
    
    # Create mask: 0 (transparent) for white, 255 (opaque) for dark
    # Anything with min(r,g,b) >= threshold is transparent
    datas = img.getdata()
    new_alpha = []
    for item in datas:
        # Distance from pure white
        min_c = min(item[0], item[1], item[2])
        if min_c >= threshold:
            # Fully transparent
            new_alpha.append(0)
        elif min_c > threshold - 20:
            # Transition edge
            t = (threshold - min_c) / 20.0
            new_alpha.append(int(255 * t))
        else:
            new_alpha.append(255)
            
    alpha_img = Image.new("L", img.size)
    alpha_img.putdata(new_alpha)
    
    # Smooth alpha slightly
    if feather > 0:
        alpha_img = alpha_img.filter(ImageFilter.BoxBlur(feather * 0.5))
        
    img.putalpha(alpha_img)
    return img

def crop_content(img):
    """Crops transparent borders."""
    bbox = img.getbbox()
    if bbox:
        return img.crop(bbox)
    return img

def main():
    print("Processing Biome Skies...")
    skies = {
        "arctic": "arctic_aurora_sky_background_1793642604959.jpg",
        "grass": "meadow_sunset_bg_1793642666781.jpg",
        "desert": "desert_canyon_background_1793642664462.jpg",
        "volcano": "volcanic_hell_sky_backdrop_1793642684262.jpg",
        "alien": "alien_planet_sky_background_1793642665581.jpg"
    }
    
    for biome, fname in skies.items():
        src = os.path.join(BRAIN_DIR, fname)
        if os.path.exists(src):
            img = Image.open(src).convert("RGBA")
            # Resize to standard widescreen 1376x768 or 1280x720
            out_name = f"bg_sky_{biome}.png"
            dest = os.path.join(ASSETS_DIR, out_name)
            img.save(dest, "PNG")
            print(f"  Saved {dest} ({img.size[0]}x{img.size[1]})")
            if biome == "arctic":
                # Also save default fallback
                img.save(os.path.join(ASSETS_DIR, "bg_sky.png"), "PNG")

    print("\nProcessing Floating Islands...")
    sheet_path = os.path.join(BRAIN_DIR, "floating_game_islands_1793642771874.jpg")
    desert_island_path = os.path.join(BRAIN_DIR, "canyon_mesa_island_1793642812074.jpg")
    
    sheet = Image.open(sheet_path)
    sw, sh = sheet.size
    half_w = sw // 2
    half_h = sh // 2
    
    # Quadrants:
    # Top-Left: Arctic
    # Top-Right: Grass
    # Bottom-Left: Volcano
    # Bottom-Right: Alien
    raw_arctic = sheet.crop((0, 0, half_w, half_h))
    raw_grass = sheet.crop((half_w, 0, sw, half_h))
    raw_volcano = sheet.crop((0, half_h, half_w, sh))
    raw_alien = sheet.crop((half_w, half_h, sw, sh))
    
    arctic_cut = crop_content(remove_white_bg(raw_arctic))
    grass_cut = crop_content(remove_white_bg(raw_grass))
    volcano_cut = crop_content(remove_white_bg(raw_volcano))
    alien_cut = crop_content(remove_white_bg(raw_alien))
    
    desert_sheet = Image.open(desert_island_path)
    desert_cut = crop_content(remove_white_bg(desert_sheet))
    
    islands = {
        "arctic": arctic_cut,
        "grass": grass_cut,
        "desert": desert_cut,
        "volcano": volcano_cut,
        "alien": alien_cut
    }
    
    # Create parallax islands layers for each biome: 960x240 transparent canvas
    # Place 3-4 islands of varying sizes across the panoramic width
    for biome, isl in islands.items():
        canvas = Image.new("RGBA", (960, 240), (0, 0, 0, 0))
        
        # Main island (medium-left)
        iw, ih = isl.size
        # Scaled versions
        scale1 = 150.0 / ih
        s_isl1 = isl.resize((int(iw * scale1), int(ih * scale1)), Image.Resampling.LANCZOS)
        
        scale2 = 110.0 / ih
        s_isl2 = isl.resize((int(iw * scale2), int(ih * scale2)), Image.Resampling.LANCZOS)
        
        scale3 = 90.0 / ih
        s_isl3 = isl.resize((int(iw * scale3), int(ih * scale3)), Image.Resampling.LANCZOS)
        
        # Paste islands across canvas with slight parallax depths
        # Island 1: x=60, y=50
        canvas.paste(s_isl2, (60, 50), s_isl2)
        # Island 2: x=380, y=30 (higher up)
        canvas.paste(s_isl1, (360, 20), s_isl1)
        # Island 3: x=720, y=60
        canvas.paste(s_isl3, (720, 60), s_isl3)
        
        out_name = f"bg_islands_{biome}.png"
        dest = os.path.join(ASSETS_DIR, out_name)
        canvas.save(dest, "PNG")
        print(f"  Saved {dest} (960x240)")
        
        if biome == "arctic":
            canvas.save(os.path.join(ASSETS_DIR, "bg_islands.png"), "PNG")

    print("\nGenerating Atmospheric VFX Sprites...")
    # 1. Snowflake (64x64)
    snow = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    draw = ImageDraw.Draw(snow)
    cx, cy = 32, 32
    # Draw soft glow
    for r in range(16, 2, -2):
        a = int(25 * (1.0 - r / 16.0))
        draw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(210, 245, 255, a))
    # 6 arms
    for i in range(6):
        angle = i * (math.pi / 3.0)
        ex = cx + math.cos(angle) * 22
        ey = cy + math.sin(angle) * 22
        draw.line([cx, cy, ex, ey], fill=(255, 255, 255, 240), width=3)
        # Side branches
        bx = cx + math.cos(angle) * 12
        by = cy + math.sin(angle) * 12
        b1_x = bx + math.cos(angle + math.pi/4) * 6
        b1_y = by + math.sin(angle + math.pi/4) * 6
        b2_x = bx + math.cos(angle - math.pi/4) * 6
        b2_y = by + math.sin(angle - math.pi/4) * 6
        draw.line([bx, by, b1_x, b1_y], fill=(235, 250, 255, 220), width=2)
        draw.line([bx, by, b2_x, b2_y], fill=(235, 250, 255, 220), width=2)
    draw.ellipse([cx - 4, cy - 4, cx + 4, cy + 4], fill=(255, 255, 255, 255))
    snow.save(os.path.join(ASSETS_DIR, "vfx_snow.png"), "PNG")
    print("  Saved vfx_snow.png")

    # 2. Ember (64x64) - fiery spark
    ember = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    edraw = ImageDraw.Draw(ember)
    for r in range(24, 2, -2):
        a = int(45 * (1.0 - r / 24.0))
        edraw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(255, 80, 20, a))
    for r in range(12, 1, -1):
        a = int(80 * (1.0 - r / 12.0))
        edraw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(255, 170, 40, a))
    edraw.ellipse([cx - 4, cy - 4, cx + 4, cy + 4], fill=(255, 250, 210, 250))
    ember.save(os.path.join(ASSETS_DIR, "vfx_ember.png"), "PNG")
    print("  Saved vfx_ember.png")

    # 3. Spore (64x64) - alien glowing mote
    spore = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    sdraw = ImageDraw.Draw(spore)
    for r in range(22, 2, -2):
        a = int(50 * (1.0 - r / 22.0))
        sdraw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(40, 240, 220, a))
    for r in range(10, 1, -1):
        a = int(90 * (1.0 - r / 10.0))
        sdraw.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(120, 255, 240, a))
    sdraw.ellipse([cx - 3, cy - 3, cx + 3, cy + 3], fill=(255, 255, 255, 255))
    spore.save(os.path.join(ASSETS_DIR, "vfx_spore.png"), "PNG")
    print("  Saved vfx_spore.png")

    # 4. Leaf / Petal (64x64)
    leaf = Image.new("RGBA", (64, 64), (0, 0, 0, 0))
    ldraw = ImageDraw.Draw(leaf)
    # Draw soft organic leaf shape
    points = [(cx, cy - 18), (cx + 12, cy - 6), (cx + 10, cy + 12), (cx, cy + 20), (cx - 10, cy + 12), (cx - 12, cy - 6)]
    ldraw.polygon(points, fill=(120, 210, 60, 220), outline=(70, 150, 40, 255))
    ldraw.line([cx, cy - 14, cx, cy + 16], fill=(180, 245, 120, 220), width=2)
    leaf.save(os.path.join(ASSETS_DIR, "vfx_leaf.png"), "PNG")
    print("  Saved vfx_leaf.png")

    print("\nAll assets successfully processed and saved to main/assets/!")

if __name__ == "__main__":
    main()

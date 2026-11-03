import os
from PIL import Image, ImageDraw, ImageFont, ImageFilter

ASSETS_DIR = r"d:\DProjects\Potato-War\main\assets"
ARTIFACT_DIR = r"C:\Users\User\.gemini\antigravity\brain\e9c56e7e-5266-417e-b6b9-4e8cf4635ad2"

def render_biome_preview(biome, title):
    # Base canvas: 960x540
    cw, ch = 960, 540
    canvas = Image.new("RGBA", (cw, ch), (20, 20, 30, 255))
    
    # 1. Sky layer
    sky_path = os.path.join(ASSETS_DIR, f"bg_sky_{biome}.png")
    if os.path.exists(sky_path):
        sky = Image.open(sky_path).convert("RGBA")
        sky = sky.resize((cw, ch), Image.Resampling.LANCZOS)
        canvas.paste(sky, (0, 0))
        
    # 2. Midground Floating Islands (Removed per user request - clean background only)
        
    # 3. Atmospheric VFX Particles
    vfx_file = "vfx_snow.png" if biome == "arctic" else ("vfx_ember.png" if biome == "volcano" else ("vfx_spore.png" if biome == "alien" else "vfx_leaf.png"))
    vfx_path = os.path.join(ASSETS_DIR, vfx_file)
    if os.path.exists(vfx_path):
        vfx = Image.open(vfx_path).convert("RGBA")
        # Scatter several particles across the scene
        positions = [
            (120, 140, 0.6), (280, 80, 0.4), (450, 190, 0.8), (620, 110, 0.5),
            (780, 210, 0.7), (200, 310, 0.5), (850, 150, 0.6), (340, 260, 0.4)
        ]
        for px, py, sc in positions:
            pw, ph = int(vfx.size[0] * sc), int(vfx.size[1] * sc)
            s_vfx = vfx.resize((pw, ph), Image.Resampling.BILINEAR)
            canvas.paste(s_vfx, (px, py), s_vfx)

    # 4. Water / Hazard at bottom
    water_path = os.path.join(ASSETS_DIR, "water.png")
    if os.path.exists(water_path):
        water = Image.open(water_path).convert("RGBA")
        # Tint water according to biome
        tints = {
            "arctic": (60, 160, 240, 240),
            "volcano": (255, 90, 20, 250),
            "alien": (40, 250, 160, 240),
            "grass": (255, 185, 60, 250),
            "desert": (30, 210, 200, 240)
        }
        tw = tints.get(biome, (255, 255, 255, 255))
        w_re = water.resize((cw, 80), Image.Resampling.BILINEAR)
        # Apply tint
        r, g, b, a = w_re.split()
        r = r.point(lambda p: int(p * tw[0] / 255.0))
        g = g.point(lambda p: int(p * tw[1] / 255.0))
        b = b.point(lambda p: int(p * tw[2] / 255.0))
        tinted_water = Image.merge("RGBA", (r, g, b, a))
        canvas.paste(tinted_water, (0, ch - 60), tinted_water)
        
    # Title overlay badge
    draw = ImageDraw.Draw(canvas)
    draw.rectangle([20, 20, 240, 60], fill=(10, 15, 25, 210), outline=(80, 140, 220, 255), width=2)
    draw.text((32, 28), title, fill=(255, 255, 255))
    
    return canvas

def main():
    biomes = [
        ("arctic", "ARCTIC / СНЕГ"),
        ("grass", "GRASS / ПОЛЯ"),
        ("desert", "DESERT / КАНЬОН"),
        ("volcano", "VOLCANO / ЛАВА"),
        ("alien", "ALIEN / ПЛАНЕТА")
    ]
    
    # 1. Generate Arctic Full Preview (960x540)
    arctic_shot = render_biome_preview("arctic", "ARCTIC (AURORA + VFX)")
    arctic_dest = os.path.join(ARTIFACT_DIR, "arctic_upgraded_preview.png")
    arctic_shot.save(arctic_dest)
    print(f"Saved {arctic_dest}")
    
    # 2. Generate All Biomes Showcase Grid (2 columns or combined banner)
    grid_w = 960 * 2
    grid_h = 540 * 3
    grid = Image.new("RGBA", (grid_w, grid_h), (15, 18, 25, 255))
    
    idx = 0
    for b_id, b_title in biomes:
        shot = render_biome_preview(b_id, b_title)
        gx = (idx % 2) * 960
        gy = (idx // 2) * 540
        grid.paste(shot, (gx, gy))
        idx += 1
        
    grid_dest = os.path.join(ARTIFACT_DIR, "all_biomes_showcase.png")
    grid.save(grid_dest)
    print(f"Saved {grid_dest}")

if __name__ == "__main__":
    main()

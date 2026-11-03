import os
from PIL import Image, ImageDraw, ImageFont
import numpy as np

BRAIN_DIR = r"C:\Users\User\.gemini\antigravity\brain\e9c56e7e-5266-417e-b6b9-4e8cf4635ad2"
ASSETS_DIR = r"d:\DProjects\Potato-War\main\assets"

def main():
    sheet_path = os.path.join(BRAIN_DIR, "potato_base_sprite_1793645006051.jpg")
    sheet = Image.open(sheet_path).convert("RGBA")
    hand_path = os.path.join(BRAIN_DIR, "clean_rayman_hand.png")
    hand = Image.open(hand_path).convert("RGBA")
    hand_r = hand.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
    hand_w, hand_h = hand.size

    # Update circle.png (32x32) and hand.png for weapon rig
    hand_32 = hand.resize((32, 32), Image.Resampling.LANCZOS)
    hand_32.save(os.path.join(ASSETS_DIR, "circle.png"), "PNG", optimize=True)
    hand.save(os.path.join(ASSETS_DIR, "hand.png"), "PNG", optimize=True)
    print("Updated circle.png and hand.png")

    # Cell configurations for the 6 potato classes from the master sheet
    cells_cfg = {
        "recruit": {"box": (30, 45, 365, 335),   "body_x": (65, 265)},
        "medic":   {"box": (340, 45, 680, 335),  "body_x": (65, 265)},
        "sniper":  {"box": (660, 40, 1020, 340), "body_x": (50, 252)},
        "assault": {"box": (30, 360, 365, 645),  "body_x": (65, 265)},
        "sapper":  {"box": (340, 360, 680, 645), "body_x": (65, 265)},
        "tank":    {"box": (660, 350, 1020, 650), "body_x": (65, 265)},
    }

    def clean_body(raw, body_x):
        arr = np.array(raw)
        r, g, b, a = arr[:,:,0], arr[:,:,1], arr[:,:,2], arr[:,:,3]
        m = np.minimum(np.minimum(r, g), b)
        alpha = np.where(m >= 244, 0, np.where(m > 224, ((244 - m) / 20.0 * 255).astype(np.uint8), 255)).astype(np.uint8)
        h, w = arr.shape[:2]
        for y in range(h - 45, h):
            for x in range(w):
                p = arr[y, x]
                if alpha[y, x] > 0 and abs(int(p[0]) - int(p[1])) < 16 and abs(int(p[1]) - int(p[2])) < 16 and p[0] > 130:
                    alpha[y, x] = 0
        raw.putalpha(Image.fromarray(alpha))
        body = raw.crop((body_x[0], 0, body_x[1], h))
        bbox = body.getbbox()
        return body.crop(bbox)

    bodies = {name: clean_body(sheet.crop(cfg["box"]), cfg["body_x"]) for name, cfg in cells_cfg.items()}

    def assemble(body, gear_fn=None):
        bw, bh = body.size
        cw = bw + 110
        ch = bh
        comp = Image.new("RGBA", (cw, ch), (0, 0, 0, 0))
        bx = (cw - bw) // 2
        comp.paste(body, (bx, 0), body)
        if gear_fn:
            gear_fn(comp, bx, 0, bw, bh)
        comp.paste(hand, (10, 175), hand)
        comp.paste(hand_r, (cw - hand_w - 10, 175), hand_r)
        return comp

    # Class 1: Recruit
    char_recruit = assemble(bodies["recruit"])

    # Class 2: Medic
    def paint_medic(comp, bx, by, bw, bh):
        draw = ImageDraw.Draw(comp)
        cx, cy = bx + 95, by + 120
        draw.rectangle([cx - 4, cy - 12, cx + 4, cy + 12], fill=(225, 30, 30, 255))
        draw.rectangle([cx - 12, cy - 4, cx + 12, cy + 4], fill=(225, 30, 30, 255))
        draw.line([(cx - 3, cy - 11), (cx - 3, cy + 11)], fill=(255, 140, 140, 200), width=1)
        draw.line([(cx - 11, cy - 3), (cx + 11, cy - 3)], fill=(255, 140, 140, 200), width=1)
    char_medic = assemble(bodies["medic"], paint_medic)

    # Class 3: Sapper
    def paint_sapper(comp, bx, by, bw, bh):
        draw = ImageDraw.Draw(comp)
        c_red = (215, 35, 35, 255)
        c_red_dark = (145, 20, 20, 255)
        c_fuse = (240, 235, 220, 255)
        c_band = (35, 35, 40, 255)
        c_out = (35, 18, 10, 255)
        for stick_cx in [bx + 42, bx + 54, bx + 66, bx + 138, bx + 150, bx + 162]:
            draw.line([(stick_cx, 168), (stick_cx + 2, 175)], fill=c_fuse, width=2)
            draw.rounded_rectangle([stick_cx - 5, 175, stick_cx + 5, 218], radius=2, fill=c_red, outline=c_out, width=2)
            draw.line([(stick_cx - 2, 177), (stick_cx - 2, 216)], fill=(255, 100, 100, 255), width=1)
            draw.line([(stick_cx + 3, 177), (stick_cx + 3, 216)], fill=c_red_dark, width=1)
            draw.rectangle([stick_cx - 5, 192, stick_cx + 5, 198], fill=c_band, outline=c_out, width=1)
    char_sapper = assemble(bodies["sapper"], paint_sapper)

    # Class 4: Tank
    def paint_tank(comp, bx, by, bw, bh):
        draw = ImageDraw.Draw(comp)
        cx = bx + bw // 2
        pts = [
            (cx - 55, 130), (cx - 20, 140), (cx + 20, 140), (cx + 55, 130),
            (cx + 60, 182), (cx + 25, 195), (cx - 25, 195), (cx - 60, 182),
        ]
        c_plate = (70, 78, 88, 255)
        c_plate_light = (110, 120, 135, 255)
        c_plate_dark = (45, 52, 60, 255)
        c_out = (25, 28, 35, 255)
        c_rivet = (185, 195, 205, 255)
        draw.polygon(pts, fill=c_plate, outline=c_out, width=3)
        draw.line([(cx - 50, 134), (cx + 50, 134)], fill=c_plate_light, width=2)
        draw.line([(cx - 55, 180), (cx + 55, 180)], fill=c_plate_dark, width=2)
        draw.line([(cx, 140), (cx, 195)], fill=c_out, width=2)
        for rx, ry in [(cx - 45, 142), (cx + 45, 142), (cx - 48, 172), (cx + 48, 172), (cx - 15, 185), (cx + 15, 185)]:
            draw.ellipse([rx - 3, ry - 3, rx + 3, ry + 3], fill=c_rivet, outline=c_out, width=1)
    char_tank = assemble(bodies["tank"], paint_tank)

    # Class 5: Assault
    def paint_assault(comp, bx, by, bw, bh):
        draw = ImageDraw.Draw(comp)
        cx = bx + bw // 2
        c_olive = (88, 102, 52, 255)
        c_olive_dark = (60, 72, 35, 255)
        c_strap = (62, 48, 32, 255)
        c_out = (35, 25, 15, 255)
        c_buckle = (150, 160, 170, 255)
        draw.polygon([(cx - 48, 105), (cx - 32, 100), (cx - 30, 138), (cx - 46, 138)], fill=c_strap, outline=c_out, width=2)
        draw.polygon([(cx + 32, 100), (cx + 48, 105), (cx + 46, 138), (cx + 30, 138)], fill=c_strap, outline=c_out, width=2)
        pts = [
            (cx - 52, 136), (cx - 20, 145), (cx + 20, 145), (cx + 52, 136),
            (cx + 56, 180), (cx - 56, 180),
        ]
        draw.polygon(pts, fill=c_olive, outline=c_out, width=3)
        draw.rounded_rectangle([cx - 48, 148, cx - 22, 175], radius=3, fill=c_olive_dark, outline=c_out, width=2)
        draw.rounded_rectangle([cx + 22, 148, cx + 48, 175], radius=3, fill=c_olive_dark, outline=c_out, width=2)
        draw.rectangle([cx - 10, 160, cx + 10, 175], fill=c_buckle, outline=c_out, width=2)
        draw.line([cx, 160, cx, 175], fill=c_out, width=2)
    char_assault = assemble(bodies["assault"], paint_assault)

    # Class 6: Sniper
    def paint_sniper(comp, bx, by, bw, bh):
        draw = ImageDraw.Draw(comp)
        cx = bx + bw // 2
        c_leaf1 = (35, 115, 45, 255)
        c_leaf2 = (55, 145, 60, 255)
        c_leaf3 = (85, 165, 55, 255)
        c_out = (20, 45, 15, 255)
        petals = [
            (cx - 55, 135, 16, 9, c_leaf1),
            (cx - 38, 138, 18, 10, c_leaf2),
            (cx - 20, 142, 17, 10, c_leaf3),
            (cx, 144, 18, 10, c_leaf2),
            (cx + 20, 142, 17, 10, c_leaf3),
            (cx + 38, 138, 18, 10, c_leaf2),
            (cx + 55, 135, 16, 9, c_leaf1),
            (cx - 45, 126, 15, 8, c_leaf2),
            (cx - 18, 132, 16, 9, c_leaf1),
            (cx + 18, 132, 16, 9, c_leaf1),
            (cx + 45, 126, 15, 8, c_leaf2),
        ]
        for px, py, rx, ry, col in petals:
            draw.ellipse([px - rx, py - ry, px + rx, py + ry], fill=col, outline=c_out, width=2)
            draw.line([(px - rx + 4, py), (px + rx - 4, py)], fill=(20, 50, 20, 180), width=1)
    char_sniper = assemble(bodies["sniper"], paint_sniper)

    TARGET_HEIGHT = 128
    all_chars = {
        "recruit": char_recruit,
        "assault": char_assault,
        "tank": char_tank,
        "sapper": char_sapper,
        "medic": char_medic,
        "sniper": char_sniper,
    }

    mapping = {
        "recruit": ["recruit.png", "potato_base.png", "potato_recruit.png", "potato_recruit_blue.png", "potato_recruit_red.png", "potato_base_blue.png", "potato_base_red.png"],
        "assault": ["assault.png", "potato_assault.png", "potato_assault_blue.png", "potato_assault_red.png"],
        "tank": ["tank.png", "potato_tank.png", "potato_artillery.png", "potato_tank_blue.png", "potato_tank_red.png", "potato_artillery_blue.png", "potato_artillery_red.png"],
        "sapper": ["sapper.png", "potato_sapper.png", "potato_sapper_blue.png", "potato_sapper_red.png"],
        "medic": ["medic.png", "potato_medic.png", "potato_medic_blue.png", "potato_medic_red.png"],
        "sniper": ["sniper.png", "potato_sniper.png", "potato_sniper_blue.png", "potato_sniper_red.png"],
    }

    print("Deploying 6 legless Rayman characters to main/assets/...")
    for name, char_img in all_chars.items():
        aspect = char_img.size[0] / float(char_img.size[1])
        target_w = int(TARGET_HEIGHT * aspect)
        scaled = char_img.resize((target_w, TARGET_HEIGHT), Image.Resampling.LANCZOS)
        for fname in mapping[name]:
            dest = os.path.join(ASSETS_DIR, fname)
            scaled.save(dest, "PNG", optimize=True)
        print(f"  Class '{name}': {char_img.size} -> ({target_w}, {TARGET_HEIGHT})")

    # Generate Lineup Showcase
    show_w = 160 * 6
    show_h = 240
    canvas = Image.new("RGBA", (show_w, show_h), (25, 30, 42, 255))
    draw = ImageDraw.Draw(canvas)
    try:
        font = ImageFont.truetype(os.path.join(ASSETS_DIR, "font.ttf"), 13)
    except:
        font = ImageFont.load_default()

    titles = [
        ("recruit", "РЕКРУТ (RECRUIT)"),
        ("assault", "ШТУРМОВИК (ASSAULT)"),
        ("tank", "ТАНК (TANK)"),
        ("sapper", "САПЁР (SAPPER)"),
        ("medic", "МЕДИК (MEDIC)"),
        ("sniper", "СНАЙПЕР (SNIPER)")
    ]

    for i, (cls_name, title) in enumerate(titles):
        col_cx = i * 160 + 80
        sp = all_chars[cls_name]
        aspect = sp.size[0] / float(sp.size[1])
        target_w = int(TARGET_HEIGHT * aspect)
        scaled = sp.resize((target_w, TARGET_HEIGHT), Image.Resampling.LANCZOS)

        draw.ellipse([col_cx - 45, 175, col_cx + 45, 195], fill=(38, 48, 65, 255), outline=(65, 85, 115, 255), width=2)
        px = col_cx - scaled.size[0] // 2
        py = 180 - scaled.size[1]
        canvas.paste(scaled, (px, py), scaled)
        bbox = draw.textbbox((0, 0), title, font=font)
        tw = bbox[2] - bbox[0]
        draw.text((col_cx - tw // 2, 205), title, fill=(240, 245, 255), font=font)

    lineup_path = os.path.join(BRAIN_DIR, "all_potatoes_showcase.png")
    canvas.save(lineup_path)
    print(f"\nSaved lineup showcase to: {lineup_path}")

if __name__ == "__main__":
    main()

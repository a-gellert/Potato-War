Add-Type -ReferencedAssemblies System.Drawing -TypeDefinition @'
using System;
using System.Drawing;
using System.Drawing.Drawing2D;
using System.Drawing.Imaging;
using System.Collections.Generic;

public class SpriteProcessor
{
    public static void ProcessCharacter(string inputPath, string outputPath, int targetSize = 64)
    {
        using (Bitmap src = new Bitmap(inputPath))
        {
            int w = src.Width;
            int h = src.Height;
            
            Bitmap argb = new Bitmap(w, h, PixelFormat.Format32bppArgb);
            using (Graphics g = Graphics.FromImage(argb))
            {
                g.DrawImage(src, 0, 0, w, h);
            }
            
            BitmapData data = argb.LockBits(new Rectangle(0, 0, w, h), ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
            int stride = data.Stride;
            IntPtr scan0 = data.Scan0;
            
            byte[] bytes = new byte[Math.Abs(stride) * h];
            System.Runtime.InteropServices.Marshal.Copy(scan0, bytes, 0, bytes.Length);
            
            bool[] visited = new bool[w * h];
            Queue<int> queue = new Queue<int>();
            
            // Seed flood fill from edges
            for (int x = 0; x < w; x++)
            {
                queue.Enqueue(x);
                visited[x] = true;
                int bIdx = (h - 1) * w + x;
                queue.Enqueue(bIdx);
                visited[bIdx] = true;
            }
            for (int y = 0; y < h; y++)
            {
                int lIdx = y * w;
                if (!visited[lIdx]) { queue.Enqueue(lIdx); visited[lIdx] = true; }
                int rIdx = y * w + (w - 1);
                if (!visited[rIdx]) { queue.Enqueue(rIdx); visited[rIdx] = true; }
            }
            
            while (queue.Count > 0)
            {
                int curr = queue.Dequeue();
                int cy = curr / w;
                int cx = curr % w;
                
                int offset = cy * stride + cx * 4;
                byte b = bytes[offset];
                byte gCol = bytes[offset + 1];
                byte r = bytes[offset + 2];
                
                // Near-white or ground shadow
                bool isWhite = (r >= 235 && gCol >= 235 && b >= 235);
                bool isShadow = (cy > h * 0.80) && (r >= 95 && r <= 180 && gCol >= 80 && gCol <= 155 && b >= 70 && b <= 145);
                
                if (isWhite || isShadow)
                {
                    bytes[offset + 3] = 0; // alpha = 0
                    
                    int[] dx = { 0, 0, 1, -1 };
                    int[] dy = { 1, -1, 0, 0 };
                    for (int i = 0; i < 4; i++)
                    {
                        int nx = cx + dx[i];
                        int ny = cy + dy[i];
                        if (nx >= 0 && nx < w && ny >= 0 && ny < h)
                        {
                            int nIdx = ny * w + nx;
                            if (!visited[nIdx])
                            {
                                visited[nIdx] = true;
                                queue.Enqueue(nIdx);
                            }
                        }
                    }
                }
            }
            
            System.Runtime.InteropServices.Marshal.Copy(bytes, 0, scan0, bytes.Length);
            argb.UnlockBits(data);
            
            // Bounding box
            int minX = w, maxX = 0, minY = h, maxY = 0;
            for (int y = 0; y < h; y++)
            {
                for (int x = 0; x < w; x++)
                {
                    Color p = argb.GetPixel(x, y);
                    if (p.A > 20)
                    {
                        if (x < minX) minX = x;
                        if (x > maxX) maxX = x;
                        if (y < minY) minY = y;
                        if (y > maxY) maxY = y;
                    }
                }
            }
            
            int charW = Math.Max(1, maxX - minX + 1);
            int charH = Math.Max(1, maxY - minY + 1);
            
            Bitmap finalBmp = new Bitmap(targetSize, targetSize, PixelFormat.Format32bppArgb);
            using (Graphics gFinal = Graphics.FromImage(finalBmp))
            {
                gFinal.Clear(Color.Transparent);
                gFinal.InterpolationMode = InterpolationMode.HighQualityBicubic;
                gFinal.SmoothingMode = SmoothingMode.HighQuality;
                gFinal.PixelOffsetMode = PixelOffsetMode.HighQuality;
                
                int pad = 2;
                int maxTargetDim = targetSize - pad * 2;
                float scale = Math.Min((float)maxTargetDim / charW, (float)maxTargetDim / charH);
                int drawW = (int)Math.Round(charW * scale);
                int drawH = (int)Math.Round(charH * scale);
                int destX = (targetSize - drawW) / 2;
                int destY = targetSize - pad - drawH;
                
                gFinal.DrawImage(argb, new Rectangle(destX, destY, drawW, drawH), new Rectangle(minX, minY, charW, charH), GraphicsUnit.Pixel);
            }
            
            finalBmp.Save(outputPath, ImageFormat.Png);
            finalBmp.Dispose();
            argb.Dispose();
        }
    }

    public static void CropAndScale(string inputPath, string outputPath, int cropX, int cropY, int cropW, int cropH, int targetW, int targetH)
    {
        using (Bitmap src = new Bitmap(inputPath))
        {
            Bitmap argb = new Bitmap(cropW, cropH, PixelFormat.Format32bppArgb);
            using (Graphics g = Graphics.FromImage(argb))
            {
                g.DrawImage(src, new Rectangle(0, 0, cropW, cropH), new Rectangle(cropX, cropY, cropW, cropH), GraphicsUnit.Pixel);
            }

            // Remove white background via flood fill from edges
            BitmapData data = argb.LockBits(new Rectangle(0, 0, cropW, cropH), ImageLockMode.ReadWrite, PixelFormat.Format32bppArgb);
            int stride = data.Stride;
            IntPtr scan0 = data.Scan0;
            byte[] bytes = new byte[Math.Abs(stride) * cropH];
            System.Runtime.InteropServices.Marshal.Copy(scan0, bytes, 0, bytes.Length);

            bool[] visited = new bool[cropW * cropH];
            Queue<int> queue = new Queue<int>();
            for (int x = 0; x < cropW; x++)
            {
                queue.Enqueue(x); visited[x] = true;
                int bIdx = (cropH - 1) * cropW + x; queue.Enqueue(bIdx); visited[bIdx] = true;
            }
            for (int y = 0; y < cropH; y++)
            {
                int lIdx = y * cropW; if (!visited[lIdx]) { queue.Enqueue(lIdx); visited[lIdx] = true; }
                int rIdx = y * cropW + (cropW - 1); if (!visited[rIdx]) { queue.Enqueue(rIdx); visited[rIdx] = true; }
            }

            while (queue.Count > 0)
            {
                int curr = queue.Dequeue();
                int cy = curr / cropW;
                int cx = curr % cropW;
                int offset = cy * stride + cx * 4;
                byte b = bytes[offset];
                byte gCol = bytes[offset + 1];
                byte r = bytes[offset + 2];

                if (r >= 235 && gCol >= 235 && b >= 235)
                {
                    bytes[offset + 3] = 0;
                    int[] dx = { 0, 0, 1, -1 };
                    int[] dy = { 1, -1, 0, 0 };
                    for (int i = 0; i < 4; i++)
                    {
                        int nx = cx + dx[i];
                        int ny = cy + dy[i];
                        if (nx >= 0 && nx < cropW && ny >= 0 && ny < cropH)
                        {
                            int nIdx = ny * cropW + nx;
                            if (!visited[nIdx])
                            {
                                visited[nIdx] = true;
                                queue.Enqueue(nIdx);
                            }
                        }
                    }
                }
            }
            System.Runtime.InteropServices.Marshal.Copy(bytes, 0, scan0, bytes.Length);
            argb.UnlockBits(data);

            // Find tight bounds
            int minX = cropW, maxX = 0, minY = cropH, maxY = 0;
            for (int y = 0; y < cropH; y++)
            {
                for (int x = 0; x < cropW; x++)
                {
                    Color p = argb.GetPixel(x, y);
                    if (p.A > 20)
                    {
                        if (x < minX) minX = x;
                        if (x > maxX) maxX = x;
                        if (y < minY) minY = y;
                        if (y > maxY) maxY = y;
                    }
                }
            }

            int itemW = Math.Max(1, maxX - minX + 1);
            int itemH = Math.Max(1, maxY - minY + 1);

            Bitmap finalBmp = new Bitmap(targetW, targetH, PixelFormat.Format32bppArgb);
            using (Graphics gFinal = Graphics.FromImage(finalBmp))
            {
                gFinal.Clear(Color.Transparent);
                gFinal.InterpolationMode = InterpolationMode.HighQualityBicubic;
                gFinal.SmoothingMode = SmoothingMode.HighQuality;
                gFinal.PixelOffsetMode = PixelOffsetMode.HighQuality;

                int pad = 1;
                float scale = Math.Min((float)(targetW - pad * 2) / itemW, (float)(targetH - pad * 2) / itemH);
                int drawW = (int)Math.Round(itemW * scale);
                int drawH = (int)Math.Round(itemH * scale);
                int destX = (targetW - drawW) / 2;
                int destY = (targetH - drawH) / 2;

                gFinal.DrawImage(argb, new Rectangle(destX, destY, drawW, drawH), new Rectangle(minX, minY, itemW, itemH), GraphicsUnit.Pixel);
            }

            finalBmp.Save(outputPath, ImageFormat.Png);
            finalBmp.Dispose();
            argb.Dispose();
        }
    }

    public static void CreateTeamVariant(string inputPath, string outputPath, float hueShift)
    {
        using (Bitmap src = new Bitmap(inputPath))
        {
            Bitmap res = new Bitmap(src.Width, src.Height, PixelFormat.Format32bppArgb);
            for (int y = 0; y < src.Height; y++)
            {
                for (int x = 0; x < src.Width; x++)
                {
                    Color p = src.GetPixel(x, y);
                    if (p.A == 0)
                    {
                        res.SetPixel(x, y, Color.Transparent);
                    }
                    else
                    {
                        // Check if pixel is predominantly red (like the headband / accents)
                        // If R is significantly higher than G and B
                        if (p.R > 130 && p.R > p.G * 1.35f && p.R > p.B * 1.35f)
                        {
                            // Shift red to team blue!
                            int newR = (int)(p.B * 0.4f + p.G * 0.2f);
                            int newG = (int)(p.G * 0.7f + p.R * 0.3f);
                            int newB = Math.Min(255, (int)(p.R * 1.1f + 30));
                            res.SetPixel(x, y, Color.FromArgb(p.A, newR, newG, newB));
                        }
                        else
                        {
                            res.SetPixel(x, y, p);
                        }
                    }
                }
            }
            res.Save(outputPath, ImageFormat.Png);
            res.Dispose();
        }
    }
}
'@

$files = @(
    @{ In = "C:\Users\User\.gemini\antigravity\brain\fd717b43-0e84-42ba-a460-8314ebc385f8\potato_base_sprite_1791387899189.jpg"; Out = "d:\DProjects\Potato-War\main\assets\potato_base.png" },
    @{ In = "C:\Users\User\.gemini\antigravity\brain\fd717b43-0e84-42ba-a460-8314ebc385f8\potato_sniper_noweapon_1791389814735.jpg"; Out = "d:\DProjects\Potato-War\main\assets\potato_sniper.png" },
    @{ In = "C:\Users\User\.gemini\antigravity\brain\fd717b43-0e84-42ba-a460-8314ebc385f8\potato_assault_noweapon_1791389834446.jpg"; Out = "d:\DProjects\Potato-War\main\assets\potato_assault.png" },
    @{ In = "C:\Users\User\.gemini\antigravity\brain\fd717b43-0e84-42ba-a460-8314ebc385f8\potato_medic_noweapon.jpg"; Out = "d:\DProjects\Potato-War\main\assets\potato_medic.png" },
    @{ In = "C:\Users\User\.gemini\antigravity\brain\fd717b43-0e84-42ba-a460-8314ebc385f8\potato_sapper_noweapon.jpg"; Out = "d:\DProjects\Potato-War\main\assets\potato_sapper.png" },
    @{ In = "C:\Users\User\.gemini\antigravity\brain\fd717b43-0e84-42ba-a460-8314ebc385f8\potato_tank_noweapon.jpg"; Out = "d:\DProjects\Potato-War\main\assets\potato_tank.png" },
    @{ In = "C:\Users\User\.gemini\antigravity\brain\fd717b43-0e84-42ba-a460-8314ebc385f8\potato_artillery_noweapon.jpg"; Out = "d:\DProjects\Potato-War\main\assets\potato_artillery.png" }
)

foreach ($f in $files) {
    [SpriteProcessor]::ProcessCharacter($f.In, $f.Out, 64)
    Write-Output "Processed: $($f.Out)"
}

$weapons = @(
    @{ In = "C:\Users\User\.gemini\antigravity\brain\fd717b43-0e84-42ba-a460-8314ebc385f8\weapon_axe_knife_1791388054577.jpg"; Out = "d:\DProjects\Potato-War\main\assets\knife.png"; X = 150; Y = 60; W = 750; H = 500; TW = 44; TH = 44 },
    @{ In = "C:\Users\User\.gemini\antigravity\brain\fd717b43-0e84-42ba-a460-8314ebc385f8\weapon_axe_knife_1791388054577.jpg"; Out = "d:\DProjects\Potato-War\main\assets\peeler.png"; X = 150; Y = 540; W = 750; H = 420; TW = 44; TH = 26 },
    @{ In = "C:\Users\User\.gemini\antigravity\brain\fd717b43-0e84-42ba-a460-8314ebc385f8\weapon_grenade_bazooka_1791388074357.jpg"; Out = "d:\DProjects\Potato-War\main\assets\grenade.png"; X = 60; Y = 120; W = 420; H = 760; TW = 36; TH = 42 },
    @{ In = "C:\Users\User\.gemini\antigravity\brain\fd717b43-0e84-42ba-a460-8314ebc385f8\weapon_grenade_bazooka_1791388074357.jpg"; Out = "d:\DProjects\Potato-War\main\assets\masher_bazooka.png"; X = 460; Y = 80; W = 520; H = 820; TW = 48; TH = 36 },
    @{ In = "C:\Users\User\.gemini\antigravity\brain\fd717b43-0e84-42ba-a460-8314ebc385f8\weapon_rifles_shotgun_1791388091940.jpg"; Out = "d:\DProjects\Potato-War\main\assets\skewer_rifle.png"; X = 40; Y = 100; W = 940; H = 240; TW = 56; TH = 24 },
    @{ In = "C:\Users\User\.gemini\antigravity\brain\fd717b43-0e84-42ba-a460-8314ebc385f8\weapon_rifles_shotgun_1791388091940.jpg"; Out = "d:\DProjects\Potato-War\main\assets\rifle.png"; X = 40; Y = 400; W = 940; H = 280; TW = 48; TH = 26 },
    @{ In = "C:\Users\User\.gemini\antigravity\brain\fd717b43-0e84-42ba-a460-8314ebc385f8\weapon_rifles_shotgun_1791388091940.jpg"; Out = "d:\DProjects\Potato-War\main\assets\grater.png"; X = 40; Y = 710; W = 940; H = 270; TW = 48; TH = 24 },
    @{ In = "C:\Users\User\.gemini\antigravity\brain\fd717b43-0e84-42ba-a460-8314ebc385f8\weapon_tactical_set_1791388112447.jpg"; Out = "d:\DProjects\Potato-War\main\assets\drill_missile.png"; X = 30; Y = 30; W = 360; H = 420; TW = 40; TH = 26 },
    @{ In = "C:\Users\User\.gemini\antigravity\brain\fd717b43-0e84-42ba-a460-8314ebc385f8\weapon_tactical_set_1791388112447.jpg"; Out = "d:\DProjects\Potato-War\main\assets\pepper_bomb.png"; X = 340; Y = 30; W = 340; H = 420; TW = 34; TH = 36 },
    @{ In = "C:\Users\User\.gemini\antigravity\brain\fd717b43-0e84-42ba-a460-8314ebc385f8\weapon_tactical_set_1791388112447.jpg"; Out = "d:\DProjects\Potato-War\main\assets\garlic_bomb.png"; X = 670; Y = 30; W = 340; H = 420; TW = 34; TH = 36 },
    @{ In = "C:\Users\User\.gemini\antigravity\brain\fd717b43-0e84-42ba-a460-8314ebc385f8\weapon_tactical_set_1791388112447.jpg"; Out = "d:\DProjects\Potato-War\main\assets\oil_bottle.png"; X = 60; Y = 490; W = 380; H = 440; TW = 32; TH = 40 },
    @{ In = "C:\Users\User\.gemini\antigravity\brain\fd717b43-0e84-42ba-a460-8314ebc385f8\weapon_tactical_set_1791388112447.jpg"; Out = "d:\DProjects\Potato-War\main\assets\air_bomb.png"; X = 530; Y = 510; W = 420; H = 420; TW = 38; TH = 28 }
)

$classes = @('base', 'sniper', 'assault', 'medic', 'sapper', 'tank', 'artillery')
foreach ($c in $classes) {
    $srcPath = "d:\DProjects\Potato-War\main\assets\potato_$c.png"
    $bluePath = "d:\DProjects\Potato-War\main\assets\potato_${c}_blue.png"
    $redPath = "d:\DProjects\Potato-War\main\assets\potato_${c}_red.png"
    
    Copy-Item $srcPath $redPath -Force
    [SpriteProcessor]::CreateTeamVariant($srcPath, $bluePath, 0)
    Write-Output "Created variants for: $c"
}



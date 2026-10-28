# Full Google Play Screenshots Generator for Potato War
Add-Type -AssemblyName System.Drawing

function Get-RoundedRectanglePath {
    param (
        [System.Drawing.Rectangle]$rect,
        [int]$radius
    )
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $diameter = [Math]::Max(2, ($radius * 2))
    $arc = New-Object System.Drawing.Rectangle $rect.X, $rect.Y, $diameter, $diameter

    $path.AddArc($arc, 180, 90)
    $arc.X = $rect.Right - $diameter
    $path.AddArc($arc, 270, 90)
    $arc.Y = $rect.Bottom - $diameter
    $path.AddArc($arc, 0, 90)
    $arc.X = $rect.Left
    $path.AddArc($arc, 90, 90)
    $path.CloseFigure()
    return $path
}

function Draw-3DText {
    param (
        $graphics,
        $text,
        $font,
        $x,
        $y,
        $gradTop,
        $gradBottom,
        $outlineColor,
        $shadowColor,
        $outlineSize = 5,
        $shadowDepth = 6
    )

    # 1. 3D shadow layers
    $sBrush = New-Object System.Drawing.SolidBrush $shadowColor
    for ($d = 1; $d -le $shadowDepth; $d++) {
        for ($ox = -$outlineSize; $ox -le $outlineSize; $ox += 2) {
            for ($oy = -$outlineSize; $oy -le $outlineSize; $oy += 2) {
                $graphics.DrawString($text, $font, $sBrush, [float]($x + $ox + $d), [float]($y + $oy + $d))
            }
        }
    }
    $sBrush.Dispose()

    # 2. Strong dark outline
    $oBrush = New-Object System.Drawing.SolidBrush $outlineColor
    for ($ox = -$outlineSize; $ox -le $outlineSize; $ox += 1) {
        for ($oy = -$outlineSize; $oy -le $outlineSize; $oy += 1) {
            if ($ox*$ox + $oy*$oy -le $outlineSize*$outlineSize) {
                $graphics.DrawString($text, $font, $oBrush, [float]($x + $ox), [float]($y + $oy))
            }
        }
    }
    $oBrush.Dispose()

    # 3. Vibrant gradient fill
    $size = $graphics.MeasureString($text, $font)
    $h = [Math]::Max(10.0, $size.Height)
    $fBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush (
        (New-Object System.Drawing.PointF $x, $y),
        (New-Object System.Drawing.PointF $x, ($y + $h)),
        $gradTop,
        $gradBottom
    )
    $graphics.DrawString($text, $font, $fBrush, [float]$x, [float]$y)
    $fBrush.Dispose()
}

function Render-StoreScreenshot {
    param (
        [string]$rawScreenshotPath,
        [string]$outputPath,
        [string]$topTag,
        [string]$titleText,
        [string]$subtitleText,
        [string]$badgeText,
        [System.Drawing.Color]$bgGradientTop,
        [System.Drawing.Color]$bgGradientBottom,
        [System.Drawing.Color]$accentColor,
        [System.Drawing.Color]$titleGradTop,
        [System.Drawing.Color]$titleGradBottom,
        [string]$cornerBadgeImage
    )

    $width = 1920
    $height = 1080
    $bmp = New-Object System.Drawing.Bitmap $width, $height
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

    # 1. Base Gradient Background
    $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush (
        (New-Object System.Drawing.Point 0, 0),
        (New-Object System.Drawing.Point 0, $height),
        $bgGradientTop,
        $bgGradientBottom
    )
    $g.FillRectangle($bgBrush, 0, 0, $width, $height)
    $bgBrush.Dispose()

    # 2. Ambient Game Rays
    $raysPath = "D:\DProjects\Potato-War\main\assets\ui\rays.png"
    if (Test-Path $raysPath) {
        $raysImg = [System.Drawing.Image]::FromFile($raysPath)
        $cm = New-Object System.Drawing.Imaging.ColorMatrix
        $cm.Matrix33 = 0.14
        $ia = New-Object System.Drawing.Imaging.ImageAttributes
        $ia.SetColorMatrix($cm)
        $rayRect = New-Object System.Drawing.Rectangle -200, -200, ($width + 400), ($height + 400)
        $g.DrawImage($raysImg, $rayRect, 0, 0, $raysImg.Width, $raysImg.Height, [System.Drawing.GraphicsUnit]::Pixel, $ia)
        $ia.Dispose()
        $raysImg.Dispose()
    }

    # 3. Ambient Game Blurred Scene
    $rawImg = $null
    if (Test-Path $rawScreenshotPath) {
        $rawImg = [System.Drawing.Image]::FromFile($rawScreenshotPath)
        $cm = New-Object System.Drawing.Imaging.ColorMatrix
        $cm.Matrix33 = 0.20
        $ia = New-Object System.Drawing.Imaging.ImageAttributes
        $ia.SetColorMatrix($cm)
        $ambRect = New-Object System.Drawing.Rectangle -40, -40, ($width + 80), ($height + 80)
        $g.DrawImage($rawImg, $ambRect, 0, 0, $rawImg.Width, $rawImg.Height, [System.Drawing.GraphicsUnit]::Pixel, $ia)
        $ia.Dispose()
    }

    # Atmospheric Vignettes
    $topDarkBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush (
        (New-Object System.Drawing.Point 0, 0),
        (New-Object System.Drawing.Point 0, 220),
        ([System.Drawing.Color]::FromArgb(235, 6, 8, 14)),
        ([System.Drawing.Color]::FromArgb(0, 6, 8, 14))
    )
    $g.FillRectangle($topDarkBrush, 0, 0, $width, 220)
    $topDarkBrush.Dispose()

    $botDarkBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush (
        (New-Object System.Drawing.Point 0, ($height - 200)),
        (New-Object System.Drawing.Point 0, $height),
        ([System.Drawing.Color]::FromArgb(0, 6, 8, 14)),
        ([System.Drawing.Color]::FromArgb(245, 6, 8, 14))
    )
    $g.FillRectangle($botDarkBrush, 0, ($height - 200), $width, 200)
    $botDarkBrush.Dispose()

    # 4. Device Bezel & Screenshot Display
    $cardW = 1580
    $cardH = 728
    $cardX = [int](($width - $cardW) / 2)
    $cardY = 246
    $bezelRadius = 24

    # Deep soft shadow
    for ($s = 22; $s -ge 2; $s -= 3) {
        $sAlpha = [int](85 / ($s * 0.4 + 1))
        $sBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb($sAlpha, 0, 0, 0))
        $sPath = Get-RoundedRectanglePath (New-Object System.Drawing.Rectangle ($cardX - $s), ($cardY - $s + 14), ($cardW + $s*2), ($cardH + $s*2)) ($bezelRadius + $s)
        $g.FillPath($sBrush, $sPath)
        $sPath.Dispose()
        $sBrush.Dispose()
    }

    # Bezel Frame
    $bezelRect = New-Object System.Drawing.Rectangle $cardX, $cardY, $cardW, $cardH
    $bezelPath = Get-RoundedRectanglePath $bezelRect $bezelRadius
    
    $bezelBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush (
        (New-Object System.Drawing.Point $cardX, $cardY),
        (New-Object System.Drawing.Point $cardX, ($cardY + $cardH)),
        ([System.Drawing.Color]::FromArgb(255, 38, 42, 56)),
        ([System.Drawing.Color]::FromArgb(255, 14, 16, 24))
    )
    $g.FillPath($bezelBrush, $bezelPath)
    $bezelBrush.Dispose()

    # Bezel accent border
    $glowPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(200, $accentColor), 4)
    $g.DrawPath($glowPen, $bezelPath)
    $glowPen.Dispose()

    # Inner Screen Viewport
    $inset = 8
    $screenRect = New-Object System.Drawing.Rectangle ($cardX + $inset), ($cardY + $inset), ($cardW - $inset*2), ($cardH - $inset*2)
    $screenRadius = [Math]::Max(4, ($bezelRadius - $inset))
    $screenPath = Get-RoundedRectanglePath $screenRect $screenRadius

    $oldClip = $g.Clip
    $g.SetClip($screenPath)
    if ($rawImg) {
        $g.DrawImage($rawImg, $screenRect, 0, 0, $rawImg.Width, $rawImg.Height, [System.Drawing.GraphicsUnit]::Pixel)
    }
    
    # Elegant diagonal gloss
    $glareBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush (
        (New-Object System.Drawing.Point $screenRect.X, $screenRect.Y),
        (New-Object System.Drawing.Point ($screenRect.Right), ($screenRect.Bottom)),
        ([System.Drawing.Color]::FromArgb(35, 255, 255, 255)),
        ([System.Drawing.Color]::FromArgb(0, 255, 255, 255))
    )
    $g.FillRectangle($glareBrush, $screenRect)
    $glareBrush.Dispose()

    $g.Clip = $oldClip
    $screenPath.Dispose()
    $bezelPath.Dispose()

    if ($rawImg) { $rawImg.Dispose() }

    # 5. Fonts setup
    $pfc = New-Object System.Drawing.Text.PrivateFontCollection
    $pfc.AddFontFile("D:\DProjects\Potato-War\main\assets\fonts\Rubik-Black.ttf")
    $pfc.AddFontFile("D:\DProjects\Potato-War\main\assets\fonts\Rubik-ExtraBold.ttf")
    $blackFam = $pfc.Families[0]
    $extraFam = if ($pfc.Families.Count -gt 1) { $pfc.Families[1] } else { $pfc.Families[0] }

    $tagFont = New-Object System.Drawing.Font ($extraFam, [float]15, [System.Drawing.FontStyle]::Bold)
    $titleFont = New-Object System.Drawing.Font ($blackFam, [float]56, [System.Drawing.FontStyle]::Bold)
    $subFont = New-Object System.Drawing.Font ($extraFam, [float]24, [System.Drawing.FontStyle]::Bold)
    $badgeFont = New-Object System.Drawing.Font ($blackFam, [float]21, [System.Drawing.FontStyle]::Bold)

    # 6. Top Tag
    if ($topTag) {
        $tagSize = $g.MeasureString($topTag, $tagFont)
        $tagPadX = 20
        $tagPadY = 6
        $tagW = [int]($tagSize.Width + $tagPadX * 2)
        $tagH = [int]($tagSize.Height + $tagPadY * 2)
        $tagX = [int](($width - $tagW) / 2)
        $tagY = 22

        $tagRect = New-Object System.Drawing.Rectangle $tagX, $tagY, $tagW, $tagH
        $tagPath = Get-RoundedRectanglePath $tagRect 14

        $tagBgBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(220, 15, 18, 28))
        $g.FillPath($tagBgBrush, $tagPath)
        $tagBgBrush.Dispose()

        $tagPen = New-Object System.Drawing.Pen $accentColor, 2
        $g.DrawPath($tagPen, $tagPath)
        $tagPen.Dispose()

        $tagTextBrush = New-Object System.Drawing.SolidBrush $accentColor
        $g.DrawString($topTag, $tagFont, $tagTextBrush, [float]($tagX + $tagPadX), [float]($tagY + $tagPadY - 1))
        $tagTextBrush.Dispose()
        $tagPath.Dispose()
    }

    # 7. Title & Subtitle
    $titleSize = $g.MeasureString($titleText, $titleFont)
    $titleX = [int](($width - $titleSize.Width) / 2)
    $titleY = if ($topTag) { 62 } else { 45 }

    Draw-3DText -graphics $g -text $titleText -font $titleFont -x $titleX -y $titleY `
        -gradTop $titleGradTop -gradBottom $titleGradBottom `
        -outlineColor ([System.Drawing.Color]::FromArgb(255, 12, 14, 20)) `
        -shadowColor ([System.Drawing.Color]::FromArgb(255, 4, 4, 8)) `
        -outlineSize 6 -shadowDepth 5

    $subSize = $g.MeasureString($subtitleText, $subFont)
    $subX = [int](($width - $subSize.Width) / 2)
    $subY = $titleY + [int]$titleSize.Height - 12

    $subOutline = [System.Drawing.Color]::FromArgb(255, 10, 12, 18)
    $subFill = [System.Drawing.Color]::FromArgb(255, 245, 248, 255)
    Draw-3DText -graphics $g -text $subtitleText -font $subFont -x $subX -y $subY `
        -gradTop $subFill -gradBottom ([System.Drawing.Color]::FromArgb(255, 215, 225, 240)) `
        -outlineColor $subOutline -shadowColor ([System.Drawing.Color]::FromArgb(180, 0, 0, 0)) `
        -outlineSize 3 -shadowDepth 3

    # 8. Bottom Badge
    if ($badgeText) {
        $badgeSize = $g.MeasureString($badgeText, $badgeFont)
        $bPadX = 26
        $bPadY = 12
        $bW = [int]($badgeSize.Width + $bPadX * 2)
        $bH = [int]($badgeSize.Height + $bPadY * 2)
        $bX = $cardX + $cardW - $bW - 24
        $bY = $cardY + $cardH - $bH - 24

        $bRect = New-Object System.Drawing.Rectangle $bX, $bY, $bW, $bH
        $bPath = Get-RoundedRectanglePath $bRect 18

        # Shadow
        $bsBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(160, 0, 0, 0))
        $bsRect = New-Object System.Drawing.Rectangle ($bX + 4), ($bY + 6), $bW, $bH
        $bsPath = Get-RoundedRectanglePath $bsRect 18
        $g.FillPath($bsBrush, $bsPath)
        $bsPath.Dispose()
        $bsBrush.Dispose()

        # Background gradient
        $bBgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush (
            (New-Object System.Drawing.Point $bX, $bY),
            (New-Object System.Drawing.Point $bX, ($bY + $bH)),
            ([System.Drawing.Color]::FromArgb(245, 25, 30, 45)),
            ([System.Drawing.Color]::FromArgb(245, 12, 15, 24))
        )
        $g.FillPath($bBgBrush, $bPath)
        $bBgBrush.Dispose()

        # Accent border
        $bPen = New-Object System.Drawing.Pen $accentColor, 3
        $g.DrawPath($bPen, $bPath)
        $bPen.Dispose()

        # Badge text
        Draw-3DText -graphics $g -text $badgeText -font $badgeFont -x ($bX + $bPadX) -y ($bY + $bPadY - 2) `
            -gradTop $titleGradTop -gradBottom $titleGradBottom `
            -outlineColor ([System.Drawing.Color]::FromArgb(255, 10, 10, 15)) `
            -shadowColor ([System.Drawing.Color]::FromArgb(160, 0, 0, 0)) `
            -outlineSize 3 -shadowDepth 2

        $bPath.Dispose()
    }

    # 9. Corner Character Medal
    if ($cornerBadgeImage -and (Test-Path $cornerBadgeImage)) {
        $cImg = [System.Drawing.Image]::FromFile($cornerBadgeImage)
        $cSize = 186
        $cX = $cardX - 42
        $cY = $cardY + $cardH - $cSize + 36

        # Circular shadow
        $csBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(180, 0, 0, 0))
        $g.FillEllipse($csBrush, ($cX + 6), ($cY + 10), $cSize, $cSize)
        $csBrush.Dispose()

        # Outer rim
        $goldRimBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush (
            (New-Object System.Drawing.Point $cX, $cY),
            (New-Object System.Drawing.Point ($cX + $cSize), ($cY + $cSize)),
            ([System.Drawing.Color]::FromArgb(255, 255, 220, 100)),
            ([System.Drawing.Color]::FromArgb(255, 180, 120, 20))
        )
        $g.FillEllipse($goldRimBrush, $cX, $cY, $cSize, $cSize)
        $goldRimBrush.Dispose()

        # Inner dark circle
        $rimWidth = 6
        $innerCSize = $cSize - $rimWidth * 2
        $innerCX = $cX + $rimWidth
        $innerCY = $cY + $rimWidth

        $innerBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(255, 15, 18, 25))
        $g.FillEllipse($innerBrush, $innerCX, $innerCY, $innerCSize, $innerCSize)
        $innerBrush.Dispose()

        # Clip inside circle for badge image
        $cClipPath = New-Object System.Drawing.Drawing2D.GraphicsPath
        $cClipPath.AddEllipse($innerCX, $innerCY, $innerCSize, $innerCSize)
        $oldClip2 = $g.Clip
        $g.SetClip($cClipPath)
        $g.DrawImage($cImg, (New-Object System.Drawing.Rectangle $innerCX, $innerCY, $innerCSize, $innerCSize), 0, 0, $cImg.Width, $cImg.Height, [System.Drawing.GraphicsUnit]::Pixel)
        $g.Clip = $oldClip2
        $cClipPath.Dispose()

        # Highlight ring
        $innerPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(150, 255, 255, 255)), 2
        $g.DrawEllipse($innerPen, $innerCX, $innerCY, $innerCSize, $innerCSize)
        $innerPen.Dispose()

        $cImg.Dispose()
    }

    # Save output PNG
    $outDir = [System.IO.Path]::GetDirectoryName($outputPath)
    if (!(Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
    
    $bmp.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)

    $tagFont.Dispose()
    $titleFont.Dispose()
    $subFont.Dispose()
    $badgeFont.Dispose()
    $pfc.Dispose()
    $g.Dispose()
    $bmp.Dispose()

    Write-Host "Generated: $outputPath"
}

# Raw screenshots mapped to storylines
$shotArsenal   = "C:/Users/User/.gemini/antigravity/brain/81cf0b15-7096-4e5b-a118-442de0b53ee3/.user_uploaded/media_1793211441749_0f645b75.png"
$shotDestruct  = "C:/Users/User/.gemini/antigravity/brain/81cf0b15-7096-4e5b-a118-442de0b53ee3/.user_uploaded/media_1793211393889_5edce1e8.png"
$shotSnow      = "C:/Users/User/.gemini/antigravity/brain/81cf0b15-7096-4e5b-a118-442de0b53ee3/.user_uploaded/media_1793211423643_d5b64b14.png"
$shotPhysics   = "C:/Users/User/.gemini/antigravity/brain/81cf0b15-7096-4e5b-a118-442de0b53ee3/.user_uploaded/media_1793211452829_3af40ab7.png"
$shotDuels     = "C:/Users/User/.gemini/antigravity/brain/81cf0b15-7096-4e5b-a118-442de0b53ee3/.user_uploaded/media_1793211405643_f703317d.png"

$iconCommando = "D:/DProjects/Potato-War/main/assets/icon_628x628.png"
$logoHelmet   = "D:/DProjects/Potato-War/main/assets/logo2 (1).png"

# ==================== RUSSIAN SET ====================

# 1. Arsenal
Render-StoreScreenshot `
    -rawScreenshotPath $shotArsenal `
    -outputPath "D:/DProjects/Potato-War/google_play_screenshots/ru/screenshot_1_arsenal.png" `
    -topTag "ТАКТИЧЕСКИЙ ШУТЕР" `
    -titleText "БОЛЬШОЙ ВЫБОР ОРУЖИЯ!" `
    -subtitleText "Гранаты, базуки, ракеты и безумные спецсредства" `
    -badgeText "15+ ВИДОВ ВООРУЖЕНИЯ" `
    -bgGradientTop ([System.Drawing.Color]::FromArgb(255, 34, 14, 8)) `
    -bgGradientBottom ([System.Drawing.Color]::FromArgb(255, 12, 5, 15)) `
    -accentColor ([System.Drawing.Color]::FromArgb(255, 255, 195, 0)) `
    -titleGradTop ([System.Drawing.Color]::FromArgb(255, 255, 240, 130)) `
    -titleGradBottom ([System.Drawing.Color]::FromArgb(255, 255, 150, 0)) `
    -cornerBadgeImage $iconCommando

# 2. Destructible World
Render-StoreScreenshot `
    -rawScreenshotPath $shotDestruct `
    -outputPath "D:/DProjects/Potato-War/google_play_screenshots/ru/screenshot_2_destruction.png" `
    -topTag "ФИЗИКА И ВЗРЫВЫ" `
    -titleText "РАЗРУШАЕМЫЙ МИР!" `
    -subtitleText "Взрывай землю и сбрасывай врагов прямо в лаву" `
    -badgeText "ТОТАЛЬНЫЙ ХАОС" `
    -bgGradientTop ([System.Drawing.Color]::FromArgb(255, 42, 10, 8)) `
    -bgGradientBottom ([System.Drawing.Color]::FromArgb(255, 15, 4, 10)) `
    -accentColor ([System.Drawing.Color]::FromArgb(255, 255, 87, 34)) `
    -titleGradTop ([System.Drawing.Color]::FromArgb(255, 255, 200, 100)) `
    -titleGradBottom ([System.Drawing.Color]::FromArgb(255, 255, 60, 20)) `
    -cornerBadgeImage $logoHelmet

# 3. Snow Biome
Render-StoreScreenshot `
    -rawScreenshotPath $shotSnow `
    -outputPath "D:/DProjects/Potato-War/google_play_screenshots/ru/screenshot_3_biomes.png" `
    -topTag "УНИКАЛЬНЫЕ БИОМЫ" `
    -titleText "СРАЖАЙСЯ НА СНЕЖНЫХ ПИКАХ!" `
    -subtitleText "Используй ветер и чесночные бомбы против врагов" `
    -badgeText "СНЕЖНЫЕ БИТВЫ" `
    -bgGradientTop ([System.Drawing.Color]::FromArgb(255, 10, 26, 44)) `
    -bgGradientBottom ([System.Drawing.Color]::FromArgb(255, 6, 12, 22)) `
    -accentColor ([System.Drawing.Color]::FromArgb(255, 0, 229, 255)) `
    -titleGradTop ([System.Drawing.Color]::FromArgb(255, 200, 245, 255)) `
    -titleGradBottom ([System.Drawing.Color]::FromArgb(255, 0, 185, 255)) `
    -cornerBadgeImage $iconCommando

# 4. Ballistics
Render-StoreScreenshot `
    -rawScreenshotPath $shotPhysics `
    -outputPath "D:/DProjects/Potato-War/google_play_screenshots/ru/screenshot_4_ballistics.png" `
    -topTag "РЕАЛИСТИЧНЫЙ ПОЛЁТ" `
    -titleText "ТОЧНАЯ БАЛЛИСТИКА!" `
    -subtitleText "Учитывай порывы ветра и траекторию выстрела" `
    -badgeText "ТОЧНЫЙ ВЫСТРЕЛ" `
    -bgGradientTop ([System.Drawing.Color]::FromArgb(255, 26, 10, 48)) `
    -bgGradientBottom ([System.Drawing.Color]::FromArgb(255, 10, 4, 20)) `
    -accentColor ([System.Drawing.Color]::FromArgb(255, 204, 255, 0)) `
    -titleGradTop ([System.Drawing.Color]::FromArgb(255, 235, 255, 120)) `
    -titleGradBottom ([System.Drawing.Color]::FromArgb(255, 170, 255, 0)) `
    -cornerBadgeImage $logoHelmet

# 5. Tactical Duels
Render-StoreScreenshot `
    -rawScreenshotPath $shotDuels `
    -outputPath "D:/DProjects/Potato-War/google_play_screenshots/ru/screenshot_5_duels.png" `
    -topTag "ТАКТИЧЕСКИЕ ДУЭЛИ" `
    -titleText "СТАНЬ ГЛАВНЫМ КАРТОХОЙ!" `
    -subtitleText "Побеждай коварных противников в жарких пошаговых боях" `
    -badgeText "ПОШАГОВЫЕ БИТВЫ" `
    -bgGradientTop ([System.Drawing.Color]::FromArgb(255, 32, 10, 42)) `
    -bgGradientBottom ([System.Drawing.Color]::FromArgb(255, 12, 4, 18)) `
    -accentColor ([System.Drawing.Color]::FromArgb(255, 255, 215, 0)) `
    -titleGradTop ([System.Drawing.Color]::FromArgb(255, 255, 240, 130)) `
    -titleGradBottom ([System.Drawing.Color]::FromArgb(255, 255, 160, 0)) `
    -cornerBadgeImage $iconCommando


# ==================== ENGLISH SET ====================

# 1. Arsenal
Render-StoreScreenshot `
    -rawScreenshotPath $shotArsenal `
    -outputPath "D:/DProjects/Potato-War/google_play_screenshots/en/screenshot_1_arsenal.png" `
    -topTag "TACTICAL SHOOTER" `
    -titleText "EPIC WEAPONS ARSENAL!" `
    -subtitleText "Grenades, bazookas, missiles & crazy airstrikes" `
    -badgeText "15+ DEADLY WEAPONS" `
    -bgGradientTop ([System.Drawing.Color]::FromArgb(255, 34, 14, 8)) `
    -bgGradientBottom ([System.Drawing.Color]::FromArgb(255, 12, 5, 15)) `
    -accentColor ([System.Drawing.Color]::FromArgb(255, 255, 195, 0)) `
    -titleGradTop ([System.Drawing.Color]::FromArgb(255, 255, 240, 130)) `
    -titleGradBottom ([System.Drawing.Color]::FromArgb(255, 255, 150, 0)) `
    -cornerBadgeImage $iconCommando

# 2. Destructible World
Render-StoreScreenshot `
    -rawScreenshotPath $shotDestruct `
    -outputPath "D:/DProjects/Potato-War/google_play_screenshots/en/screenshot_2_destruction.png" `
    -topTag "PHYSICS & DESTRUCTION" `
    -titleText "DESTRUCTIBLE TERRAIN!" `
    -subtitleText "Blast craters and drop enemies straight into lava" `
    -badgeText "TOTAL CHAOS" `
    -bgGradientTop ([System.Drawing.Color]::FromArgb(255, 42, 10, 8)) `
    -bgGradientBottom ([System.Drawing.Color]::FromArgb(255, 15, 4, 10)) `
    -accentColor ([System.Drawing.Color]::FromArgb(255, 255, 87, 34)) `
    -titleGradTop ([System.Drawing.Color]::FromArgb(255, 255, 200, 100)) `
    -titleGradBottom ([System.Drawing.Color]::FromArgb(255, 255, 60, 20)) `
    -cornerBadgeImage $logoHelmet

# 3. Snow Biome
Render-StoreScreenshot `
    -rawScreenshotPath $shotSnow `
    -outputPath "D:/DProjects/Potato-War/google_play_screenshots/en/screenshot_3_biomes.png" `
    -topTag "DIVERSE WORLDS" `
    -titleText "BATTLE ACROSS BIOMES!" `
    -subtitleText "Master wind mechanics and deadly garlic bombs" `
    -badgeText "FROST PEAKS" `
    -bgGradientTop ([System.Drawing.Color]::FromArgb(255, 10, 26, 44)) `
    -bgGradientBottom ([System.Drawing.Color]::FromArgb(255, 6, 12, 22)) `
    -accentColor ([System.Drawing.Color]::FromArgb(255, 0, 229, 255)) `
    -titleGradTop ([System.Drawing.Color]::FromArgb(255, 200, 245, 255)) `
    -titleGradBottom ([System.Drawing.Color]::FromArgb(255, 0, 185, 255)) `
    -cornerBadgeImage $iconCommando

# 4. Ballistics
Render-StoreScreenshot `
    -rawScreenshotPath $shotPhysics `
    -outputPath "D:/DProjects/Potato-War/google_play_screenshots/en/screenshot_4_ballistics.png" `
    -topTag "REALISTIC BALLISTICS" `
    -titleText "PRECISION BALLISTICS!" `
    -subtitleText "Calculate wind speed and arc for the perfect hit" `
    -badgeText "BULLSEYE SHOT" `
    -bgGradientTop ([System.Drawing.Color]::FromArgb(255, 26, 10, 48)) `
    -bgGradientBottom ([System.Drawing.Color]::FromArgb(255, 10, 4, 20)) `
    -accentColor ([System.Drawing.Color]::FromArgb(255, 204, 255, 0)) `
    -titleGradTop ([System.Drawing.Color]::FromArgb(255, 235, 255, 120)) `
    -titleGradBottom ([System.Drawing.Color]::FromArgb(255, 170, 255, 0)) `
    -cornerBadgeImage $logoHelmet

# 5. Tactical Duels
Render-StoreScreenshot `
    -rawScreenshotPath $shotDuels `
    -outputPath "D:/DProjects/Potato-War/google_play_screenshots/en/screenshot_5_duels.png" `
    -topTag "TURN-BASED COMBAT" `
    -titleText "BECOME THE SPUD LEGEND!" `
    -subtitleText "Outsmart sneaky enemies in intense tactical duels" `
    -badgeText "TACTICAL DUELS" `
    -bgGradientTop ([System.Drawing.Color]::FromArgb(255, 32, 10, 42)) `
    -bgGradientBottom ([System.Drawing.Color]::FromArgb(255, 12, 4, 18)) `
    -accentColor ([System.Drawing.Color]::FromArgb(255, 255, 215, 0)) `
    -titleGradTop ([System.Drawing.Color]::FromArgb(255, 255, 240, 130)) `
    -titleGradBottom ([System.Drawing.Color]::FromArgb(255, 255, 160, 0)) `
    -cornerBadgeImage $iconCommando

Write-Host "All 10 Google Play screenshots generated successfully!"

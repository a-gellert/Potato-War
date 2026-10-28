Add-Type -AssemblyName System.Drawing

function Get-RoundedRectanglePath {
    param (
        [System.Drawing.Rectangle]$rect,
        [int]$radius
    )
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $diameter = $radius * 2
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

function Render-Screenshot {
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
        [string]$cornerBadgeImage = $null
    )

    $width = 1920
    $height = 1080
    $bmp = New-Object System.Drawing.Bitmap $width, $height
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
    $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit

    # 1. Background Gradient
    $bgBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush (
        (New-Object System.Drawing.Point 0, 0),
        (New-Object System.Drawing.Point 0, $height),
        $bgGradientTop,
        $bgGradientBottom
    )
    $g.FillRectangle($bgBrush, 0, 0, $width, $height)
    $bgBrush.Dispose()

    # 2. Ambient game rays
    $raysPath = "D:\DProjects\Potato-War\main\assets\ui\rays.png"
    if (Test-Path $raysPath) {
        $raysImg = [System.Drawing.Image]::FromFile($raysPath)
        $cm = New-Object System.Drawing.Imaging.ColorMatrix
        $cm.Matrix33 = 0.12 # low opacity
        $ia = New-Object System.Drawing.Imaging.ImageAttributes
        $ia.SetColorMatrix($cm)
        $rayRect = New-Object System.Drawing.Rectangle -200, -200, ($width + 400), ($height + 400)
        $g.DrawImage($raysImg, $rayRect, 0, 0, $raysImg.Width, $raysImg.Height, [System.Drawing.GraphicsUnit]::Pixel, $ia)
        $ia.Dispose()
        $raysImg.Dispose()
    }

    # 3. Ambient blurred game scene
    if (Test-Path $rawScreenshotPath) {
        $rawImg = [System.Drawing.Image]::FromFile($rawScreenshotPath)
        $cm = New-Object System.Drawing.Imaging.ColorMatrix
        $cm.Matrix33 = 0.18 # 18% opacity
        $ia = New-Object System.Drawing.Imaging.ImageAttributes
        $ia.SetColorMatrix($cm)
        $ambRect = New-Object System.Drawing.Rectangle -40, -40, ($width + 80), ($height + 80)
        $g.DrawImage($rawImg, $ambRect, 0, 0, $rawImg.Width, $rawImg.Height, [System.Drawing.GraphicsUnit]::Pixel, $ia)
        $ia.Dispose()
    }

    # Top & bottom darkening vignette
    $topDarkBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush (
        (New-Object System.Drawing.Point 0, 0),
        (New-Object System.Drawing.Point 0, 220),
        ([System.Drawing.Color]::FromArgb(230, 8, 8, 14)),
        ([System.Drawing.Color]::FromArgb(0, 8, 8, 14))
    )
    $g.FillRectangle($topDarkBrush, 0, 0, $width, 220)
    $topDarkBrush.Dispose()

    $botDarkBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush (
        (New-Object System.Drawing.Point 0, ($height - 200)),
        (New-Object System.Drawing.Point 0, $height),
        ([System.Drawing.Color]::FromArgb(0, 8, 8, 14)),
        ([System.Drawing.Color]::FromArgb(240, 8, 8, 14))
    )
    $g.FillRectangle($botDarkBrush, 0, ($height - 200), $width, 200)
    $botDarkBrush.Dispose()

    # 4. Device Bezel & Screenshot Card
    # Dimensions: 1560 x 720
    $cardW = 1580
    $cardH = 728
    $cardX = [int](($width - $cardW) / 2)
    $cardY = 245
    $bezelRadius = 24

    # Multiple shadow layers for depth
    for ($s = 20; $s -ge 2; $s -= 3) {
        $sAlpha = [int](80 / ($s * 0.4 + 1))
        $sBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb($sAlpha, 0, 0, 0))
        $sPath = Get-RoundedRectanglePath (New-Object System.Drawing.Rectangle ($cardX - $s), ($cardY - $s + 14), ($cardW + $s*2), ($cardH + $s*2)) ($bezelRadius + $s)
        $g.FillPath($sBrush, $sPath)
        $sPath.Dispose()
        $sBrush.Dispose()
    }

    # Outer Bezel
    $bezelRect = New-Object System.Drawing.Rectangle $cardX, $cardY, $cardW, $cardH
    $bezelPath = Get-RoundedRectanglePath $bezelRect $bezelRadius
    
    $bezelBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush (
        (New-Object System.Drawing.Point $cardX, $cardY),
        (New-Object System.Drawing.Point $cardX, ($cardY + $cardH)),
        ([System.Drawing.Color]::FromArgb(255, 36, 40, 52)),
        ([System.Drawing.Color]::FromArgb(255, 16, 18, 26))
    )
    $g.FillPath($bezelBrush, $bezelPath)
    $bezelBrush.Dispose()

    # Bezel outer glow / border
    $glowPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(180, $accentColor), 4)
    $g.DrawPath($glowPen, $bezelPath)
    $glowPen.Dispose()

    # Screen viewport inside bezel (inset by 8px)
    $inset = 8
    $screenRect = New-Object System.Drawing.Rectangle ($cardX + $inset), ($cardY + $inset), ($cardW - $inset*2), ($cardH - $inset*2)
    $screenRadius = [Math]::Max(4, ($bezelRadius - $inset))
    $screenPath = Get-RoundedRectanglePath $screenRect $screenRadius

    # Clip to screen viewport and draw screenshot
    $oldClip = $g.Clip
    $g.SetClip($screenPath)
    if ($rawImg) {
        $g.DrawImage($rawImg, $screenRect, 0, 0, $rawImg.Width, $rawImg.Height, [System.Drawing.GraphicsUnit]::Pixel)
    }
    
    # Subtle glossy diagonal glare across the screen
    $glareBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush (
        (New-Object System.Drawing.Point $screenRect.X, $screenRect.Y),
        (New-Object System.Drawing.Point ($screenRect.Right), ($screenRect.Bottom)),
        ([System.Drawing.Color]::FromArgb(35, 255, 255, 255)),
        ([System.Drawing.Color]::FromArgb(0, 255, 255, 255))
    )
    $g.FillRectangle($glareBrush, $screenRect)
    $glareBrush.Dispose()

    # Restore clip
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
    $badgeFont = New-Object System.Drawing.Font ($blackFam, [float]22, [System.Drawing.FontStyle]::Bold)

    # Helper function for rendering high-impact 3D comic text
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

        # 1. 3D shadow layers (offset diagonally down-right)
        $sBrush = New-Object System.Drawing.SolidBrush $shadowColor
        for ($d = 1; $d -le $shadowDepth; $d++) {
            for ($ox = -$outlineSize; $ox -le $outlineSize; $ox += 2) {
                for ($oy = -$outlineSize; $oy -le $outlineSize; $oy += 2) {
                    $graphics.DrawString($text, $font, $sBrush, [float]($x + $ox + $d), [float]($y + $oy + $d))
                }
            }
        }
        $sBrush.Dispose()

        # 2. Strong outline
        $oBrush = New-Object System.Drawing.SolidBrush $outlineColor
        for ($ox = -$outlineSize; $ox -le $outlineSize; $ox += 1) {
            for ($oy = -$outlineSize; $oy -le $outlineSize; $oy += 1) {
                if ($ox*$ox + $oy*$oy -le $outlineSize*$outlineSize) {
                    $graphics.DrawString($text, $font, $oBrush, [float]($x + $ox), [float]($y + $oy))
                }
            }
        }
        $oBrush.Dispose()

        # 3. Main gradient fill
        $size = $graphics.MeasureString($text, $font)
        $fBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush (
            (New-Object System.Drawing.PointF $x, $y),
            (New-Object System.Drawing.PointF $x, ($y + $size.Height)),
            $gradTop,
            $gradBottom
        )
        $graphics.DrawString($text, $font, $fBrush, [float]$x, [float]$y)
        $fBrush.Dispose()
    }

    # 6. Render Top Tag Pill
    if ($topTag) {
        $tagSize = $g.MeasureString($topTag, $tagFont)
        $tagPadX = 18
        $tagPadY = 6
        $tagW = [int]($tagSize.Width + $tagPadX * 2)
        $tagH = [int]($tagSize.Height + $tagPadY * 2)
        $tagX = [int](($width - $tagW) / 2)
        $tagY = 22

        $tagRect = New-Object System.Drawing.Rectangle $tagX, $tagY, $tagW, $tagH
        $tagPath = Get-RoundedRectanglePath $tagRect 14

        $tagBgBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(210, 15, 20, 32))
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

    # 7. Render Title & Subtitle
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

    # Draw Subtitle with crisp contrast
    $subOutline = [System.Drawing.Color]::FromArgb(255, 10, 12, 18)
    $subFill = [System.Drawing.Color]::FromArgb(255, 245, 248, 255)
    Draw-3DText -graphics $g -text $subtitleText -font $subFont -x $subX -y $subY `
        -gradTop $subFill -gradBottom ([System.Drawing.Color]::FromArgb(255, 215, 225, 240)) `
        -outlineColor $subOutline -shadowColor ([System.Drawing.Color]::FromArgb(180, 0, 0, 0)) `
        -outlineSize 3 -shadowDepth 3

    # 8. Render Bottom Badge
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

    # 9. Corner Badge / Character Medal
    if ($cornerBadgeImage -and (Test-Path $cornerBadgeImage)) {
        $cImg = [System.Drawing.Image]::FromFile($cornerBadgeImage)
        $cSize = 190
        $cX = $cardX - 45
        $cY = $cardY + $cardH - $cSize + 40

        # Circular shadow
        $csBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(180, 0, 0, 0))
        $g.FillEllipse($csBrush, ($cX + 6), ($cY + 10), $cSize, $cSize)
        $csBrush.Dispose()

        # Outer gold rim
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

    # Save PNG
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

# Test on Screenshot 1
Render-Screenshot `
    -rawScreenshotPath "C:/Users/User/.gemini/antigravity/brain/81cf0b15-7096-4e5b-a118-442de0b53ee3/.user_uploaded/media_1793211441749_0f645b75.png" `
    -outputPath "D:/DProjects/Potato-War/scratch/test_pro_1.png" `
    -topTag "ТАКТИЧЕСКИЙ ШУТЕР" `
    -titleText "БОЛЬШОЙ ВЫБОР ОРУЖИЯ!" `
    -subtitleText "Гранаты, базуки, ракеты и безумный арсенал" `
    -badgeText "ВЫБИРАЙ ТАКТИКУ" `
    -bgGradientTop ([System.Drawing.Color]::FromArgb(255, 28, 12, 8)) `
    -bgGradientBottom ([System.Drawing.Color]::FromArgb(255, 10, 5, 12)) `
    -accentColor ([System.Drawing.Color]::FromArgb(255, 255, 195, 0)) `
    -titleGradTop ([System.Drawing.Color]::FromArgb(255, 255, 235, 120)) `
    -titleGradBottom ([System.Drawing.Color]::FromArgb(255, 255, 150, 0)) `
    -cornerBadgeImage "D:/DProjects/Potato-War/main/assets/icon_628x628.png"

# Prototype for Google Play Screenshot Generator
Add-Type -AssemblyName System.Drawing

function Create-StyledScreenshot {
    param (
        [string]$screenshotPath,
        [string]$outputPath,
        [string]$title,
        [string]$subtitle,
        [string]$badgeText,
        [System.Drawing.Color]$themeColor1,
        [System.Drawing.Color]$themeColor2,
        [System.Drawing.Color]$accentColor,
        [string]$popoutAssetPath,
        [int]$popoutX,
        [int]$popoutY,
        [int]$popoutScale
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
        $themeColor1,
        $themeColor2
    )
    $g.FillRectangle($bgBrush, 0, 0, $width, $height)
    $bgBrush.Dispose()

    # 2. Draw blurred/dimmed game background underlay
    if (Test-Path $screenshotPath) {
        $rawShot = [System.Drawing.Image]::FromFile($screenshotPath)
        
        # Draw stretched dimmed screenshot in background for ambient lighting
        $ambientRect = New-Object System.Drawing.Rectangle -50, -50, ($width + 100), ($height + 100)
        $colorMatrix = New-Object System.Drawing.Imaging.ColorMatrix
        $colorMatrix.Matrix33 = 0.22 # 22% opacity
        $imgAttr = New-Object System.Drawing.Imaging.ImageAttributes
        $imgAttr.SetColorMatrix($colorMatrix)
        
        $g.DrawImage($rawShot, $ambientRect, 0, 0, $rawShot.Width, $rawShot.Height, [System.Drawing.GraphicsUnit]::Pixel, $imgAttr)
        $imgAttr.Dispose()

        # Dark overlay on background for readability
        $overlayBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(140, 5, 5, 10))
        $g.FillRectangle($overlayBrush, 0, 0, $width, $height)
        $overlayBrush.Dispose()

        # 3. Main Gameplay Card Frame
        # Target size for screenshot: width 1560, height 720 (approx 2.167 ratio)
        $cardW = 1580
        $cardH = 728
        $cardX = [int](($width - $cardW) / 2)
        $cardY = 240

        # Card shadow
        for ($i = 15; $i -ge 1; $i -= 3) {
            $shadowAlpha = [int](60 / ($i + 1))
            $shadowBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb($shadowAlpha, 0, 0, 0))
            $g.FillRectangle($shadowBrush, ($cardX - $i), ($cardY - $i + 10), ($cardW + $i * 2), ($cardH + $i * 2))
            $shadowBrush.Dispose()
        }

        # Card Border glow
        $glowPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(180, $accentColor), 6)
        $g.DrawRectangle($glowPen, ($cardX - 3), ($cardY - 3), ($cardW + 6), ($cardH + 6))
        $glowPen.Dispose()

        $innerPen = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(255, 255, 255, 255), 2)
        $g.DrawRectangle($innerPen, ($cardX - 1), ($cardY - 1), ($cardW + 2), ($cardH + 2))
        $innerPen.Dispose()

        # Draw the screenshot crisp and centered
        $cardRect = New-Object System.Drawing.Rectangle $cardX, $cardY, $cardW, $cardH
        $g.DrawImage($rawShot, $cardRect, 0, 0, $rawShot.Width, $rawShot.Height, [System.Drawing.GraphicsUnit]::Pixel)

        $rawShot.Dispose()
    }

    # 4. Fonts
    $pfc = New-Object System.Drawing.Text.PrivateFontCollection
    $pfc.AddFontFile("D:\DProjects\Potato-War\main\assets\fonts\Rubik-Black.ttf")
    $fontFam = $pfc.Families[0]
    $titleFont = New-Object System.Drawing.Font ($fontFam, [float]54, [System.Drawing.FontStyle]::Bold)
    $subFont = New-Object System.Drawing.Font ($fontFam, [float]26, [System.Drawing.FontStyle]::Regular)
    $badgeFont = New-Object System.Drawing.Font ($fontFam, [float]22, [System.Drawing.FontStyle]::Bold)

    # Helper for drawing outlined text
    function Draw-OutlinedText {
        param (
            $graphics,
            $text,
            $font,
            $x,
            $y,
            $fillColor,
            $outlineColor,
            $outlineWidth = 5
        )
        $outBrush = New-Object System.Drawing.SolidBrush $outlineColor
        for ($dx = -$outlineWidth; $dx -le $outlineWidth; $dx += 2) {
            for ($dy = -$outlineWidth; $dy -le $outlineWidth; $dy += 2) {
                if ($dx*$dx + $dy*$dy -le $outlineWidth*$outlineWidth) {
                    $graphics.DrawString($text, $font, $outBrush, [float]($x + $dx), [float]($y + $dy))
                }
            }
        }
        $outBrush.Dispose()
        $inBrush = New-Object System.Drawing.SolidBrush $fillColor
        $graphics.DrawString($text, $font, $inBrush, [float]$x, [float]$y)
        $inBrush.Dispose()
    }

    # Measure Title and Subtitle to center them
    $titleSize = $g.MeasureString($title, $titleFont)
    $titleX = [int](($width - $titleSize.Width) / 2)
    $titleY = 50

    $subSize = $g.MeasureString($subtitle, $subFont)
    $subX = [int](($width - $subSize.Width) / 2)
    $subY = 145

    # Draw Title with bold yellow/gold fill and black outline
    Draw-OutlinedText -graphics $g -text $title -font $titleFont -x $titleX -y $titleY -fillColor ([System.Drawing.Color]::FromArgb(255, 255, 215, 0)) -outlineColor ([System.Drawing.Color]::FromArgb(255, 10, 10, 15)) -outlineWidth 6

    # Draw Subtitle with crisp white/light yellow and soft outline
    Draw-OutlinedText -graphics $g -text $subtitle -font $subFont -x $subX -y $subY -fillColor ([System.Drawing.Color]::FromArgb(255, 240, 245, 255)) -outlineColor ([System.Drawing.Color]::FromArgb(230, 10, 10, 15)) -outlineWidth 3

    # 5. Badge in bottom corner
    if ($badgeText) {
        $badgeSize = $g.MeasureString($badgeText, $badgeFont)
        $badgePadX = 28
        $badgePadY = 12
        $badgeW = [int]($badgeSize.Width + $badgePadX * 2)
        $badgeH = [int]($badgeSize.Height + $badgePadY * 2)
        $badgeX = $cardX + $cardW - $badgeW - 25
        $badgeY = $cardY + $cardH - $badgeH - 25

        # Badge shadow
        $bShadowBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(160, 0, 0, 0))
        $g.FillRectangle($bShadowBrush, ($badgeX + 4), ($badgeY + 4), $badgeW, $badgeH)
        $bShadowBrush.Dispose()

        # Badge background
        $badgeBg = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(235, 18, 22, 32))
        $g.FillRectangle($badgeBg, $badgeX, $badgeY, $badgeW, $badgeH)
        $badgeBg.Dispose()

        # Badge border
        $badgePen = New-Object System.Drawing.Pen $accentColor, 3
        $g.DrawRectangle($badgePen, $badgeX, $badgeY, $badgeW, $badgeH)
        $badgePen.Dispose()

        # Badge text
        Draw-OutlinedText -graphics $g -text $badgeText -font $badgeFont -x ($badgeX + $badgePadX) -y ($badgeY + $badgePadY - 2) -fillColor $accentColor -outlineColor ([System.Drawing.Color]::Black) -outlineWidth 2
    }

    # 6. Popout asset
    if ($popoutAssetPath -and (Test-Path $popoutAssetPath)) {
        $popImg = [System.Drawing.Image]::FromFile($popoutAssetPath)
        $popW = [int]($popImg.Width * $popoutScale)
        $popH = [int]($popImg.Height * $popoutScale)

        # Popout shadow
        $pShadowBrush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(140, 0, 0, 0))
        $g.FillEllipse($pShadowBrush, ($popoutX + 10), ($popoutY + $popH - 20), ($popW - 20), 30)
        $pShadowBrush.Dispose()

        $g.DrawImage($popImg, $popoutX, $popoutY, $popW, $popH)
        $popImg.Dispose()
    }

    # Save output
    $outDir = [System.IO.Path]::GetDirectoryName($outputPath)
    if (!(Test-Path $outDir)) { New-Item -ItemType Directory -Path $outDir -Force | Out-Null }
    
    $bmp.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)

    $titleFont.Dispose()
    $subFont.Dispose()
    $badgeFont.Dispose()
    $pfc.Dispose()
    $g.Dispose()
    $bmp.Dispose()
    Write-Host "Created screenshot: $outputPath"
}

# Run prototype test
Create-StyledScreenshot `
    -screenshotPath "C:/Users/User/.gemini/antigravity/brain/81cf0b15-7096-4e5b-a118-442de0b53ee3/.user_uploaded/media_1793211441749_0f645b75.png" `
    -outputPath "D:/DProjects/Potato-War/scratch/preview_shot1.png" `
    -title "БОЛЬШОЙ ВЫБОР ОРУЖИЯ!" `
    -subtitle "Гранаты, базуки, ракеты и безумные спецсредства" `
    -badgeText "ВЫБИРАЙ ТАКТИКУ!" `
    -themeColor1 ([System.Drawing.Color]::FromArgb(255, 30, 10, 5)) `
    -themeColor2 ([System.Drawing.Color]::FromArgb(255, 12, 6, 18)) `
    -accentColor ([System.Drawing.Color]::FromArgb(255, 255, 180, 0)) `
    -popoutAssetPath "D:/DProjects/Potato-War/main/assets/potato/assault.png" `
    -popoutX 110 `
    -popoutY 760 `
    -popoutScale 2

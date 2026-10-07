Add-Type -AssemblyName System.Drawing

function Rotate-Image($inputPath, $outputPath, $angleDegrees, $targetW, $targetH) {
    $src = [System.Drawing.Bitmap]::FromFile($inputPath)
    
    # Create larger canvas to rotate without clipping
    $maxDim = [Math]::Max($src.Width, $src.Height) * 2
    $temp = [System.Drawing.Bitmap]::new($maxDim, $maxDim, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $g = [System.Drawing.Graphics]::FromImage($temp)
    $g.Clear([System.Drawing.Color]::Transparent)
    $g.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    
    # Translate to center, rotate, translate back
    $g.TranslateTransform($maxDim / 2, $maxDim / 2)
    $g.RotateTransform($angleDegrees)
    $g.TranslateTransform(-($maxDim / 2), -($maxDim / 2))
    
    $drawX = ($maxDim - $src.Width) / 2
    $drawY = ($maxDim - $src.Height) / 2
    $g.DrawImage($src, $drawX, $drawY)
    $g.Dispose()
    $src.Dispose()
    
    # Find bounding box of non-transparent pixels
    $minX = $maxDim; $maxX = 0; $minY = $maxDim; $maxY = 0
    for ($y = 0; $y -lt $maxDim; $y++) {
        for ($x = 0; $x -lt $maxDim; $x++) {
            if ($temp.GetPixel($x, $y).A -gt 20) {
                if ($x -lt $minX) { $minX = $x }
                if ($x -gt $maxX) { $maxX = $x }
                if ($y -lt $minY) { $minY = $y }
                if ($y -gt $maxY) { $maxY = $y }
            }
        }
    }
    
    $cropW = [Math]::Max(1, $maxX - $minX + 1)
    $cropH = [Math]::Max(1, $maxY - $minY + 1)
    
    # Scale to target
    $finalBmp = [System.Drawing.Bitmap]::new($targetW, $targetH, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $gFinal = [System.Drawing.Graphics]::FromImage($finalBmp)
    $gFinal.Clear([System.Drawing.Color]::Transparent)
    $gFinal.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
    $gFinal.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
    
    $pad = 1
    $scale = [Math]::Min(($targetW - $pad * 2) / $cropW, ($targetH - $pad * 2) / $cropH)
    $dW = [int][Math]::Round($cropW * $scale)
    $dH = [int][Math]::Round($cropH * $scale)
    $destX = [int](($targetW - $dW) / 2)
    $destY = [int](($targetH - $dH) / 2)
    
    $gFinal.DrawImage($temp, [System.Drawing.Rectangle]::new($destX, $destY, $dW, $dH), [System.Drawing.Rectangle]::new($minX, $minY, $cropW, $cropH), [System.Drawing.GraphicsUnit]::Pixel)
    $gFinal.Dispose()
    $temp.Dispose()
    
    $finalBmp.Save($outputPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $finalBmp.Dispose()
    Write-Output "Rotated $inputPath by $angleDegrees to $outputPath ($targetW x $targetH)"
}

# Test rotation of drill_missile from tactical set
# The drill was angled pointing down-left at approx 135 deg or -135 deg.
# Let's find the exact angle to make it point right (0 deg):
# If tip is down-left, rotating by +135 deg should bring it to horizontal right!
Rotate-Image "d:\DProjects\Potato-War\main\assets\drill_missile.png" "d:\DProjects\Potato-War\scratch\drill_rot135.png" 135 40 20
Rotate-Image "d:\DProjects\Potato-War\main\assets\drill_missile.png" "d:\DProjects\Potato-War\scratch\drill_rot_neg135.png" -135 40 20

# For air bomb: nose was pointing down-left (approx -135 or 135 deg)
Rotate-Image "d:\DProjects\Potato-War\main\assets\air_bomb.png" "d:\DProjects\Potato-War\scratch\bomb_rot135.png" 135 38 24
Rotate-Image "d:\DProjects\Potato-War\main\assets\air_bomb.png" "d:\DProjects\Potato-War\scratch\bomb_rot_neg135.png" -135 38 24

# For masher bazooka: was angled pointing up-right (~60 deg)
# Rotating by -60 deg should make it horizontal pointing right!
Rotate-Image "d:\DProjects\Potato-War\main\assets\masher_bazooka.png" "d:\DProjects\Potato-War\scratch\bazooka_rot_neg55.png" -55 48 24

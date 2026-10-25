Add-Type -AssemblyName System.Drawing
$bmp = [System.Drawing.Bitmap]::FromFile("C:/Users/User/.gemini/antigravity/brain/1aed803c-56a8-4d3f-82c6-517eadaf5717/.user_uploaded/media_1792821332235_e57c027d.png")

# Find clusters of white pixels (R > 250, G > 250, B > 250) in bottom-left quadrant (x < 350, y > 250)
$whitePixels = @()
for ($y = 250; $y -lt $bmp.Height; $y += 2) {
    for ($x = 0; $x -lt 350; $x += 2) {
        $p = $bmp.GetPixel($x, $y)
        if ($p.R -ge 245 -and $p.G -ge 245 -and $p.B -ge 245) {
            $whitePixels += [PSCustomObject]@{ X = $x; Y = $y; R = $p.R; G = $p.G; B = $p.B }
        }
    }
}

Write-Host "Total white pixels sampled: $($whitePixels.Count)"

# Group pixels into bounding boxes
# Print min and max of clusters
$clusters = @()
foreach ($p in $whitePixels) {
    Write-Host "White pixel at ($($p.X), $($p.Y))"
}

$bmp.Dispose()

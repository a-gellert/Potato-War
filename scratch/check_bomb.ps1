Add-Type -AssemblyName System.Drawing

$bmp = [System.Drawing.Bitmap]::FromFile("d:\DProjects\Potato-War\scratch\bomb_rot_neg135.png")
# Check nose vs fins. Fins have fins protruding above/below.
# Let's count vertical span at x=5 vs x=30.
$minYLeft = 100; $maxYLeft = 0; $minYRight = 100; $maxYRight = 0
for ($y = 0; $y -lt $bmp.Height; $y++) {
    if ($bmp.GetPixel(5, $y).A -gt 20) {
        if ($y -lt $minYLeft) { $minYLeft = $y }
        if ($y -gt $maxYLeft) { $maxYLeft = $y }
    }
    if ($bmp.GetPixel(30, $y).A -gt 20) {
        if ($y -lt $minYRight) { $minYRight = $y }
        if ($y -gt $maxYRight) { $maxYRight = $y }
    }
}
Write-Output "Left vertical span (fins): $($maxYLeft - $minYLeft), Right vertical span (nose): $($maxYRight - $minYRight)"
$bmp.Dispose()

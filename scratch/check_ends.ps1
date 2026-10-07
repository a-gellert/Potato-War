Add-Type -AssemblyName System.Drawing

$bmp = [System.Drawing.Bitmap]::FromFile("d:\DProjects\Potato-War\scratch\drill_rot_neg135.png")
Write-Output "drill_rot_neg135 width=$($bmp.Width), height=$($bmp.Height)"
# Check leftmost 10 columns vs rightmost 10 columns
$leftCol = 0; $rightCol = 0
for ($y = 0; $y -lt $bmp.Height; $y++) {
    for ($x = 0; $x -lt 10; $x++) { if ($bmp.GetPixel($x, $y).A -gt 20) { $leftCol++ } }
    for ($x = $bmp.Width - 10; $x -lt $bmp.Width; $x++) { if ($bmp.GetPixel($x, $y).A -gt 20) { $rightCol++ } }
}
Write-Output "Left pixels: $leftCol, Right pixels: $rightCol"

# Sample color on left vs right:
# The fins are red (R > 180, G < 80, B < 80). The drill tip is silver/gray (R~G~B).
$redLeft = 0; $redRight = 0
for ($y = 0; $y -lt $bmp.Height; $y++) {
    for ($x = 0; $x -lt 15; $x++) {
        $p = $bmp.GetPixel($x, $y)
        if ($p.R -gt 150 -and $p.G -lt 80) { $redLeft++ }
    }
    for ($x = $bmp.Width - 15; $x -lt $bmp.Width; $x++) {
        $p = $bmp.GetPixel($x, $y)
        if ($p.R -gt 150 -and $p.G -lt 80) { $redRight++ }
    }
}
Write-Output "Red fins on left: $redLeft, Red fins on right: $redRight"
$bmp.Dispose()

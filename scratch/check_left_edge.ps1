Add-Type -AssemblyName System.Drawing
$bmp = New-Object System.Drawing.Bitmap('C:\Users\User\.gemini\antigravity\brain\1aed803c-56a8-4d3f-82c6-517eadaf5717\.user_uploaded\media_1792821332235_e57c027d.png')

# Dump all lines on the left edge (X: 0..8)
for ($y = 0; $y -lt $bmp.Height; $y += 6) {
    $hasPixel = $false
    for ($x = 0; $x -lt 6; $x++) {
        $c = $bmp.GetPixel($x, $y)
        if ($c.R -gt 150 -or $c.G -gt 150 -or $c.B -gt 150) {
            $hasPixel = $true
            break
        }
    }
    if ($hasPixel) {
        $c0 = $bmp.GetPixel(0, $y)
        $c2 = $bmp.GetPixel(2, $y)
        Write-Host ("Y={0:D3}: (0) R={1} G={2} B={3} | (2) R={4} G={5} B={6}" -f $y, $c0.R, $c0.G, $c0.B, $c2.R, $c2.G, $c2.B)
    }
}
$bmp.Dispose()

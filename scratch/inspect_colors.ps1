Add-Type -AssemblyName System.Drawing
$bmp = New-Object System.Drawing.Bitmap('C:\Users\User\.gemini\antigravity\brain\1aed803c-56a8-4d3f-82c6-517eadaf5717\.user_uploaded\media_1792821332235_e57c027d.png')
for ($y = 450; $y -lt 500; $y += 2) {
    for ($x = 0; $x -lt 80; $x += 2) {
        $c = $bmp.GetPixel($x, $y)
        if ($c.R -gt 100 -or $c.G -gt 100 -or $c.B -gt 100) {
            Write-Host "($x, $y): R=$($c.R), G=$($c.G), B=$($c.B)"
        }
    }
}
$bmp.Dispose()

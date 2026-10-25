Add-Type -AssemblyName System.Drawing
$bmp = New-Object System.Drawing.Bitmap('C:\Users\User\.gemini\antigravity\brain\1aed803c-56a8-4d3f-82c6-517eadaf5717\.user_uploaded\media_1792821332235_e57c027d.png')
for ($y = 400; $y -lt 462; $y += 4) {
    $c = $bmp.GetPixel(30, $y)
    Write-Host "Y=$y : R=$($c.R), G=$($c.G), B=$($c.B)"
}
$bmp.Dispose()

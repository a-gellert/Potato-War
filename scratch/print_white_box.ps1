Add-Type -AssemblyName System.Drawing
$bmp = New-Object System.Drawing.Bitmap('C:\Users\User\.gemini\antigravity\brain\1aed803c-56a8-4d3f-82c6-517eadaf5717\.user_uploaded\media_1792821332235_e57c027d.png')

for ($y = 458; $y -le 480; $y++) {
    $row = ""
    for ($x = 8; $x -le 70; $x++) {
        $c = $bmp.GetPixel($x, $y)
        if ($c.R -gt 240 -and $c.G -gt 240 -and $c.B -gt 240) {
            $row += "#"
        } elseif ($c.R -gt 200 -and $c.G -gt 200 -and $c.B -gt 200) {
            $row += "="
        } elseif ($c.R -gt 100 -or $c.G -gt 100 -or $c.B -gt 100) {
            $row += "."
        } else {
            $row += " "
        }
    }
    Write-Host ("{0:D3}: {1}" -f $y, $row)
}
$bmp.Dispose()

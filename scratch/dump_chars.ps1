Add-Type -AssemblyName System.Drawing
$bmp = New-Object System.Drawing.Bitmap('C:\Users\User\.gemini\antigravity\brain\1aed803c-56a8-4d3f-82c6-517eadaf5717\.user_uploaded\media_1792821332235_e57c027d.png')
for ($y = 430; $y -lt 495; $y++) {
    $line = ""
    for ($x = 0; $x -lt 70; $x++) {
        $c = $bmp.GetPixel($x, $y)
        # Check if bright pixel (text or white box)
        if ($c.R -gt 230 -and $c.G -gt 230 -and $c.B -gt 230) {
            $line += "W"
        } elseif ($c.G -gt 150 -and $c.B -gt 150 -and $c.R -lt 100) {
            $line += "C" # cyan
        } elseif ($c.R -gt 120 -or $c.G -gt 120 -or $c.B -gt 120) {
            $line += "."
        } else {
            $line += " "
        }
    }
    if ($line.Trim() -ne "") {
        Write-Host ("{0:D3}: {1}" -f $y, $line)
    }
}
$bmp.Dispose()

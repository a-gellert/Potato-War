Add-Type -AssemblyName System.Drawing
$bmp = New-Object System.Drawing.Bitmap('C:\Users\User\.gemini\antigravity\brain\1aed803c-56a8-4d3f-82c6-517eadaf5717\.user_uploaded\media_1792821332235_e57c027d.png')
for ($y = 440; $y -lt 500; $y += 2) {
    $line = ''
    for ($x = 0; $x -lt 80; $x += 2) {
        $c = $bmp.GetPixel($x, $y)
        if ($c.R -gt 240 -and $c.G -gt 240 -and $c.B -gt 240) {
            $line += '#'
        } elseif ($c.R -gt 150) {
            $line += '+'
        } elseif ($c.R -gt 50) {
            $line += '.'
        } else {
            $line += ' '
        }
    }
    Write-Host ($y.ToString() + ': ' + $line)
}
$bmp.Dispose()

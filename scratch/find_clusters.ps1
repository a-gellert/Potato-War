
Add-Type -AssemblyName System.Drawing
$bmp = New-Object System.Drawing.Bitmap('C:\Users\User\.gemini\antigravity\brain\1aed803c-56a8-4d3f-82c6-517eadaf5717\.user_uploaded\media_1792821332235_e57c027d.png')

$w = $bmp.Width
$h = $bmp.Height

# Simple grid scan by 10x10 blocks
for ($by = 0; $by -lt $h; $by += 10) {
    for ($bx = 0; $bx -lt $w; $bx += 10) {
        $whiteCount = 0
        for ($dy = 0; $dy -lt 10 -and ($by + $dy) -lt $h; $dy++) {
            for ($dx = 0; $dx -lt 10 -and ($bx + $dx) -lt $w; $dx++) {
                $c = $bmp.GetPixel($bx + $dx, $by + $dy)
                if ($c.R -gt 240 -and $c.G -gt 240 -and $c.B -gt 240) {
                    $whiteCount++
                }
            }
        }
        if ($whiteCount -gt 5) {
            Write-Host "White cluster at block ($bx, $by) count=$whiteCount"
        }
    }
}
$bmp.Dispose()

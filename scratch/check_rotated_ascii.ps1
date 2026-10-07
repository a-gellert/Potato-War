Add-Type -AssemblyName System.Drawing

function Show-Ascii($path) {
    $bmp = [System.Drawing.Bitmap]::FromFile($path)
    Write-Output "=== $path ($($bmp.Width)x$($bmp.Height)) ==="
    for ($y = 0; $y -lt $bmp.Height; $y += 2) {
        $line = ""
        for ($x = 0; $x -lt $bmp.Width; $x++) {
            $p = $bmp.GetPixel($x, $y)
            $line += if ($p.A -gt 50) { "#" } else { " " }
        }
        Write-Output $line
    }
    $bmp.Dispose()
}

Show-Ascii "d:\DProjects\Potato-War\scratch\drill_rot135.png"
Show-Ascii "d:\DProjects\Potato-War\scratch\drill_rot_neg135.png"
Show-Ascii "d:\DProjects\Potato-War\scratch\bomb_rot135.png"
Show-Ascii "d:\DProjects\Potato-War\scratch\bomb_rot_neg135.png"
Show-Ascii "d:\DProjects\Potato-War\scratch\bazooka_rot_neg55.png"

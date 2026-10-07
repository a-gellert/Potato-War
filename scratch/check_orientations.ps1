Add-Type -AssemblyName System.Drawing

function Show-Ascii($name) {
    $bmp = [System.Drawing.Bitmap]::FromFile("d:\DProjects\Potato-War\main\assets\$name")
    Write-Output "=== $name ($($bmp.Width)x$($bmp.Height)) ==="
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

Show-Ascii "potato_base.png"




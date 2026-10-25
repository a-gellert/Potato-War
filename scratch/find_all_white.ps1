Add-Type -AssemblyName System.Drawing
$bmp = New-Object System.Drawing.Bitmap('C:\Users\User\.gemini\antigravity\brain\1aed803c-56a8-4d3f-82c6-517eadaf5717\.user_uploaded\media_1792821332235_e57c027d.png')

$whiteMap = New-Object 'int[,]' $bmp.Width, $bmp.Height
for ($y = 0; $y -lt $bmp.Height; $y++) {
    for ($x = 0; $x -lt $bmp.Width; $x++) {
        $c = $bmp.GetPixel($x, $y)
        if ($c.R -gt 240 -and $c.G -gt 240 -and $c.B -gt 240) {
            $whiteMap[$x, $y] = 1
        }
    }
}

# Flood fill / connected components
$visited = New-Object 'bool[,]' $bmp.Width, $bmp.Height
$components = @()

for ($y = 0; $y -lt $bmp.Height; $y++) {
    for ($x = 0; $x -lt $bmp.Width; $x++) {
        if ($whiteMap[$x, $y] -eq 1 -and -not $visited[$x, $y]) {
            # Start flood fill
            $q = New-Object System.Collections.Generic.Queue[System.Drawing.Point]
            $q.Enqueue((New-Object System.Drawing.Point($x, $y)))
            $visited[$x, $y] = $true
            $count = 0
            $minX = $x; $maxX = $x; $minY = $y; $maxY = $y
            
            while ($q.Count -gt 0) {
                $pt = $q.Dequeue()
                $count++
                if ($pt.X -lt $minX) { $minX = $pt.X }
                if ($pt.X -gt $maxX) { $maxX = $pt.X }
                if ($pt.Y -lt $minY) { $minY = $pt.Y }
                if ($pt.Y -gt $maxY) { $maxY = $pt.Y }
                
                $neighbors = @(
                    (New-Object System.Drawing.Point($pt.X+1, $pt.Y)),
                    (New-Object System.Drawing.Point($pt.X-1, $pt.Y)),
                    (New-Object System.Drawing.Point($pt.X, $pt.Y+1)),
                    (New-Object System.Drawing.Point($pt.X, $pt.Y-1))
                )
                foreach ($n in $neighbors) {
                    if ($n.X -ge 0 -and $n.X -lt $bmp.Width -and $n.Y -ge 0 -and $n.Y -lt $bmp.Height) {
                        if ($whiteMap[$n.X, $n.Y] -eq 1 -and -not $visited[$n.X, $n.Y]) {
                            $visited[$n.X, $n.Y] = $true
                            $q.Enqueue($n)
                        }
                    }
                }
            }
            if ($count -gt 15) {
                $components += [PSCustomObject]@{
                    Count = $count
                    MinX = $minX; MaxX = $maxX
                    MinY = $minY; MaxY = $maxY
                    Width = ($maxX - $minX + 1)
                    Height = ($maxY - $minY + 1)
                }
            }
        }
    }
}

foreach ($comp in $components) {
    Write-Host "Component: pixels=$($comp.Count) at X=$($comp.MinX)..$($comp.MaxX) (w=$($comp.Width)) Y=$($comp.MinY)..$($comp.MaxY) (h=$($comp.Height))"
}
$bmp.Dispose()

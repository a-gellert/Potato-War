Add-Type -AssemblyName System.Drawing

function Get-RoundedRectanglePath {
    param (
        [System.Drawing.Rectangle]$rect,
        [int]$radius
    )
    $path = New-Object System.Drawing.Drawing2D.GraphicsPath
    $diameter = $radius * 2
    $arc = New-Object System.Drawing.Rectangle $rect.X, $rect.Y, $diameter, $diameter

    # top left
    $path.AddArc($arc, 180, 90)
    # top right
    $arc.X = $rect.Right - $diameter
    $path.AddArc($arc, 270, 90)
    # bottom right
    $arc.Y = $rect.Bottom - $diameter
    $path.AddArc($arc, 0, 90)
    # bottom left
    $arc.X = $rect.Left
    $path.AddArc($arc, 90, 90)
    $path.CloseFigure()
    return $path
}

$bmp = New-Object System.Drawing.Bitmap 400, 300
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$path = Get-RoundedRectanglePath (New-Object System.Drawing.Rectangle 50, 50, 300, 200) 24
$brush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::Crimson)
$g.FillPath($brush, $path)
$pen = New-Object System.Drawing.Pen ([System.Drawing.Color]::Gold), 4
$g.DrawPath($pen, $path)

$bmp.Save("D:\DProjects\Potato-War\scratch\test_round.png", [System.Drawing.Imaging.ImageFormat]::Png)
$pen.Dispose()
$brush.Dispose()
$path.Dispose()
$g.Dispose()
$bmp.Dispose()
Write-Host "Success: $(Test-Path 'D:\DProjects\Potato-War\scratch\test_round.png')"

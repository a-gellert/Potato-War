Add-Type -AssemblyName System.Drawing
$pfc = New-Object System.Drawing.Text.PrivateFontCollection
$pfc.AddFontFile('D:\DProjects\Potato-War\main\assets\fonts\Rubik-Black.ttf')
$fontFamily = $pfc.Families[0]
$bmp = New-Object System.Drawing.Bitmap 700, 150
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAliasGridFit
$font = New-Object System.Drawing.Font ($fontFamily, [float]40, [System.Drawing.FontStyle]::Bold)
$brush = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::Gold)
$g.DrawString('ЭПИЧЕСКИЙ АРСЕНАЛ!', $font, $brush, [float]20, [float]30)
$bmp.Save('D:\DProjects\Potato-War\scratch\font_test2.png', [System.Drawing.Imaging.ImageFormat]::Png)
$g.Dispose(); $bmp.Dispose(); $pfc.Dispose()
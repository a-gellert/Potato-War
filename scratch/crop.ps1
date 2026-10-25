Add-Type -AssemblyName System.Drawing
$bmp = New-Object System.Drawing.Bitmap('C:\Users\User\.gemini\antigravity\brain\1aed803c-56a8-4d3f-82c6-517eadaf5717\.user_uploaded\media_1792821332235_e57c027d.png')
# Save a cropped version of bottom-left
$rect = New-Object System.Drawing.Rectangle(0, 300, 300, 202)
$crop = $bmp.Clone($rect, $bmp.PixelFormat)
$crop.Save('scratch/crop_bottom_left.png', [System.Drawing.Imaging.ImageFormat]::Png)
Write-Host "Cropped bottom left saved."
$bmp.Dispose()
$crop.Dispose()

Add-Type -AssemblyName System.Drawing

# 1. Flip all potato character sprites horizontally so default PNG orientation is facing RIGHT
$potatoFiles = Get-ChildItem "d:\DProjects\Potato-War\main\assets\potato_*.png" | Where-Object { $_.Name -notmatch "potato_chip" }

foreach ($f in $potatoFiles) {
    $bmp = [System.Drawing.Bitmap]::FromFile($f.FullName)
    $bmp.RotateFlip([System.Drawing.RotateFlipType]::RotateNoneFlipX)
    $tmpPath = $f.FullName + ".tmp"
    $bmp.Save($tmpPath, [System.Drawing.Imaging.ImageFormat]::Png)
    $bmp.Dispose()
    Move-Item $tmpPath $f.FullName -Force
    Write-Output "Flipped horizontally to face RIGHT: $($f.Name)"
}

# 2. Update drill_missile.png to horizontal right-pointing
Copy-Item "d:\DProjects\Potato-War\scratch\drill_rot_neg135.png" "d:\DProjects\Potato-War\main\assets\drill_missile.png" -Force
Write-Output "Updated drill_missile.png to point horizontally RIGHT"

# 3. Update air_bomb.png to horizontal right-pointing
Copy-Item "d:\DProjects\Potato-War\scratch\bomb_rot_neg135.png" "d:\DProjects\Potato-War\main\assets\air_bomb.png" -Force
Write-Output "Updated air_bomb.png to point horizontally RIGHT"

# 4. Update masher_bazooka.png to horizontal right-pointing
Copy-Item "d:\DProjects\Potato-War\scratch\bazooka_rot_neg55.png" "d:\DProjects\Potato-War\main\assets\masher_bazooka.png" -Force
Write-Output "Updated masher_bazooka.png to point horizontally RIGHT"

# 5. Sync updated assets to artifact folder
Copy-Item "d:\DProjects\Potato-War\main\assets\potato_*.png" "C:\Users\User\.gemini\antigravity\brain\fd717b43-0e84-42ba-a460-8314ebc385f8\" -Force
Copy-Item "d:\DProjects\Potato-War\main\assets\drill_missile.png" "C:\Users\User\.gemini\antigravity\brain\fd717b43-0e84-42ba-a460-8314ebc385f8\" -Force
Copy-Item "d:\DProjects\Potato-War\main\assets\air_bomb.png" "C:\Users\User\.gemini\antigravity\brain\fd717b43-0e84-42ba-a460-8314ebc385f8\" -Force
Copy-Item "d:\DProjects\Potato-War\main\assets\masher_bazooka.png" "C:\Users\User\.gemini\antigravity\brain\fd717b43-0e84-42ba-a460-8314ebc385f8\" -Force

Write-Output "All orientations fixed and synced!"

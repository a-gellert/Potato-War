Add-Type -AssemblyName System.Drawing

function Clean-Medic {
    $med = [System.Drawing.Bitmap]::FromFile("C:\Users\User\.gemini\antigravity\brain\fd717b43-0e84-42ba-a460-8314ebc385f8\potato_medic_sprite_1791387966096.jpg")
    $base = [System.Drawing.Bitmap]::FromFile("C:\Users\User\.gemini\antigravity\brain\fd717b43-0e84-42ba-a460-8314ebc385f8\potato_base_sprite_1791387899189.jpg")
    $g = [System.Drawing.Graphics]::FromImage($med)
    $whiteBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)

    # Erase syringe (x < 275)
    $g.FillRectangle($whiteBrush, 0, 0, 275, 760)
    # Erase bottle (x > 760)
    $g.FillRectangle($whiteBrush, 760, 0, 264, 760)

    # Copy clean stick arms from potato_base
    $g.DrawImage($base, [System.Drawing.Rectangle]::new(215, 530, 85, 230), [System.Drawing.Rectangle]::new(215, 530, 85, 230), [System.Drawing.GraphicsUnit]::Pixel)
    $g.DrawImage($base, [System.Drawing.Rectangle]::new(660, 530, 95, 230), [System.Drawing.Rectangle]::new(660, 530, 95, 230), [System.Drawing.GraphicsUnit]::Pixel)

    $g.Dispose()
    $whiteBrush.Dispose()
    $med.Save("C:\Users\User\.gemini\antigravity\brain\fd717b43-0e84-42ba-a460-8314ebc385f8\potato_medic_noweapon.jpg", [System.Drawing.Imaging.ImageFormat]::Jpeg)
    $med.Dispose()
    $base.Dispose()
    Write-Output "Medic cleaned!"
}

function Clean-Sapper {
    $sap = [System.Drawing.Bitmap]::FromFile("C:\Users\User\.gemini\antigravity\brain\fd717b43-0e84-42ba-a460-8314ebc385f8\potato_sapper_sprite_1791387983307.jpg")
    $base = [System.Drawing.Bitmap]::FromFile("C:\Users\User\.gemini\antigravity\brain\fd717b43-0e84-42ba-a460-8314ebc385f8\potato_base_sprite_1791387899189.jpg")
    $g = [System.Drawing.Graphics]::FromImage($sap)
    $whiteBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)

    # Erase shovel on left (x < 285)
    $g.FillRectangle($whiteBrush, 0, 0, 285, 760)

    # Copy clean left stick arm from potato_base
    $g.DrawImage($base, [System.Drawing.Rectangle]::new(215, 530, 85, 230), [System.Drawing.Rectangle]::new(215, 530, 85, 230), [System.Drawing.GraphicsUnit]::Pixel)

    $g.Dispose()
    $whiteBrush.Dispose()
    $sap.Save("C:\Users\User\.gemini\antigravity\brain\fd717b43-0e84-42ba-a460-8314ebc385f8\potato_sapper_noweapon.jpg", [System.Drawing.Imaging.ImageFormat]::Jpeg)
    $sap.Dispose()
    $base.Dispose()
    Write-Output "Sapper cleaned!"
}

Clean-Medic
Clean-Sapper

function Clean-Tank {
    $tank = [System.Drawing.Bitmap]::FromFile("C:\Users\User\.gemini\antigravity\brain\fd717b43-0e84-42ba-a460-8314ebc385f8\potato_tank_sprite_1791388010219.jpg")
    $g = [System.Drawing.Graphics]::FromImage($tank)
    $whiteBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)

    # Erase axe on left (x < 170, y in 580..860) and handle (y > 700)
    $g.FillRectangle($whiteBrush, 0, 580, 180, 300)
    $g.FillRectangle($whiteBrush, 50, 700, 150, 200)

    # Center is x = 490.
    # Mirror left torso/arm (x: 180 to 490) to right side (x: 490 to 800) to replace shield
    $centerX = 490
    $srcW = 310
    $leftHalf = [System.Drawing.Bitmap]::new($srcW, 700, [System.Drawing.Imaging.PixelFormat]::Format32bppArgb)
    $gLeft = [System.Drawing.Graphics]::FromImage($leftHalf)
    $gLeft.DrawImage($tank, [System.Drawing.Rectangle]::new(0, 0, $srcW, 700), [System.Drawing.Rectangle]::new($centerX - $srcW, 200, $srcW, 700), [System.Drawing.GraphicsUnit]::Pixel)
    $gLeft.Dispose()
    $leftHalf.RotateFlip([System.Drawing.RotateFlipType]::RotateNoneFlipX)

    # Erase shield on right
    $g.FillRectangle($whiteBrush, $centerX + 100, 200, 430, 700)

    # Draw mirrored right half
    $g.DrawImage($leftHalf, $centerX, 200)
    $leftHalf.Dispose()

    $g.Dispose()
    $whiteBrush.Dispose()
    $tank.Save("C:\Users\User\.gemini\antigravity\brain\fd717b43-0e84-42ba-a460-8314ebc385f8\potato_tank_noweapon.jpg", [System.Drawing.Imaging.ImageFormat]::Jpeg)
    $tank.Dispose()
    Write-Output "Tank cleaned!"
}

function Clean-Artillery {
    $art = [System.Drawing.Bitmap]::FromFile("C:\Users\User\.gemini\antigravity\brain\fd717b43-0e84-42ba-a460-8314ebc385f8\potato_artillery_sprite_1791388029282.jpg")
    $base = [System.Drawing.Bitmap]::FromFile("C:\Users\User\.gemini\antigravity\brain\fd717b43-0e84-42ba-a460-8314ebc385f8\potato_base_sprite_1791387899189.jpg")
    $g = [System.Drawing.Graphics]::FromImage($art)
    $whiteBrush = [System.Drawing.SolidBrush]::new([System.Drawing.Color]::White)

    # Erase bazooka front, projectile and cord on left (x < 360, y < 750)
    $g.FillRectangle($whiteBrush, 0, 0, 360, 750)

    # Erase bazooka rear tube on right (x > 780, y in 250..550)
    $g.FillRectangle($whiteBrush, 780, 250, 244, 300)

    # Copy clean left stick arm from potato_base (adjusted for artillery torso)
    $g.DrawImage($base, [System.Drawing.Rectangle]::new(260, 530, 95, 230), [System.Drawing.Rectangle]::new(215, 530, 85, 230), [System.Drawing.GraphicsUnit]::Pixel)

    $g.Dispose()
    $whiteBrush.Dispose()
    $art.Save("C:\Users\User\.gemini\antigravity\brain\fd717b43-0e84-42ba-a460-8314ebc385f8\potato_artillery_noweapon.jpg", [System.Drawing.Imaging.ImageFormat]::Jpeg)
    $art.Dispose()
    $base.Dispose()
    Write-Output "Artillery cleaned!"
}

Clean-Tank
Clean-Artillery




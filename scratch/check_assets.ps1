Add-Type -AssemblyName System.Drawing

$assets = @(
    "D:/DProjects/Potato-War/main/assets/potato/assault.png",
    "D:/DProjects/Potato-War/main/assets/potato/tank.png",
    "D:/DProjects/Potato-War/main/assets/potato/sniper.png",
    "D:/DProjects/Potato-War/main/assets/potato/medic.png",
    "D:/DProjects/Potato-War/main/assets/potato/sapper.png",
    "D:/DProjects/Potato-War/main/assets/tnt_barrel.png",
    "D:/DProjects/Potato-War/main/assets/holy_spud.png",
    "D:/DProjects/Potato-War/main/assets/garlic_bomb.png",
    "D:/DProjects/Potato-War/main/assets/french_fries.png",
    "D:/DProjects/Potato-War/main/assets/explosion.png",
    "D:/DProjects/Potato-War/main/assets/weapons/w_bazooka.png",
    "D:/DProjects/Potato-War/main/assets/weapons/w_grenade.png",
    "D:/DProjects/Potato-War/main/assets/weapons/w_dynamite.png",
    "D:/DProjects/Potato-War/main/assets/weapons/w_airstrike.png",
    "D:/DProjects/Potato-War/main/assets/ui/card_legendary.png",
    "D:/DProjects/Potato-War/main/assets/ui/badge.png"
)

foreach ($f in $assets) {
    if (Test-Path $f) {
        $img = [System.Drawing.Image]::FromFile($f)
        Write-Host "$([System.IO.Path]::GetFileName($f)) : $($img.Width)x$($img.Height)"
        $img.Dispose()
    }
}

Add-Type -AssemblyName System.Drawing

$files = @(
    "C:/Users/User/.gemini/antigravity/brain/81cf0b15-7096-4e5b-a118-442de0b53ee3/.user_uploaded/media_1793211393889_5edce1e8.png",
    "C:/Users/User/.gemini/antigravity/brain/81cf0b15-7096-4e5b-a118-442de0b53ee3/.user_uploaded/media_1793211405643_f703317d.png",
    "C:/Users/User/.gemini/antigravity/brain/81cf0b15-7096-4e5b-a118-442de0b53ee3/.user_uploaded/media_1793211423643_d5b64b14.png",
    "C:/Users/User/.gemini/antigravity/brain/81cf0b15-7096-4e5b-a118-442de0b53ee3/.user_uploaded/media_1793211441749_0f645b75.png",
    "C:/Users/User/.gemini/antigravity/brain/81cf0b15-7096-4e5b-a118-442de0b53ee3/.user_uploaded/media_1793211452829_3af40ab7.png",
    "D:/DProjects/Potato-War/main/assets/logo2 (1).png"
)

foreach ($f in $files) {
    if (Test-Path $f) {
        $img = [System.Drawing.Image]::FromFile($f)
        Write-Host "$f : $($img.Width)x$($img.Height)"
        $img.Dispose()
    } else {
        Write-Host "Missing: $f"
    }
}

# Wechsle in das aktuelle Verzeichnis (optional)
Set-Location -Path $PSScriptRoot

# Durchsuche alle Dateien mit beliebiger Erweiterung
Get-ChildItem -File | ForEach-Object {
    $file = $_.Name

    # Lese den "Make"-Tag aus den EXIF-Daten
    $makeTag = & exiftool -Make $file

    if ([string]::IsNullOrWhiteSpace($makeTag)) {
        Write-Output "$file contains no exif"

        # Entferne .jpg, .jpeg oder .tiff von Dateinamen
        $originalFileBase = $file -replace '\.(jpg|jpeg|tiff)$', ''

        # Nehme an, dass das Original (.NEF) eine Ebene höher liegt
        $originalPath = "..\$originalFileBase.NEF"

        # Kopiere bestimmte EXIF-Tags vom Original auf die aktuelle Datei
        & exiftool -overwrite_original -x Orientation -TagsFromFile $originalPath $file

        # Log-Datei schreiben
        Add-Content -Path "log.txt" -Value "$file, $makeTag"
    }
}

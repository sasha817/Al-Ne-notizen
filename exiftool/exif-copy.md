# Копіювання exif з іншого файлу

*Оригінал цього допису написаний 7 лютого 2013 року*

Днями я наступив на вельми несподівані граблі: більша частина оброблених фотографій з однієї поїздки виявилась без EXIF-інформації. Все би нічого, але мав на меті проставити геотеги, а їм, в свою чергу, необхідно мати відомим час зйомки. Перепроявляти tiff’и по-новій, різати та коригувати (попри невелику кількість правок) не хотілось, відтак вирішив скопіювати EXIF’и.

Задача копіювання була виконана не надто тупо (надто тупо — взяти всі оброблені файли та скопіювати в них EXIF’и з оригіналів), а трошки менш тупо (пробігтись по обробленому — якщо EXIF відсутній, скопіювати його з оригіналу). Оскільки все в середовищі OS X, скриптик написаний на bash’і, втім, його можна легко «перекласти» для Windows. Код наступний:

```
#!/bin/bash
for f in *.*
do
 STRING=$(exiftool -Make $f)
 if [ "$STRING" == '' ] ; then
  echo $f contains no exif;

  #remove file extension to get original file name
  shopt -s extglob
  ORIGINAL_FILE=${f//@(.jpg|.jpeg|.tiff)}

  #copy EXIF tags from original file, it should be in parent directory
  exiftool -overwrite_original -x Orientation -TagsFromFile ../$ORIGINAL_FILE.NEF ./$f

  echo $f, $STRING >> "log.txt";
 fi
done
```

Далі «chmod +x copyMissingExif.sh» і запуск з будь-якого місця системи, де лежать оброблені файли. Умова: оригінали (raw) мають лежати на один рівень вище і мати ті ж самі назви файлів (розширення відтинається).

Недоліки: версія 0.1 але працює :) насправді недолік в дворазовому читанні обробленого файлу в разі копіювання тегів. Ця проблема цілком підлягає вирішенню засобами ExifTool (я сказав, що він неохідний? нє? кажу: ExifTool необхідний), але на разі я не мав часу глибоко вникнути в його схему подібних дій, щойно розберусь — буде версія 0.2.

## Update 27.05.2025

У зв'язку з відсутністю Mac, скрипт перекладений у середовище Windows PowerShell з допомогою ChatGPT. Працює, правда, лише в поточній папці. Тим не менш:

```
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
```

Важливо: треба дозволити запуск "невідомих" скриптів:

`Set-ExecutionPolicy RemoteSigned -Scope CurrentUser`
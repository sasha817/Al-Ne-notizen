# Windows, Exiftool, Synology Photos and network drives

## Task

Synology Photos relies on date of file has been created in filesystem in order to sort Timeline.
Thus, to have photos in proper places, once they have been shot long time ago but exportet later, one has to update file creation date. Which is trivial operation using ExifTool:

> exiftool "-filemodifydate<datetimeoriginal" "-filecreatedate<datetimeoriginal" DIR

## Problem

However, Windows command prompt can't just `cd` to network drive, in order to run ExifTool. This can be done using `pushd` and later `popd`:

> pushd \\your\server\network\path

Be sure to unmount temporary drive after.

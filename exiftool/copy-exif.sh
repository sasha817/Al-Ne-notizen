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
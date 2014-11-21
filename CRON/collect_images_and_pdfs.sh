#!/bin/bash

# IFS=$'\n'
# PATH="/usr/bin:/bin:$SCRIPT_FOLDER"
DESKEN="/uio/kant/div-universitas-desken"

SCRIPT_FOLDER="$DESKEN/SCRIPTS/CRON"
STAGING="$DESKEN/STAGING"
IMAGE_FOLDER="$STAGING/IMAGES"
PDF_FOLDER="$STAGING/PDF"

remote_linode="haakenlid@linode:/srv/fotoarkiv_universitas/STAGING/"
remote_domeneshop="universitas@login.domeneshop.no:static/bilder/"

logfile="rsync.log"

if [ "$2" ]; then
  YEAR=$1
  ISSUE=$2
else
  YEAR=$(date +%Y)
  ISSUE=$(ls $DESKEN/ | grep -e '^[0-9]\{1,3\}$' | sort -nr | head -n 1)
fi

echo "$ISSUE ($YEAR)"

if [ "$ISSUE" = "" ]; then
  exit
fi

mkdir -p $IMAGE_FOLDER $PDF_FOLDER

# Check that we are not already running
# touch lock
# read last_pid < lock
# [ ! -z "$last_pid" -a -d /proc/$last_pid ] && echo "Already running" && exit
# echo $$ > lock

ERROR='_ERROR_'
image_files=$(find "$DESKEN/$ISSUE" -iregex '.*\.\(jpg\|jpeg\|png\)' ! -name '._*' ! -name "$ERROR*")
for original in $image_files; do
  original=$($SCRIPT_FOLDER/fix_filnavn.py $original)
  # ln -s $image $IMAGE_FOLDER
  compressed="$IMAGE_FOLDER/$(basename $original)"
  if [[ ! -f "$compressed" || "$original" -nt "$compressed" ]]; then
    convert "$original" -resize 1500x -quality 60 "$compressed"
    #echo "compressed  $original"
    #echo "        ->  $compressed"
    if [[ ! -f "$compressed" ]]; then
      broken_file=$(dirname "$original")"/$ERROR"$(basename "$original")
      echo "ERROR:   " $broken_file
      mv $original $broken_file
    fi
  fi
done

# remove stale files
for compressed in $(ls $IMAGE_FOLDER); do
  if [[ "" == $(find "$DESKEN/$ISSUE" -name "$compressed") ]]; then
    rm "$IMAGE_FOLDER/$compressed"
  fi
done

find $PDF_FOLDER -type l -delete
pdf_files=$(find "$DESKEN/$ISSUE" -name "UNI11*.pdf")
for pdf_file in $pdf_files; do
  ln -s $pdf_file $PDF_FOLDER
done

# key="/uio/kant/div-universitas-u1/haakenl/.ssh/id_rsa"

# uploading to domeneshop
logg="$STAGING/domeneshop-rsync.log"
remote="$remote_domeneshop/$YEAR/$ISSUE"
/usr/bin/rsync -rthzv $IMAGE_FOLDER $remote > "$STAGING/$logg"

# uploading to linode
logg="$STAGING/linode-rsync.log"
remote="$remote_linode"
/usr/bin/rsync -rthzv $STAGING_FOLDER $remote > "$STAGING/$logg"

#!/bin/bash

# load environmental variables.
source ${0%/*}/cron_environment_variables.sh
# force upload
if [[ -n $1 ]]; then
  upload_files=true
fi

# logfile
logfile="$STAGING/collect.log"
echo "Collecting images and pdfs for: $ISSUE ($YEAR)" | logger $logfile

# Make sure local folders exist.
mkdir -p $IMAGE_FOLDER $PDF_FOLDER

if [[ -z "$ISSUE" ]]; then
  # no valid folder name.
  echo "No valid folder for this week's issue" >&2
  exit 1
fi

if [[ -z "$(find "$DESKEN/$ISSUE" -mmin -5 -print -quit)" ]]; then
  # no modified files
  [[ -z $upload_files ]] && exit 0
fi

# remove stale files in local image staging folder.
for compressed in $(ls $IMAGE_FOLDER); do
  if [[ "" == $(find "$DESKEN/$ISSUE" -name "$compressed") ]]; then
    # file in staging folder doesn't match any file in current issue.
    rm "$IMAGE_FOLDER/$compressed"
    echo "removed $compressed" | logger $logfile
  fi
done


$SCRIPT_FOLDER/fix_filnavn.py "$DESKEN/$ISSUE"
ERROR='ERROR-' # used to rename image files that can't be converted.
image_files=$(find "$DESKEN/$ISSUE" -iregex '.*\.\(jpg\|jpeg\|png\)' ! -name '._*' ! -name "$ERROR*")

for original in $image_files; do
  compressed="$IMAGE_FOLDER/$(basename $original)"
  if [[ ! -f "$compressed" || "$original" -nt "$compressed" ]]; then
    size='10000000@>'  # max 10 Megapixels
    convert "$original" -resize $size -quality 75 "$compressed" 2>> $logfile
    if [[ $? -eq 0 ]]; then
      upload_files=true
      echo "compressed  $original" | logger $logfile
    else
      error_count=$(tail -n100 "$logfile" | grep -c "ERROR: $original")
      echo "ERROR: $original $(( error_count + 1 ))" | logger $logfile
      if (( $error_count > 2 )); then
        # Unable to convert image file. Corrupt file or wrong filename.
        broken_file=$(dirname "$original")"/$ERROR"$(basename "$original")
        mv $original $broken_file # rename file.
      fi
    fi
  fi
done

# Symlink pdf files.
find $PDF_FOLDER -type l -delete  # delete symbolic links in pdf folder.
pdf_files=$(find "$DESKEN/$ISSUE" -name "UNI1*.pdf")
[[ -n $pdf_files ]] && pdf_files=$(ls -tr1 $pdf_files) # order by time
for pdf_file in $pdf_files; do
  ln -fs $pdf_file $PDF_FOLDER # create symbolic links
done

if $upload_files; then
  # chmod 664 -R $IMAGE_FOLDER
  # chmod 775 $IMAGE_FOLDER

  # upload to linode
  logfile="$STAGING/linode-rsync.log"
  remote="$REMOTE_LINODE"
  /usr/bin/rsync --temp-dir=/tmp -rthzvLp $STAGING/ $remote --exclude=*.log | logger $logfile
fi

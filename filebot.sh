#!/bin/bash

# This script by default uses "Automated Media Center" (AMC). See the final filebot call below. For more docs on AMC,
# visit: http://www.filebot.net/forums/viewtopic.php?t=215

#-----------------------------------------------------------------------------------------------------------------------

. /config/filebot.conf

if [ "$SUBTITLE_LANG" == "" ];then
  SUBTITLE_OPTION=""
else
  SUBTITLE_OPTION="subtitles=$SUBTITLE_LANG"
fi

#-----------------------------------------------------------------------------------------------------------------------

# Download scripts and such.
. /files/pre-run.sh

# See http://www.filebot.net/forums/viewtopic.php?t=215 for details on amc
filebot -script ${SCRIPT:-"fn:amc"} -no-xattr --output /output --log-file /files/amc.log --action ${ACTION:-copy} --lang=${LANG:-en} --conflict auto \
  -non-strict --def ut_dir=/completed ut_kind=multi music=n deleteAfterExtract=y clean=y \
  gmail="$GMAIL" mailto="$MAILTO" pushover="$PUSHOVER" plex="$PLEX" \
  excludeList=/config/amc-exclude-list.txt $SUBTITLE_OPTION \
  movieFormat="$MOVIE_FORMAT" musicFormat="$MUSIC_FORMAT" seriesFormat="$SERIES_FORMAT"

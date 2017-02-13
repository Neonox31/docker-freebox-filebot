#!/bin/bash

function ts {
  echo [`date '+%b %d %X'`]
}

#-----------------------------------------------------------------------------------------------------------------------

function initialize_configuration {
  # Initialize filebot configuration
  if [ ! -f /config/filebot.conf ]; then
    echo "$(ts) Creating /config/filebot.conf"
    cp /files/filebot.conf /config/filebot.conf
    chmod a+w /config/filebot.conf
  fi
  # Convert windows line endings
  dos2unix /config/filebot.conf

  # Initialize freebox configuration
  if [ ! -f /config/freebox.conf ]; then
    echo "$(ts) Creating /config/freebox.conf"
    cp /files/freebox.conf /config/freebox.conf
    chmod a+w /config/freebox.conf
  fi
  # Convert windows line endings
  dos2unix /config/freebox.conf

  if [ -f /config/freebox_auth.conf ]; then
    # Convert windows line endings
    dos2unix /config/freebox_auth.conf
  fi
}

#-----------------------------------------------------------------------------------------------------------------------

function setup_opensubtitles_account {
  . /config/filebot.conf

  if [ "$OPENSUBTITLES_USER" != "" ]; then
    echo "$(ts) Configuring for OpenSubtitles user \"$OPENSUBTITLES_USER\""
    echo -en "$OPENSUBTITLES_USER\n$OPENSUBTITLES_PASSWORD\n" | /files/runas.sh $USER_ID $GROUP_ID $UMASK filebot -script fn:configure
  else
    echo "$(ts) No OpenSubtitles user set. Skipping setup..."
  fi
}

#-----------------------------------------------------------------------------------------------------------------------

echo "$(ts) Starting Freebox-FileBot container"

initialize_configuration

setup_opensubtitles_account

# Start freebox script
echo "$(ts) Starting freebox script"
/files/runas.sh $USER_ID $GROUP_ID $UMASK /files/freebox.sh

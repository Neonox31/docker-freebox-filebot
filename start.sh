#!/bin/bash

function ts {
  echo [`date '+%b %d %X'`]
}

#-----------------------------------------------------------------------------------------------------------------------

function initialize_configuration {
  # Initialize filebot script
  if [ ! -f /config/filebot.conf ]; then
    echo "$(ts) Creating /config/filebot.conf.new"
    cp /files/filebot.conf /config/filebot.conf.new
    chmod a+w /config/filebot.conf.new
    echo "$(ts) /config/filebot.conf doesn't exist, please edit /config/filebot.conf.new and rename it when done"
    exit 1
  else
    chmod a+w /config/filebot.conf
  fi

  # Initialize freebox script
  if [ ! -f /config/freebox.conf ]; then
    echo "$(ts) Creating /config/freebox.conf.new"
    cp /files/freebox.conf /config/freebox.conf.new
    chmod a+w /config/freebox.conf.new
    echo "$(ts) /config/freebox.conf doesn't exist, please edit /config/freebox.conf.new and rename it when done"
    exit 1
  else
    chmod a+w /config/freebox.conf
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

# Run once at the start
echo "$(ts) Running Freebox script on startup"
/files/runas.sh $USER_ID $GROUP_ID $UMASK /files/freebox.sh &


#!/bin/bash

function ts {
  echo [`date '+%b %d %X'`]
}

#-----------------------------------------------------------------------------------------------------------------------

function authorize_application {
 echo "$(ts) authorize app"
 if [ ! -f /config/freebox_auth.conf ] || [ ! -s /config/freebox_auth.conf ]; then
   echo "$(ts) /config/freebox_auth.conf doesn't exist or is empty"
   echo "$(ts) Asking an application authorization to the freebox"
   source /files/freeboxos_bash_api.sh
   if authorize_application  'docker-freebox-filebot'  'Docker Freebox FileBot'  '1.0.0'  'docker-container' > /config/freebox_auth.conf; then
    return 0
   else
    rm -rf /config/freebox_auth.conf
    return 1
   fi
 fi
 return 0
}

#-----------------------------------------------------------------------------------------------------------------------

echo "$(ts) freebox script"
if authorize_application; then
 # get app ID and token
 source /config/freebox_auth.conf
 # get freebox conf
 source /config/freebox.conf
 # source the freeboxos-bash-api
 source /files/freeboxos_bash_api.sh
 # login
 if login_freebox "$MY_APP_ID" "$MY_APP_TOKEN"; then
  echo "$(ts) Successfully logged"
  # get completed downloads
  answer=$(call_freebox_api 'downloads/')
  files=($(echo "$answer" | jq -r '.result[] | select(.status == "done" or .status == "seeding") | .name'))
  for file in ${files[@]}
  do
    echo "$(ts) Copy /freebox/$file to /completed/$file"
    cp "/freebox//$file" "/completed/$file"
  done
  echo "$(ts) Start filebot script"
  /files/runas.sh $USER_ID $GROUP_ID $UMASK /files/filebot.sh
  exit 0
 fi
else
   echo "$(ts) fail"
fi

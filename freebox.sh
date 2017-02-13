#!/bin/bash

function ts {
  echo [`date '+%b %d %X'`]
}

#-----------------------------------------------------------------------------------------------------------------------

function authorize_application {
 if [ ! -f /config/freebox_auth.conf ]; then
   echo "$(ts) /config/freebox_auth.conf missing"
   echo "$(ts) Asking freebox for an application authorization"
   source /files/freeboxos_bash_api.sh
   if authorize_application  'docker-freebox-filebot'  'Docker Freebox FileBot'  '1.0.0'  'docker-container' > /config/freebox_auth.conf; then
    return 0
   else
    rm -rf /config/freebox_auth.conf
    echo "$(ts) /config/freebox_auth.conf deleted"
    return 1
   fi
 else
   echo "$(ts) /config/freebox_auth.conf found, bypass authorisation process"
 fi
 return 0
}

#-----------------------------------------------------------------------------------------------------------------------

# Get freebox conf
source /config/freebox.conf
# Source the freeboxos-bash-api
source /files/freeboxos_bash_api.sh

while true
do
    if authorize_application; then
     # Get app ID and token
     source /config/freebox_auth.conf
     # Login
     if login_freebox "$MY_APP_ID" "$MY_APP_TOKEN"; then
      echo "$(ts) New session opened on the freebox for $MY_APP_ID application"
      # Get completed downloads
      answer=$(call_freebox_api 'downloads/')
      echo "$(ts) Downloads request result : $answer"
      # Filter only done or seeding downloads
      files=($(echo "$answer" | jq -r '.result[] | select(.status == "done" or .status == "seeding") | .name'))
      if [ ${#files[@]} -ne 0 ]; then
       for file in ${files[@]}
       do
         echo "$(ts) New completed download detected : $file"
         echo "$(ts) Copy /freebox/$file to /completed/$file"
         cp -rf "/freebox//$file" "/completed/$file"
       done
       echo "$(ts) Starting filebot script"
       /files/runas.sh $USER_ID $GROUP_ID $UMASK /files/filebot.sh
      else
        echo "$(ts) No completed download detected"
      fi
     else
       echo "$(ts) Opening session failed"
     fi
    else
       echo "$(ts) Application authorization failed"
    fi
    echo "$(ts) Wait for $LOOP_DELAY seconds..."
    sleep $LOOP_DELAY
done
#!/bin/bash

function ts {
  echo [`date '+%b %d %X'`]
}

#-----------------------------------------------------------------------------------------------------------------------

function fb_authorize {
 if [ ! -f /config/freebox_auth.conf ]; then
   echo "$(ts) [DEBUG] /config/freebox_auth.conf missing"
   echo "$(ts) [INFO] Asking freebox for an application authorization"
   if ! authorize_application  'docker-freebox-filebot'  'Docker Freebox FileBot'  '1.0.0'  'docker-container' > /config/freebox_auth.conf; then
    rm -rf /config/freebox_auth.conf
    echo "$(ts) [DEBUG] /config/freebox_auth.conf deleted"
    return 1
   fi
 else
   echo "$(ts) [INFO] /config/freebox_auth.conf found, bypass authorization process"
 fi
 return 0
}

#-----------------------------------------------------------------------------------------------------------------------

function fb_logout {
 answer_logout=$(call_freebox_api '/login/logout/' "{}")
 if ! _check_success "$answer_logout"; then
  echo "$(ts) [ERROR] Failed to close session"
  return 1
 fi
 return 0
}

#-----------------------------------------------------------------------------------------------------------------------

function fb_iterate {
 if [ "$1" ==  true ]; then
  fb_logout
 fi
 echo "$(ts) [INFO] Wait for $LOOP_DELAY seconds..."
 sleep $LOOP_DELAY
 continue
}

#-----------------------------------------------------------------------------------------------------------------------

function run {
 # Source the freeboxos-bash-api script
 source /files/freeboxos_bash_api.sh

 while true
  do
   # Refresh freebox script configuration
   source /config/freebox.conf

   # Authorize
   if ! fb_authorize; then
    echo "$(ts) [ERROR] Application authorization failed"
    fb_iterate
   fi
   # Get app ID and token
   source /config/freebox_auth.conf

   # Open session
   if ! login_freebox "$MY_APP_ID" "$MY_APP_TOKEN"; then
    echo "$(ts) [ERROR] Failed to open new session"
    fb_iterate
   fi

   # Get completed downloads
   answer_dls=$(call_freebox_api 'downloads/')
   if ! _check_success "$answer_dls"; then
    echo "$(ts) [ERROR] Failed while retrieving downloads"
    fb_iterate true
   fi
   echo "$(ts) [DEBUG] Downloads response : $answer_dls"
   # Filter only done or seeding downloads
   files=$(echo "$answer_dls" | jq -r '.result[]? | select(.status == "done" or .status == "seeding") | .name')
   if [ -z "$files" ] || [ ${#files[@]} -eq 0 ]; then
    echo "$(ts) [INFO] No completed downloads detected"
   else
    local has_new_files=false
    for file in "$files"
     do
      echo "$(ts) [INFO] New completed download detected : ${file}"
      if ! grep -Fxq "$file" /config/fb-exclude-list.txt; then
       echo "$(ts) [DEBUG] $file not found in freebox exclude list"
       echo "$(ts) [INFO] Copy /freebox/${file} to /completed/${file}"
       if cp -rf /freebox/"${file}" /completed/"${file}"; then
         echo "$(ts) [DEBUG] Add ${file} to freebox exclude list"
         echo "$file" >> /config/fb-exclude-list.txt
       fi
      else
        echo "$(ts) [WARN] $file found in freebox exclude list, ignoring"
      fi
     done
     if $has_new_files; then
      echo "$(ts) [INFO] Starting filebot script"
      /files/runas.sh $USER_ID $GROUP_ID $UMASK /files/filebot.sh
     fi
   fi
   fb_iterate true
  done
}

#-----------------------------------------------------------------------------------------------------------------------

# Startup
run
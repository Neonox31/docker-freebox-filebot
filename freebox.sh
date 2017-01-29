#!/bin/bash

function ts {
  echo [`date '+%b %d %X'`]
}

#-----------------------------------------------------------------------------------------------------------------------

function create_conf {
  cat <<"EOF" >> /config/freebox.conf
MY_APP_ID=$MY_APP_ID
MY_APP_TOKEN=$MY_APP_TOKEN
EOF
}

#-----------------------------------------------------------------------------------------------------------------------

function authorize_application {
 if [ ! -f /config/freebox.conf ]
 then
   echo "$(ts) /config/freebox.conf doesn't exist"
   echo "$(ts) Asking an application authorization to the freebox"
   source /files/freeboxos_bash_api.sh
   authorize_application  'docker-freebox-filebot'  'Docker Freebox FileBot'  '1.0.0'  'docker-container'
   create_conf
 fi
 return 0;
}

#-----------------------------------------------------------------------------------------------------------------------

authorize_application
# source the freeboxos-bash-api
source /files/freeboxos_bash_api.sh
# login
login_freebox "$MY_APP_ID" "$MY_APP_TOKEN"
# get completed downloads
answer=$(call_freebox_api '/downloads')
dump_json_keys_values "$answer"
echo

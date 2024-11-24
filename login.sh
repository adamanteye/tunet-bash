#!/usr/bin/bash

source ./constants.sh
USERNAME="${TUNET_USERNAME}"
PASSWORD="${TUNET_PASSWORD}"
LOG_LEVEL="${LOG_LEVEL}"

if [ -z "$LOG_LEVEL" ]; then
    LOG_LEVEL="info"
fi

log_date() {
    echo "[$(date --rfc-3339 s)]"
}

log_error() {
    echo "$(log_date) ERROR $1" >&2
}

if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ]; then
    log_error "TUNET_USERNAME or TUNET_PASSWORD is not set"
    exit 1
fi

log_debug() {
    if [ "$LOG_LEVEL" == "debug" ]; then
        echo -e "$(log_date) DEBUG $1" >&2
    fi
}

log_info() {
    if [ "$LOG_LEVEL" == "info" ] || [ "$LOG_LEVEL" == "debug" ]; then
        echo -e "$(log_date) INFO $1" >&2
    fi
}

fetch_ac_id() {
    log_debug "fetch ac_id"
    local res=$(curl -s "$REDIRECT_URI")
    [[ $(echo $res) =~ $REGEX_AC_ID ]]
    local ac_id=${BASH_REMATCH[1]}
    if [ -z "$ac_id" ]; then
        log_debug "ac_id not found, using 1 as default"
        echo "1"
    else
        echo "$ac_id"
    fi
    log_debug "ac_id: $ac_id"
}

fetch_challenge() {
    log_debug "fetch challenge"
    local res=$(curl -s "$AUTH4_CHALLENGE_URL" --data-urlencode "username=$USERNAME" --data-urlencode "double_stack=1" --data-urlencode "ip=" --data-urlencode "callback=callback")
    log_debug "response: $res"
    local len=$((${#res}-10))
    local res=${res:9:$len}
    local challenge=$(echo $res | jq -r '.challenge')
    log_debug "challenge: $challenge"
    echo $challenge
}

gen_hmacmd5() {
    echo -n $1 | openssl dgst -md5 -hmac "" | sed 's/^.* //'
}

post_info() {
    local challenge=$1
    local password_md5=$(gen_hmacmd5 $challenge)
    log_debug "password_md5: $password_md5"
    local json=$(jq -n \
        --arg username $USERNAME \
        --arg password $PASSWORD \
        --arg ip "" \
        --arg acid "$2" \
        --arg enc_ver "srun_bx1" \
        '{acid:$acid,enc_ver:$enc_ver,ip: $ip,password:$password,username:$username}')
    echo -n $json | sed 's/ //g' > data.txt
    echo $(./tea $challenge ./data.txt)
    rm -f data.txt
}

log_debug "begin login"
log_debug "$(make all)"
ac_id=$(fetch_ac_id)
challenge=$(fetch_challenge)
post_info $challenge $ac_id

#!/usr/bin/bash

SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
source $SCRIPT_DIR/constants.sh
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

if [ -z "$USERNAME" ]; then
    log_error "TUNET_USERNAME is not set"
    exit 1
fi

if [ -z "$PASSWORD" ]; then
    log_error "TUNET_PASSWORD is not set"
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
    local res=$(curl --cookie $SCRIPT_DIR/cookies.txt --cookie-jar $SCRIPT_DIR/cookies.txt -s "$REDIRECT_URI")
    [[ $(echo $res) =~ $REGEX_AC_ID ]]
    local ac_id=${BASH_REMATCH[1]}
    if [ -z "$ac_id" ]; then
        log_debug "ac_id not found, using 1 as default"
        echo "1"
    else
        echo "$ac_id"
    fi
}

fetch_challenge() {
    log_debug "fetch challenge"
    local res=$(curl --cookie $SCRIPT_DIR/cookies.txt --cookie-jar $SCRIPT_DIR/cookies.txt -s "$AUTH4_CHALLENGE_URL" --data-urlencode "username=$USERNAME" --data-urlencode "double_stack=1" --data-urlencode "ip=" --data-urlencode "callback=callback")
    local len=$((${#res}-10))
    local res=${res:9:$len}
    local challenge=$(echo $res | jq -r '.challenge')
    echo $challenge
}

gen_hmacmd5() {
    echo -n $1 | openssl dgst -md5 -hmac "" | sed 's/^.* //'
}

post_info() {
    local challenge=$1
    local json=$(jq -n \
        --arg username $USERNAME \
        --arg password $PASSWORD \
        --arg ip "" \
        --arg acid "$2" \
        --arg enc_ver "srun_bx1" \
        '{acid:$acid,enc_ver:$enc_ver,ip: $ip,password:$password,username:$username}')
    echo -n $json | sed 's/ //g' | sed 's/"acid":"\([0-9]\+\)"/"acid":\1/g' > $SCRIPT_DIR/data.txt
    log_debug "encoded_json: $($SCRIPT_DIR/.tea $challenge $SCRIPT_DIR/data.txt $SCRIPT_DIR/encoded_output.bin)" # note that tea also writes to stdout, which will pop up in the output
    echo $(base64 $SCRIPT_DIR/encoded_output.bin | tr -d '\n' | tr \
       'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/' \
       'LVoJPiCN2R8G90yg+hmFHuacZ1OWMnrsSTXkYpUq/3dlbfKwv6xztjI7DeBE45QA')
    rm -f $SCRIPT_DIR/data.txt $SCRIPT_DIR/encoded_output.bin
}

login() {
    log_debug "begin login"
    log_debug "$(cd $SCRIPT_DIR && make all)"
    log_debug "remove cookies $(rm -f $SCRIPT_DIR/cookies.txt)"
    ac_id=$(fetch_ac_id)
    challenge=$(fetch_challenge)
    log_debug "challenge: $challenge"
    info="{SRBX1}$(post_info $challenge $ac_id)"
    log_debug "info: $info"
    password_md5=$(gen_hmacmd5 $challenge)
    log_debug "password_md5: {MD5}$password_md5"
    checksum="$challenge$USERNAME$challenge$password_md5$challenge$ac_id$challenge${challenge}200${challenge}1$challenge$info"
    checksum=$(echo -n $checksum | openssl sha1 -hex | sed 's/SHA1(stdin)= //g')
    log_debug "checksum: $checksum"
    log_debug "make login request"
    response=$(curl --cookie $SCRIPT_DIR/cookies.txt --cookie-jar $SCRIPT_DIR/cookies.txt -s -X POST "$AUTH4_LOG_URL" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        --data-urlencode "action=login" \
        --data-urlencode "ac_id=$ac_id" \
        --data-urlencode "double_stack=1" \
        --data-urlencode "n=200" \
        --data-urlencode "type=1" \
        --data-urlencode "username=$USERNAME" \
        --data-urlencode "password={MD5}$password_md5" \
        --data-urlencode "info=$info" \
        --data-urlencode "chksum=$checksum" \
        --data-urlencode "callback=callback")
    log_debug "response: $response"
    log_debug "remove cookies $(rm -f $SCRIPT_DIR/cookies.txt)"
    len=$((${#response}-10))
    response=${response:9:$len}
    suc_msg=$(echo $response | jq -r '.suc_msg')
    log_info "$suc_msg"
    if [ "$suc_msg" != "login_ok" ]; then
        exit 1
    else
        exit 0
    fi
}

logout() {
    log_debug "begin logout"
    local response=$(curl -s -X POST "$AUTH4_LOG_URL" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        --data-urlencode "action=logout" \
        --data-urlencode "ac_id=1" \
        --data-urlencode "double_stack=1" \
        --data-urlencode "username=$USERNAME" \
        --data-urlencode "callback=callback")
    log_debug "response: $response"
    local len=$((${#response}-10))
    local response=${response:9:$len}
    local suc_msg=$(echo $response | jq -r '.error')
    log_info "$suc_msg"
    if [ "$suc_msg" != "ok" ]; then
        local error_msg=$(echo $response | jq -r '.error_msg')
        log_error "$error_msg"
        exit 1
    else
        exit 0
    fi
}

if [ "$1" == "login" ]; then
    login
elif [ "$1" == "logout" ]; then
    logout
else
    echo "Usage: $0 {login|logout}"
    exit 1
fi

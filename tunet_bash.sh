#!/usr/bin/bash

AUTH4_LOG_URL="https://auth4.tsinghua.edu.cn/cgi-bin/srun_portal"
AUTH4_USER_INFO="https://auth4.tsinghua.edu.cn/cgi-bin/rad_user_info" 
AUTH4_CHALLENGE_URL="https://auth4.tsinghua.edu.cn/cgi-bin/get_challenge"
AUTH6_LOG_URL="https://auth6.tsinghua.edu.cn/cgi-bin/srun_portal"
AUTH6_CHALLENGE_URL="https://auth6.tsinghua.edu.cn/cgi-bin/get_challenge"
REDIRECT_URI="http://info.tsinghua.edu.cn/"
REGEX_AC_ID='//auth([46])\.tsinghua\.edu\.cn/index_([0-9]+)\.html'

SCRIPT_DIR=$(dirname "${BASH_SOURCE[0]}")
LOG_LEVEL="${LOG_LEVEL}"

[ -z "$LOG_LEVEL" ] && LOG_LEVEL="info"

log_date() {
    echo "[$(date --rfc-3339 s)]"
}

log_error() {
    echo "$(log_date) ERROR $1" >&2
}

check_user() {
    USERNAME="${TUNET_USERNAME}"
    PASSWORD="${TUNET_PASSWORD}"
    if [ -z "$USERNAME" ]; then
        log_error "TUNET_USERNAME is not set"
        exit 1
    fi
    if [ -z "$PASSWORD" ]; then
        log_error "TUNET_PASSWORD is not set"
        exit 1
    fi
}

log_debug() {
    [ "$LOG_LEVEL" == "debug" ] && echo -e "$(log_date) DEBUG $1" >&2
}

log_info() {
    if [ "$LOG_LEVEL" == "info" ] || [ "$LOG_LEVEL" == "debug" ]; then
        echo -e "$(log_date) INFO $1" >&2
    fi
}

fetch_ac_id() {
    log_debug "fetch ac_id"
    local res=$(curl -s "$REDIRECT_URI")
    [[ $res =~ $REGEX_AC_ID ]]
    ipv=${BASH_REMATCH[1]}
    if [ -z "$ipv" ]; then
        ipv="4"
    fi
    log_debug "ip version $ipv"
    local ac_id=${BASH_REMATCH[2]}
    if [ -z "$ac_id" ]; then
        log_debug "ac_id not found, using 1 as default"
        echo "1"
    else
        echo "$ac_id"
    fi
}

fetch_challenge() {
    log_debug "fetch challenge"
    local res=$(curl -s "$REDIRECT_URI")
    [[ $res =~ $REGEX_AC_ID ]]
    ipv=${BASH_REMATCH[1]}
    if [ -z "$ipv" ]; then
        ipv="4"
    fi
    local AUTH_CHALLENGE_URL=$([ $ipv == "6" ] && echo $AUTH6_CHALLENGE_URL || echo $AUTH4_CHALLENGE_URL)
    local res=$(curl -s "$AUTH_CHALLENGE_URL" --data-urlencode "username=$USERNAME" --data-urlencode "double_stack=1" --data-urlencode "ip=" --data-urlencode "callback=callback")
    local REGEX_CHALLENGE='"challenge":"([^"]+)"'
    [[ $res =~ $REGEX_CHALLENGE ]]
    local challenge=${BASH_REMATCH[1]}
    echo $challenge
}

gen_hmacmd5() {
    echo -n $1 | openssl dgst -md5 -hmac "" | sed 's/^.* //'
}

post_info() {
    local challenge=$1
    local json="{\"acid\":\"$2\",\"enc_ver\":\"srun_bx1\",\"ip\":\"\",\"password\":\"$PASSWORD\",\"username\":\"$USERNAME\"}"
    echo -n $json | sed 's/ //g' | sed 's/"acid":"\([0-9]\+\)"/"acid":\1/g' > $SCRIPT_DIR/data.txt
    log_debug "encoded_json: $($SCRIPT_DIR/.tea $challenge $SCRIPT_DIR/data.txt $SCRIPT_DIR/encoded_output.bin)" # note that tea also writes to stdout, which will pop up in the output
    echo $(base64 $SCRIPT_DIR/encoded_output.bin | tr -d '\n' | tr \
       'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/' \
       'LVoJPiCN2R8G90yg+hmFHuacZ1OWMnrsSTXkYpUq/3dlbfKwv6xztjI7DeBE45QA')
    rm -f $SCRIPT_DIR/data.txt $SCRIPT_DIR/encoded_output.bin
}

login() {
    [ -f "$SCRIPT_DIR/.env" ] && source "$SCRIPT_DIR/.env"
    check_user
    log_debug "begin login"
    local ac_id=$(fetch_ac_id)
    local challenge=$(fetch_challenge)
    log_debug "challenge: $challenge"
    local info="{SRBX1}$(post_info $challenge $ac_id)"
    log_debug "info: $info"
    local password_md5=$(gen_hmacmd5 $challenge)
    log_debug "password_md5: {MD5}$password_md5"
    local checksum="$challenge$USERNAME$challenge$password_md5$challenge$ac_id$challenge${challenge}200${challenge}1$challenge$info"
    local checksum=$(echo -n $checksum | openssl sha1 -hex | sed 's/SHA1(stdin)= //g')
    log_debug "checksum: $checksum"
    log_debug "make login request"
    local res=$(curl -s "$REDIRECT_URI")
    [[ $res =~ $REGEX_AC_ID ]]
    ipv=${BASH_REMATCH[1]}
    if [ -z "$ipv" ]; then
        ipv="4"
    fi
    local AUTH_LOG_URL=$([ "$ipv" == "6" ] && echo $AUTH6_LOG_URL || echo $AUTH4_LOG_URL)
    local response=$(curl -s -X POST "$AUTH_LOG_URL" \
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
    local REGEX_SUC_MSG='"suc_msg":"([^"]+)"'
    [[ $response =~ $REGEX_SUC_MSG ]]
    local suc_msg=${BASH_REMATCH[1]}
    if [ "$suc_msg" != "login_ok" ]; then
        log_error "$suc_msg"
        exit 1
    else
        log_info "$suc_msg"
        exit 0
    fi
}

logout() {
    [ -f "$SCRIPT_DIR/.env" ] && source "$SCRIPT_DIR/.env"
    check_user
    log_debug "begin logout"
    local res=$(curl -s "$REDIRECT_URI")
    [[ $res =~ $REGEX_AC_ID ]]
    ipv=${BASH_REMATCH[1]}
    if [ -z "$ipv" ]; then
        ipv="4"
    fi
    local AUTH_LOG_URL=$([ "$ipv" == "6" ] && echo $AUTH6_LOG_URL || echo $AUTH4_LOG_URL)
    local response=$(curl -s -X POST "$AUTH_LOG_URL" \
        -H "Content-Type: application/x-www-form-urlencoded" \
        --data-urlencode "action=logout" \
        --data-urlencode "ac_id=1" \
        --data-urlencode "double_stack=1" \
        --data-urlencode "username=$USERNAME" \
        --data-urlencode "callback=callback")
    log_debug "response: $response"
    local REGEX_SUC_MSG='"error":"([^"]+)"'
    [[ $response =~ $REGEX_SUC_MSG ]]
    local suc_msg=${BASH_REMATCH[1]}
    log_info "$suc_msg"
    if [ "$suc_msg" != "ok" ]; then
        local REGEX_ERROR_MSG='"error_msg":"([^"]+)"'
        [[ $response =~ $REGEX_ERROR_MSG ]]
        local error_msg=${BASH_REMATCH[1]}
        log_error "$error_msg"
        exit 1
    else
        exit 0
    fi
}

whoami() {
    local user=$(curl -s $AUTH4_USER_INFO | cut -d',' -f1)
    if [ -z "$user" ]; then
        log_error "not logged in"
        exit 1
    else
        log_info "$user"
        exit 0
    fi
}

set_config() {
    USERNAME="${TUNET_USERNAME}"
    PASSWORD="${TUNET_PASSWORD}"
    while [[ -z "$USERNAME" ]]; do
        read -p "username: " USERNAME
    done
    while [[ -z "$PASSWORD" ]]; do
        read -s -p "password: " PASSWORD
        echo
    done
    echo "export TUNET_USERNAME=$USERNAME" > $SCRIPT_DIR/.env
    echo "export TUNET_PASSWORD=$PASSWORD" >> $SCRIPT_DIR/.env
    chmod 600 $SCRIPT_DIR/.env
}

if [ "$1" == "login" ]; then
    login
elif [ "$1" == "logout" ]; then
    logout
elif [ "$1" == "whoami" ]; then
    whoami
elif [ "$1" == "config" ]; then
    set_config
else
    echo "Usage: $0 login | logout | whoami | config"
    exit 1
fi

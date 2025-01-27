#!/usr/bin/bash

AUTH4_LOG_URL="https://auth4.tsinghua.edu.cn/cgi-bin/srun_portal"
AUTH4_USER_INFO="https://auth4.tsinghua.edu.cn/cgi-bin/rad_user_info"
AUTH4_CHALLENGE_URL="https://auth4.tsinghua.edu.cn/cgi-bin/get_challenge"
AUTH6_LOG_URL="https://auth6.tsinghua.edu.cn/cgi-bin/srun_portal"
AUTH6_CHALLENGE_URL="https://auth6.tsinghua.edu.cn/cgi-bin/get_challenge"
REDIRECT_URL="http://info.tsinghua.edu.cn/"
REGEX_AC_ID='//auth([46])\.tsinghua\.edu\.cn/index_([0-9]+)\.html'

KEY_ARRAY_LENGTH=4

CACHE_DIR="$HOME/.cache/tunet_bash"
LOG_LEVEL=$LOG_LEVEL

key_array=()
data_array=()

fill_key() {
    local key="$1"
    local array=()
    for ((i = 0; i < ${#key}; i++)); do
        local char=${key:$i:1}
        local value=$(printf "%d" "'$char")
        array+=($value)
    done
    while [ ${#array[@]} -lt 16 ]; do
        array+=(0)
    done
    local temp_u32
    for ((i = 0; i < KEY_ARRAY_LENGTH; i++)); do
        temp_u32=0
        for ((j = 0; j < 4; j++)); do
            temp_u32=$((temp_u32 | (array[$((i * 4 + j))] << (8 * j))))
        done
        key_array[i]=$temp_u32
    done
}

fill_data() {
    local data="$1"
    local data_len=${#data}
    for ((i = 0; i < data_len; i++)); do
        local char=${data:$i:1}
        data_array+=($(printf "%d" "'$char"))
    done
    local n=$(((data_len + 3) / 4))
    local out_len=$(((n + 1) * 4))
    while [ ${#data_array[@]} -lt $out_len ]; do
        data_array+=(0)
    done
    data_array[$((out_len - 4))]=$(($data_len & 0xFF))
    data_array[$((out_len - 3))]=$(($data_len >> 8 & 0xFF))
    data_array[$((out_len - 2))]=$(($data_len >> 16 & 0xFF))
    data_array[$((out_len - 1))]=$(($data_len >> 24 & 0xFF))
}

encode() {
    local n=$((${#data_array[@]} / 4 - 1))
    local q=$((6 + 52 / (n + 1)))
    local d=0
    local z=0
    for ((i = 0; i < 4 && $((n * 4 + i)) < ${#data_array[@]}; i++)); do
        z=$((z | (data_array[$((n * 4 + i))] << (8 * i))))
    done
    for ((i = 0; i < q; i++)); do
        d=$((d + 0x9E3779B9))
        local e=$(((d >> 2) & 3))
        for ((p = 0; p <= n; p++)); do
            local y_index=$((((p + 1) % (n + 1)) * 4))
            local y=0
            for ((j = 0; j < 4 && $((y_index + j)) < ${#data_array[@]}; j++)); do
                y=$((y | (data_array[$((y_index + j))] << (8 * j))))
            done
            local m=$(((z >> 5) ^ (y << 2)))
            m=$((m + ((y >> 3) ^ (z << 4) ^ (d ^ y))))
            m=$((m + (key_array[$(((p & 3) ^ e))] ^ z)))
            local m_index=$((p * 4))
            local temp_m=$((data_array[$m_index] | (data_array[$((m_index + 1))] << 8) | (data_array[$((m_index + 2))] << 16) | (data_array[$((m_index + 3))] << 24)))
            m=$((m + temp_m))
            m=$((m & 0xFFFFFFFF))
            data_array[$((m_index + 0))]=$((m & 0xFF))
            data_array[$((m_index + 1))]=$(((m >> 8) & 0xFF))
            data_array[$((m_index + 2))]=$(((m >> 16) & 0xFF))
            data_array[$((m_index + 3))]=$(((m >> 24) & 0xFF))
            z=$m
        done
    done
    for ((i = 0; i < ${#data_array[@]}; i++)); do
        local hex=$(printf "%x" ${data_array[$i]})
        echo -e -n "\x$hex"
    done
}

tea() {
    fill_key "$1"
    fill_data "$2"
    encode
}

[ -z $LOG_LEVEL ] && LOG_LEVEL="info"

log_date() {
    echo "[$(date --rfc-3339 s)]"
}

log_error() {
    echo "$(log_date) ERROR $1" >&2
}

check_user() {
    USERNAME=$TUNET_USERNAME
    PASSWORD=$TUNET_PASSWORD
    if [ -z $USERNAME ]; then
        log_error "TUNET_USERNAME is not set"
        exit 1
    fi
    if [ -z $PASSWORD ]; then
        log_error "TUNET_PASSWORD is not set"
        exit 1
    fi
}

log_debug() {
    [ $LOG_LEVEL == "debug" ] && echo -e "$(log_date) DEBUG $1" >&2
}

log_info() {
    if [ $LOG_LEVEL == "info" ] || [ $LOG_LEVEL == "debug" ]; then
        echo -e "$(log_date) INFO $1" >&2
    fi
}

fetch_ac_id() {
    log_debug "fetch ac_id"
    local res=$(curl -s $REDIRECT_URL)
    [[ $res =~ $REGEX_AC_ID ]]
    ipv=${BASH_REMATCH[1]}
    if [ -z $ipv ]; then
        ipv=4
    fi
    log_debug "ip version $ipv"
    local ac_id=${BASH_REMATCH[2]}
    if [ -z $ac_id ]; then
        log_debug "ac_id not found, using 1 as default"
        echo "1"
    else
        echo $ac_id
    fi
}

fetch_challenge() {
    log_debug "fetch challenge"
    local res=$(curl -s $REDIRECT_URL)
    [[ $res =~ $REGEX_AC_ID ]]
    ipv=${BASH_REMATCH[1]}
    if [ -z $ipv ]; then
        ipv=4
    fi
    local AUTH_CHALLENGE_URL=$([ $ipv == 6 ] && echo $AUTH6_CHALLENGE_URL || echo $AUTH4_CHALLENGE_URL)
    local res=$(curl -s $AUTH_CHALLENGE_URL --data-urlencode "username=$USERNAME" --data-urlencode "double_stack=1" --data-urlencode "ip=" --data-urlencode "callback=callback")
    local REGEX_CHALLENGE='"challenge":"([^"]+)"'
    [[ $res =~ $REGEX_CHALLENGE ]]
    local challenge=${BASH_REMATCH[1]}
    echo $challenge
}

gen_hmacmd5() {
    echo -n $1 | openssl dgst -md5 -hmac "" -r | cut -d ' ' -f 1
}

post_info() {
    local challenge=$1
    local json="{\"acid\":\"$2\",\"enc_ver\":\"srun_bx1\",\"ip\":\"\",\"password\":\"$PASSWORD\",\"username\":\"$USERNAME\"}"
    local data=$(echo -n $json | sed 's/ //g' | sed 's/"acid":"\([0-9]\+\)"/"acid":\1/g')
    echo $(tea $challenge $data | base64 | tr -d '\n' | tr \
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/' \
        'LVoJPiCN2R8G90yg+hmFHuacZ1OWMnrsSTXkYpUq/3dlbfKwv6xztjI7DeBE45QA')
}

login() {
    [ -f "$CACHE_DIR/passwd" ] && source "$CACHE_DIR/passwd"
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
    local checksum=$(echo -n $checksum | openssl sha1 -hex -r | cut -d ' ' -f 1)
    log_debug "checksum: $checksum"
    log_debug "make login request"
    local res=$(curl -s $REDIRECT_URL)
    [[ $res =~ $REGEX_AC_ID ]]
    ipv=${BASH_REMATCH[1]}
    if [ -z $ipv ]; then
        ipv=4
    fi
    local AUTH_LOG_URL=$([ $ipv == 6 ] && echo $AUTH6_LOG_URL || echo $AUTH4_LOG_URL)
    local response=$(curl -s -X POST $AUTH_LOG_URL \
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
        if [ -z $suc_msg ]; then
            local REGEX_ERR_MSG='"error_msg":"([^"]+)"'
            [[ $response =~ $REGEX_ERR_MSG ]]
            local err_msg=${BASH_REMATCH[1]}
            log_error "$err_msg"
        else
            log_error "$suc_msg"
        fi
        exit 1
    else
        log_info "$suc_msg"
        exit 0
    fi
}

logout() {
    [ -f "$CACHE_DIR/passwd" ] && source "$CACHE_DIR/passwd"
    check_user
    log_debug "begin logout"
    local res=$(curl -s $REDIRECT_URL)
    [[ $res =~ $REGEX_AC_ID ]]
    ipv=${BASH_REMATCH[1]}
    if [ -z $ipv ]; then
        ipv=4
    fi
    local AUTH_LOG_URL=$([ $ipv == 6 ] && echo $AUTH6_LOG_URL || echo $AUTH4_LOG_URL)
    local response=$(curl -s -X POST $AUTH_LOG_URL \
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
    if [ "$suc_msg" != "ok" ]; then
        local REGEX_ERROR_MSG='"error_msg":"([^"]+)"'
        [[ $response =~ $REGEX_ERROR_MSG ]]
        local error_msg=${BASH_REMATCH[1]}
        log_error "$error_msg"
        exit 1
    else
        log_info "$suc_msg"
        exit 0
    fi
}

whoami() {
    local res=$(curl -s $AUTH4_USER_INFO)
    log_debug "res: $res"
    local cnt=$(echo $res | tr ',' '\n' | wc -l)
    log_debug "cnt: $cnt"
    local user=$(echo $res | cut -d ',' -f1)
    if [ $cnt != 22 ]; then
        log_error $user
        exit 1
    else
        log_info $user
        exit 0
    fi
}

set_config() {
    USERNAME=$TUNET_USERNAME
    PASSWORD=$TUNET_PASSWORD
    while [[ -z $USERNAME ]]; do
        read -p "username: " USERNAME
    done
    while [[ -z $PASSWORD ]]; do
        read -s -p "password: " PASSWORD
        echo
    done
    echo "export TUNET_USERNAME=$USERNAME" >$CACHE_DIR/passwd
    echo "export TUNET_PASSWORD=$PASSWORD" >>$CACHE_DIR/passwd
    chmod 600 $CACHE_DIR/passwd
}

mkdir -p $CACHE_DIR
script_name=$(basename "$0")
args=$(getopt -o c:l:o:w --long config:,login,logout,whoami -n "$script_name" -- "$@")
if [ $? != 0 ] ; then exit 1 ; fi

while true; do
    case "$1" in
        -c | --config ) set_config; exit 0 ;;
        -l | --login ) login; exit 0 ;;
        -o | --logout ) logout; exit 0 ;;
        -w | --whoami ) whoami; exit 0 ;;
        -- ) shift; break ;;
        * ) break ;;
    esac
done
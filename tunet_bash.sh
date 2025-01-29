#!/usr/bin/bash

set -o pipefail

AUTH4_LOG_URL="https://auth4.tsinghua.edu.cn/cgi-bin/srun_portal"
AUTH4_CHALLENGE_URL="https://auth4.tsinghua.edu.cn/cgi-bin/get_challenge"
AUTH6_LOG_URL="https://auth6.tsinghua.edu.cn/cgi-bin/srun_portal"
AUTH6_CHALLENGE_URL="https://auth6.tsinghua.edu.cn/cgi-bin/get_challenge"
AUTH4_USER_INFO="https://auth4.tsinghua.edu.cn/cgi-bin/rad_user_info"
AUTH6_USER_INFO="https://auth6.tsinghua.edu.cn/cgi-bin/rad_user_info"
AUTH4_USER_INFO_JSON="$AUTH4_USER_INFO?callback=any"
AUTH6_USER_INFO_JSON="$AUTH6_USER_INFO?callback=any"
REGEX_USER_INFO_JSON='"online_device_total":"([^"]+)"[^}]*"user_balance":([^,]+)[^}]*"user_mac":"([^"]+)"'
REDIRECT_URL="http://info.tsinghua.edu.cn/"
REGEX_AC_ID='//auth[46]\.tsinghua\.edu\.cn/index_([0-9]+)\.html'

KEY_ARRAY_LENGTH=4

CACHE_DIR="$HOME/.cache/tunet_bash"
LOG_LEVEL=${TUNET_LOG_LEVEL:-"info"}

key_array=()
data_array=()

verbose=0
ipv=4
date_format="--rfc-3339 s"

fill_key() {
    local key="$1"
    local array=()
    for ((i = 0; i < ${#key}; i++)); do
        local char=${key:$i:1}
        local value=$(printf "%d" "'$char")
        local array+=($value)
    done
    while [ ${#array[@]} -lt 16 ]; do
        local array+=(0)
    done
    for ((i = 0; i < KEY_ARRAY_LENGTH; i++)); do
        local temp_u32=0
        for ((j = 0; j < 4; j++)); do
            local temp_u32=$((temp_u32 | (array[$((i * 4 + j))] << (8 * j))))
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
        local z=$((z | (data_array[$((n * 4 + i))] << (8 * i))))
    done
    for ((i = 0; i < q; i++)); do
        local d=$((d + 0x9E3779B9))
        local e=$(((d >> 2) & 3))
        for ((p = 0; p <= n; p++)); do
            local y_index=$((((p + 1) % (n + 1)) * 4))
            local y=0
            for ((j = 0; j < 4 && $((y_index + j)) < ${#data_array[@]}; j++)); do
                local y=$((y | (data_array[$((y_index + j))] << (8 * j))))
            done
            local m=$(((z >> 5) ^ (y << 2)))
            local m=$((m + ((y >> 3) ^ (z << 4) ^ (d ^ y))))
            local m=$((m + (key_array[$(((p & 3) ^ e))] ^ z)))
            local m_index=$((p * 4))
            local temp_m=$((data_array[$m_index] | (data_array[$((m_index + 1))] << 8) | (data_array[$((m_index + 2))] << 16) | (data_array[$((m_index + 3))] << 24)))
            local m=$((m + temp_m))
            local m=$((m & 0xFFFFFFFF))
            data_array[$((m_index + 0))]=$((m & 0xFF))
            data_array[$((m_index + 1))]=$(((m >> 8) & 0xFF))
            data_array[$((m_index + 2))]=$(((m >> 16) & 0xFF))
            data_array[$((m_index + 3))]=$(((m >> 24) & 0xFF))
            local z=$m
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

log_date() {
    echo "[$(date $date_format)]"
}

log_error() {
    if [ $LOG_LEVEL == "info" ] || [ $LOG_LEVEL == "debug" ] ||
        [ $LOG_LEVEL == "error" ]; then
        echo "$(log_date) ERROR $1" >&2
    fi
}

check_user() {
    USERNAME=$TUNET_USERNAME
    if [ -z $USERNAME ]; then
        log_error "TUNET_USERNAME is not set"
        exit 1
    fi

}

check_pass() {
    PASSWORD=$TUNET_PASSWORD
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
    local ac_id=${BASH_REMATCH[1]}
    if [ -z $ac_id ]; then
        log_debug "ac_id not found, using 1 as default"
        echo "1"
    else
        log_debug "ac_id: $ac_id"
        echo $ac_id
    fi
}

fetch_challenge() {
    log_debug "fetch challenge v$ipv"
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
    check_pass
    log_debug "begin auth$ipv login"
    local ac_id=$(fetch_ac_id)
    local challenge=$(fetch_challenge "$ipv")
    log_debug "challenge: $challenge"
    local info="{SRBX1}$(post_info $challenge $ac_id)"
    log_debug "info: $info"
    local password_md5=$(gen_hmacmd5 $challenge)
    log_debug "password_md5: {MD5}$password_md5"
    local checksum="$challenge$USERNAME$challenge$password_md5$challenge$ac_id$challenge${challenge}200${challenge}1$challenge$info"
    local checksum=$(echo -n $checksum | openssl sha1 -hex -r | cut -d ' ' -f 1)
    log_debug "checksum: $checksum"
    log_debug "make login request"
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
    log_debug "begin auth$ipv logout"
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
    local AUTH_USER_INFO=$([ $ipv == 6 ] && echo $AUTH6_USER_INFO || echo $AUTH4_USER_INFO)
    local res=$(curl -s $AUTH_USER_INFO)
    log_debug "res: $res"
    local cnt=$(echo $res | tr ',' '\n' | wc -l)
    log_debug "cnt: $cnt"
    local user=$(echo $res | cut -d ',' -f1)
    if [ $cnt != 22 ]; then
        log_error $user
        exit 1
    else
        log_info $user
        if [ $verbose -eq 1 ]; then
            printf "%-27s %-6s %-7s %-8s %-16s %-17s %-17s %-19s %-18s %-s\n" \
                "LOGIN" "UP(h)" "DEVICE" "BALANCE" "TRAFFIC_IN(MiB)" "TRAFFIC_OUT(MiB)" \
                "TRAFFIC_SUM(MiB)" "TRAFFIC_TOTAL(GiB)" "MAC" "IP"
            local login=$(echo $res | cut -d ',' -f2)
            local online=$(echo $res | cut -d ',' -f3)
            local online=$((online - login))
            local online=$(awk "BEGIN {printf \"%.2f\n\", $online / 3600}")
            local login=$(date -d "@$login" --rfc-3339 s)
            local in=$(echo $res | cut -d ',' -f4)
            local out=$(echo $res | cut -d ',' -f5)
            local tot=$(echo $res | cut -d ',' -f7)
            local sum=$((in + out))
            local in=$(awk "BEGIN {printf \"%.2f\n\", $in / 1048576}")
            local out=$(awk "BEGIN {printf \"%.2f\n\", $out / 1048576}")
            local sum=$(awk "BEGIN {printf \"%.2f\n\", $sum / 1048576}")
            local tot=$(awk "BEGIN {printf \"%.2f\n\", $tot / 1073741824}")
            local ip=$(echo $res | cut -d ',' -f9)
            local AUTH_USER_INFO_JSON=$([ $ipv == 6 ] && echo $AUTH6_USER_INFO_JSON || echo $AUTH4_USER_INFO_JSON)
            local res=$(curl -s $AUTH_USER_INFO_JSON)
            [[ $res =~ $REGEX_USER_INFO_JSON ]]
            log_debug "json: $res"
            local device=${BASH_REMATCH[1]}
            local balance=${BASH_REMATCH[2]}
            local mac=${BASH_REMATCH[3]}
            local mac=$(echo -n "$mac" | tr -- '-ABCDEF' ':abcdef')
            printf "%-27s %-6s %-7s %-8s %-16s %-17s %-17s %-19s %-18s %-s\n" \
                "$login" "$online" "$device" "$balance" \
                "$in" "$out" "$sum" "$tot" "$mac" "$ip"
        fi
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
op="whoami"
while [[ $# -gt 0 ]]; do
    case "$1" in
    -c | --config)
        set_config
        exit 0
        ;;
    -i | --login)
        op="login"
        shift
        ;;
    -o | --logout)
        op="logout"
        shift
        ;;
    -w | --whoami)
        op="whoami"
        shift
        ;;
    -v | --verbose)
        verbose=1
        shift
        ;;
    -a | --auth)
        ipv="$2"
        shift 2
        ;;
    --date-format)
        date_format="$2"
        shift 2
        ;;
    --)
        shift
        break
        ;;
    *)
        echo "Unknown option: $1" >&2
        exit 1
        ;;
    esac
done

if [ "$ipv" = "auto" ]; then
    REGEX_IPV='//auth([46])\.tsinghua\.edu\.cn'
    res=$(curl -s $REDIRECT_URL)
    [[ $res =~ $REGEX_IPV ]]
    ipv=${BASH_REMATCH[1]}
    if [ -z $ipv ]; then
        ipv=4
    fi
    log_debug "ipv: $ipv"
fi

if [[ "$ipv" != "4" ]] && [[ $ipv != "6" ]]; then
    echo "Unknown auth method: $ipv" >&2
    exit 1
fi

case $op in
whoami)
    whoami
    ;;
login)
    login
    ;;
logout)
    logout
    ;;
esac

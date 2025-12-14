#!/bin/bash

set -o pipefail

LC_ALL=C.UTF-8
LANG=$LC_ALL

NAME='tunet-bash'
VERSION='1.3.3'

REDIRECT_URL='http://info.tsinghua.edu.cn/'
TUNET_BASE_AUTH4='https://auth4.tsinghua.edu.cn'
TUNET_BASE_AUTH6='https://auth6.tsinghua.edu.cn'
TUNET_BASE_AUTH='https://auth.tsinghua.edu.cn'
REGEX_USER_INFO_JSON='"billing_name":"([^"]+)".*"online_device_total":"([^"]+)"[^}]*"products_name":"([^"]+)"[^}]*"sysver":"([^"]+)"[^}]*"user_balance":([^,]+)[^}]*"user_mac":"([^"]+)"'
REGEX_AC_ID='//auth[46]\.tsinghua\.edu\.cn/index_([0-9]+)\.html'

KEY_ARRAY_LENGTH=4

CACHE_DIR="$HOME/.cache/$NAME"
LOG_LEVEL=${LOG:-'info'}

key_array=()
data_array=()
curl_extra_args=()

verbose=0
ipv=auto
op='whoami'

auth_url() {
	local kind="$1"
	case "$kind" in
		login)
			if [[ "$ipv" == "6" ]]; then
				echo "$TUNET_BASE_AUTH6/cgi-bin/srun_portal"
			elif [[ "$ipv" == "4" ]]; then
				echo "$TUNET_BASE_AUTH4/cgi-bin/srun_portal"
			else
				echo "$TUNET_BASE_AUTH/cgi-bin/srun_portal"
			fi
			;;
		logout)
			if [[ "$ipv" == "6" ]]; then
				echo "$TUNET_BASE_AUTH6/cgi-bin/rad_user_dm"
			elif [[ "$ipv" == "4" ]]; then
				echo "$TUNET_BASE_AUTH4/cgi-bin/rad_user_dm"
			else
				echo "$TUNET_BASE_AUTH/cgi-bin/rad_user_dm"
			fi
			;;
		web)
			if [[ "$ipv" == "6" ]]; then
				echo "$TUNET_BASE_AUTH6/srun_portal_pc"
			elif [[ "$ipv" == "4" ]]; then
				echo "$TUNET_BASE_AUTH4/srun_portal_pc"
			else
				echo "$TUNET_BASE_AUTH/srun_portal_pc"
			fi
			;;
		challenge)
			if [[ "$ipv" == "6" ]]; then
				echo "$TUNET_BASE_AUTH6/cgi-bin/get_challenge"
			elif [[ "$ipv" == "4" ]]; then
				echo "$TUNET_BASE_AUTH4/cgi-bin/get_challenge"
			else
				echo "$TUNET_BASE_AUTH/cgi-bin/get_challenge"
			fi
			;;
		user-info)
			if [[ "$ipv" == "6" ]]; then
				echo "$TUNET_BASE_AUTH6/cgi-bin/rad_user_info"
			elif [[ "$ipv" == "4" ]]; then
				echo "$TUNET_BASE_AUTH4/cgi-bin/rad_user_info"
			else
				echo "$TUNET_BASE_AUTH/cgi-bin/rad_user_info"
			fi
			;;
		*)
			return 1
			;;
	esac
}

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
	for ((i = 0; i < KEY_ARRAY_LENGTH; i++)); do
		local temp_u32=0
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
			m_index=$((p * 4))
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

log_error() {
	if [ $LOG_LEVEL == "info" ] || [ $LOG_LEVEL == "debug" ] ||
		[ $LOG_LEVEL == "error" ]; then
		echo "ERROR $1" >&2
	fi
}

log_debug() {
	[ $LOG_LEVEL == "debug" ] && echo -e "DEBUG $1" >&2
}

log_info() {
	if [ $LOG_LEVEL == "info" ] || [ $LOG_LEVEL == "debug" ]; then
		echo -e "INFO  $1" >&2
	fi
}

check_user() {
	USERNAME=${USERNAME:-"$TUNET_USERNAME"}
	if [ -z $USERNAME ]; then
		log_error "please configure username"
		exit 1
	fi
}

check_pass() {
	PASSNAME=${PASSNAME:-"$TUNET_PASSNAME"}
	PASSWORD=${PASSWORD:-"$TUNET_PASSWORD"}
	if [ -z $PASSNAME ]; then
		if [ -z $PASSWORD ]; then
			log_error "please configure password"
			exit 1
		else
			PASSWORD="$(echo -n $PASSWORD | base64 -d)"
		fi
	else
		log_debug "passname: $PASSNAME"
		PASSWORD="$(pass show "$PASSNAME")"
	fi
}

run_curl() {
	local _outvar="$1"
	shift
	local _res
	local _err_file
	_err_file=$(mktemp)

	# -sS: Silent mode but show errors.
	# Capture stderr to a temp file to report specific errors on failure.
	_res=$(curl -sS "${curl_extra_args[@]}" "$@" 2>"$_err_file")
	local _ret=$?

	if [ $_ret -ne 0 ]; then
		local _err_msg
		_err_msg=$(cat "$_err_file")
		rm -f "$_err_file"
		log_error "curl connection failed: $_err_msg"
		exit 1
	fi
	rm -f "$_err_file"
	printf -v "$_outvar" '%s' "$_res"
}

fetch_ac_id() {
	local res
	run_curl res $REDIRECT_URL
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
	local AUTH_CHALLENGE_URL=$(auth_url challenge)
	local res
	run_curl res "$AUTH_CHALLENGE_URL" --data-urlencode "username=$USERNAME" --data-urlencode "double_stack=1" --data-urlencode "ip=$1" --data-urlencode "callback=callback"
	local REGEX_CHALLENGE='"challenge":"([^"]+)"'
	[[ $res =~ $REGEX_CHALLENGE ]] && local challenge=${BASH_REMATCH[1]}
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

check_perm() {
	if [ -f "$CACHE_DIR/passwd" ]; then
		if [ $(stat -c "%a" "$CACHE_DIR/passwd") != "600" ]; then
			log_error "permission is too open: $CACHE_DIR/passwd"
			exit 1
		else
			source "$CACHE_DIR/passwd"
		fi
	fi
}

login() {
	check_perm
	check_user
	check_pass
	log_info "auth($ipv) login"
	log_debug "username: $USERNAME"
	local ac_id=$(fetch_ac_id)
	local n="200"
	local type="1"
	local AUTH_WEB_URL=$(auth_url web)
	local res
	run_curl res "$AUTH_WEB_URL" \
		--data-urlencode "theme=pro" \
		--data-urlencode "ac_id=$ac_id"
	local REGEX_IP='ip[[:space:]]*\:[[:space:]]*"([a-f0-9\.\:]+)"'
	[[ $res =~ $REGEX_IP ]] && local ip=${BASH_REMATCH[1]}
	log_debug "ip: $ip"
	local token=$(fetch_challenge "$ip")
	log_debug "token: $token"
	local info="{SRBX1}$(post_info $token $ac_id)"
	log_debug "info: <edited>"
	local password_md5=$(gen_hmacmd5 $token)
	log_debug "password_md5: {MD5}<edited>"
	local AUTH_LOGIN_URL=$(auth_url login)
	local checksum="$token$USERNAME$token$password_md5$token$ac_id$token$ip$token$n$token$type$token$info"
	checksum=$(echo -n $checksum | sha1sum -z | cut -d ' ' -f 1)
	log_debug "checksum: $checksum"
	local res
	run_curl res "$AUTH_LOGIN_URL" \
		--data-urlencode "action=login" \
		--data-urlencode "ac_id=$ac_id" \
		--data-urlencode "double_stack=1" \
		--data-urlencode "n=$n" \
		--data-urlencode "ip=$ip" \
		--data-urlencode "type=$type" \
		--data-urlencode "os=Linux" \
		--data-urlencode "name=Linux" \
		--data-urlencode "username=$USERNAME" \
		--data-urlencode "password={MD5}$password_md5" \
		--data-urlencode "info=$info" \
		--data-urlencode "chksum=$checksum" \
		--data-urlencode "callback=callback"

	local REGEX_SUC_MSG='"suc_msg":"([^"]+)"'
	[[ $res =~ $REGEX_SUC_MSG ]] && local suc_msg=${BASH_REMATCH[1]}
	if [ "$suc_msg" != "login_ok" ]; then
		log_debug "$AUTH_LOGIN_URL: \"$res\""
		if [ -z $suc_msg ]; then
			local REGEX_ERR_MSG='"error":"([^"]+)"'
			[[ $res =~ $REGEX_ERR_MSG ]]
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
	check_perm
	check_user
	log_info "auth($ipv) logout"
	log_debug "username: $USERNAME"
	local AUTH_LOGOUT_URL=$(auth_url logout)
	local time=$(date +%s)
	local res
	run_curl res "$(auth_url user-info)"
	local ip=$(echo $res | cut -d ',' -f9)
	local unbind="1"
	log_debug "ip: $ip"
	local sign=$(echo -n "$time$USERNAME$ip$unbind$time" | sha1sum -z | cut -d ' ' -f 1)
	if [ -z "$ip" ]; then
		log_error "not online"
		exit 1
	fi
	local response
	run_curl response $AUTH_LOGOUT_URL \
		--data-urlencode "unbind=1" \
		--data-urlencode "time=$time" \
		--data-urlencode "ip=$ip" \
		--data-urlencode "sign=$sign" \
		--data-urlencode "username=$USERNAME" \
		--data-urlencode "callback=callback"

	local REGEX_SUC_MSG='"error":"([^"]+)"'
	[[ $response =~ $REGEX_SUC_MSG ]]
	local suc_msg=${BASH_REMATCH[1]}
	if [ "$suc_msg" != "ok" ]; then
		log_debug "$AUTH_LOGOUT_URL: \"$response\""
		log_error "$suc_msg"
		exit 1
	else
		log_info "$suc_msg"
		exit 0
	fi
}

assert() {
	("$NAME" -w -a "$ipv" || ("$NAME" -w -a 4 || "$NAME" -w -a 6)) ||
		"$NAME" -i -a "$ipv"
}

whoami() {
	local res
	run_curl res "$(auth_url user-info)"
	log_debug "$(auth_url user-info): $res"
	local cnt=$(echo $res | tr ',' '\n' | wc -l)
	if [ $cnt != 22 ]; then
		log_error "possibly not online"
		exit 1
	else
		local user=$(echo $res | cut -d ',' -f1)
		if [ $verbose -eq 1 ]; then
			local login=$(echo $res | cut -d ',' -f2)
			local online=$(echo $res | cut -d ',' -f3)
			local online=$((online - login))
			local online=$(awk "BEGIN {printf \"%.2f\n\", $online / 3600}")
			local login=$(date -d "@$login" "--iso-8601=seconds")
			local in=$(echo $res | cut -d ',' -f4)
			local out=$(echo $res | cut -d ',' -f5)
			local tot=$(echo $res | cut -d ',' -f7)
			local sum=$((in + out))
			local in=$(awk "BEGIN {printf \"%.2f\n\", $in / 1048576}")
			local out=$(awk "BEGIN {printf \"%.2f\n\", $out / 1048576}")
			local sum=$(awk "BEGIN {printf \"%.2f\n\", $sum / 1048576}")
			local tot=$(awk "BEGIN {printf \"%.2f\n\", $tot / 1073741824}")
			local ip=$(echo $res | cut -d ',' -f9)
			local res
			run_curl res "$(auth_url user-info)?callback=any"
			[[ $res =~ $REGEX_USER_INFO_JSON ]]
			local billing_name=${BASH_REMATCH[1]}
			local device=${BASH_REMATCH[2]}
			local products_name=${BASH_REMATCH[3]}
			local sysver=${BASH_REMATCH[4]}
			local balance=${BASH_REMATCH[5]}
			local mac=${BASH_REMATCH[6]}
			local mac=$(echo -n "$mac" | tr -- '-ABCDEF' ':abcdef')
			local label_width=18
			printf "%-${label_width}s %s\n" "Username:" "$user"
			printf "%-${label_width}s %s\n" "Session Start:" "$login"
			printf "%-${label_width}s %s h\n" "Session Age:" "$online"
			printf "%-${label_width}s %s\n" "Billing Profile:" "$billing_name"
			printf "%-${label_width}s %s\n" "Product Plan:" "$products_name"
			printf "%-${label_width}s %s\n" "Online Devices:" "$device"
			printf "%-${label_width}s %s CNY\n" "Balance:" "$balance"
			printf "%-${label_width}s %s Mi\n" "Session Inbound:" "$in"
			printf "%-${label_width}s %s Mi\n" "Session Outbound:" "$out"
			printf "%-${label_width}s %s Mi\n" "Session Total:" "$sum"
			printf "%-${label_width}s %s Gi\n" "Monthly Total:" "$tot"
			printf "%-${label_width}s %s\n" "MAC Address:" "$mac"
			printf "%-${label_width}s %s\n" "IP Address:" "$ip"
			if command -v jq >/dev/null 2>&1; then
				local res="${res:4:-1}"
				local device_detail=$(echo "$res" | jq -r '.online_device_detail // empty' 2>/dev/null)
				if [ -n "$device_detail" ] && [ "$device_detail" != "null" ]; then
					echo
					printf "%-${label_width}s\n" "Device Details:"
					local device_num=1
					echo "$device_detail" | jq -r 'to_entries[] | "\(.key)|\(.value.ip)|\(.value.ip6)|\(.value.class_name)|\(.value.os_name)"' 2>/dev/null | while IFS='|' read -r device_id device_ip device_ip6 device_class device_os; do
						[ -z "$device_id" ] && continue
						local device_indent=$(printf "%*s" 2 "")
						local field_indent=$(printf "%*s" 4 "")
						local field_width=$((label_width - 4))
						printf "${device_indent}Device %d:\n" "$device_num"
						printf "${field_indent}%-${field_width}s %s\n" "Rad Online ID:" "$device_id"
						printf "${field_indent}%-${field_width}s %s\n" "IPv4 Address:" "${device_ip:-N/A}"
						printf "${field_indent}%-${field_width}s %s\n" "IPv6 Address:" "${device_ip6:-N/A}"
						[ -n "$device_class" ] && [ "$device_class" != "" ] && printf "${field_indent}%-${field_width}s %s\n" "Class Name:" "$device_class"
						[ -n "$device_os" ] && [ "$device_os" != "" ] && printf "${field_indent}%-${field_width}s %s\n" "OS Name:" "$device_os"
						echo
						((device_num++))
					done
				else
					echo
					printf "%-${label_width}s %s\n" "Device Details:" "${dim}No details available${reset}"
				fi
			else
				log_info "jq not found, skipping device details parsing"
			fi
			printf "%-${label_width}s %s\n" "System Version:" "$sysver"
		else
			echo "$user"
		fi
		exit 0
	fi
}

help() {
	echo "See $NAME(1) for details."
	exit 0
}

config() {
	while [[ -z $USERNAME ]]; do
		read -p "username: " USERNAME
	done
	echo "export TUNET_USERNAME=$USERNAME" >"$CACHE_DIR/passwd"
	if [[ "$use_passname" == "yes" ]]; then
		while [[ -z $PASSNAME ]]; do
			read -p "passname: " PASSNAME
		done
		echo "export TUNET_PASSNAME=$PASSNAME" >>"$CACHE_DIR/passwd"
	else

		while [[ -z $PASSWORD ]]; do
			read -s -p "password: " PASSWORD
			echo
		done
		echo "export TUNET_PASSWORD=$(echo -n $PASSWORD | base64)" >>"$CACHE_DIR/passwd"
	fi
	chmod 600 "$CACHE_DIR/passwd"
}

preprocess_args() {
	local args=("$@")
	new_args=()
	local i=0
	while ((i < ${#args[@]})); do
		local arg="${args[i]}"
		case "$arg" in
			--)
				new_args+=("--")
				((i++))
				;;
			--*)
				new_args+=("$arg")
				((i++))
				;;
			-?*)
				local opt_str="${arg:1}"
				while [[ -n "$opt_str" ]]; do
					local opt_char="${opt_str:0:1}"
					new_args+=("-${opt_char}")
					opt_str="${opt_str:1}"
				done
				((i++))
				;;
			*)
				new_args+=("$arg")
				((i++))
				;;
		esac
	done
}

preprocess_args "$@"

set -- "${new_args[@]}"
mkdir -p "$CACHE_DIR"

while [[ $# -gt 0 ]]; do
	case "$1" in
		-h | --help)
			op="help"
			shift
			;;
		-c | --config)
			op="config"
			shift
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
		--assert)
			op="assert"
			shift
			;;
		--version)
			echo "$NAME $VERSION"
			exit 0
			;;
		--pass)
			use_passname="yes"
			shift
			;;
		--curl-extra-args)
			curl_extra_args+=($2)
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

if [ $ipv == "auto" ]; then
	REGEX_IPV='//auth([46])\.tsinghua\.edu\.cn'
	run_curl res $REDIRECT_URL
	if [[ $res =~ $REGEX_IPV ]]; then
		ipv="${BASH_REMATCH[1]}"
	else
		ipv="either"
	fi
fi

if [[ ! ($ipv == "4" || $ipv == "6" || "$ipv" == "either") ]]; then
	echo "Unknown auth version: $ipv" >&2
fi

case $op in
	help)
		help
		;;
	config)
		config
		;;
	whoami)
		whoami
		;;
	login)
		login
		;;
	assert)
		assert
		;;
	logout)
		logout
		;;
esac

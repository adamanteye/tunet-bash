#!/usr/bin/bash

key_array=()
data_array=()
KEY_ARRAY_LENGTH=4

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

fill_key $1
fill_data $2
encode

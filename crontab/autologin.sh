#!/usr/bin/env bash

LOG_FILE="$HOME/.cache/tunet-bash/access.log"

tunet-bash -w &>>$LOG_FILE
if [[ $? -ne 0 ]]; then
    tunet-bash -i -a auto &>>$LOG_FILE
fi

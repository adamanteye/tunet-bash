#!/bin/bash

LOG_FILE="$HOME/.cache/tunet-bash/access.log"

tunet-bash -w &>>$LOG_FILE
if [[ $? -ne 0 ]]; then
    tunet-bash -i &>>$LOG_FILE
fi

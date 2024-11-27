#!/bin/bash

export AUTH4_LOG_URL="https://auth4.tsinghua.edu.cn/cgi-bin/srun_portal"
export AUTH4_CHALLENGE_URL="https://auth4.tsinghua.edu.cn/cgi-bin/get_challenge"
export REDIRECT_URI="http://www.tsinghua.edu.cn/"
export REGEX_AC_ID='location.href="http://auth[46].tsinghua.edu.cn/index_([0-9]+)\.html'

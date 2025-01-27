tunet_bash(1)

# NAME

tunet_bash - Tsinghua University network authentication script

# SYNOPSIS

*tunet_bash* [_OPTIONS_]

# DESCRIPTION

*tunet_bash* is an authentication script for Tsinghua network.
It is written in bash with minimal dependencies.

# OPTIONS

*-c*,*--config*
	Specify the username and password for the account in use.
	They will be written to _$HOME/.cache/tunet_bash/passwd_.

	Once set, the username and password will be used for login
	and logout operations.

*-l*,*--login*
	Make login request.

*-o*,*--logout*
	Make logout request.

*-w*,*--whoami*
	Query account username currently online.

	Can also be used with a Tsinghua-Secure connection.

# ENVIRONMENT

*LOG_LEVEL*
	Possible values are _debug_ or _info_.

	However, error messages will always be printed.

*TUNET_USERNAME*
	If set, the username defined in _$HOME/.cache/tunet_bash/passwd_
	will be overridden.

*TUNET_PASSWORD*
	If set, the password defined in _$HOME/.cache/tunet_bash/passwd_
	will be overridden.

# FILES

$HOME/.cache/tunet_bash/passwd

# AUTHOR

Maintained by adamanteye <ada@adamanteye.cc>. Up-to-date sources are
available at _https://github.com/adamanteye/tunet_bash_.

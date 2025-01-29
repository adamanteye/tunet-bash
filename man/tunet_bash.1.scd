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
	Start an interactive prompt to specify
	the username and password for the account in use.
	The credentials will be saved to _$HOME/.cache/tunet_bash/passwd_.

	Once configured, these credentials will be used for login and logout operations.

*-i*,*--login*
	Make a login request.

	Defaults to auth4 unless *--v4* or *--v6* is specified.

*-o*,*--logout*
	Make a logout request.

	Defaults to auth4 unless *--v4* or *--v6* is specified.

*-w*,*--whoami*
	Make a status query of account currently online.

	Defaults to auth4 unless *--v4* or *--v6* is specified.

	Can also be used with a Tsinghua-Secure connection.

*--v4*
	Use auth4.

*--v6*
	Use auth6.

*-v*,*--verbose*
	When used with *-w*,*--whoami*, provides detailed account statistics.

# ENVIRONMENT

*LOG_LEVEL*
	Possible values are _debug_ or _info_.

	However, error messages will always be printed.

*TUNET_USERNAME*
	If set, it overrides username defined in _$HOME/.cache/tunet_bash/passwd_.

*TUNET_PASSWORD*
	If set, it overrides password defined in _$HOME/.cache/tunet_bash/passwd_.

# FILES

- $HOME/.cache/tunet_bash/passwd

# AUTHOR

Maintained by adamanteye <ada@adamanteye.cc>. Up-to-date sources are
available at _https://github.com/adamanteye/tunet_bash_.

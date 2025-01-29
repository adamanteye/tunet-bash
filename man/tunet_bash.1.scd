tunet_bash(1)

# NAME

tunet_bash - Tsinghua University network authentication script

# SYNOPSIS

*tunet_bash* [_OPTIONS_]

# DESCRIPTION

*tunet_bash* is an authentication script for Tsinghua University network.++
It is written in bash with minimal dependencies and assumptions.

# OPTIONS

*-c*,*--config*
	Start an interactive prompt to specify
	the username and password for the account in use.

	The credentials will be saved to _$HOME/.cache/tunet_bash/passwd_.

	Once configured, these credentials will be used for login and logout operations.

*-i*,*--login*
	Make a login request.

*-o*,*--logout*
	Make a logout request.

*-w*,*--whoami*
	Make a status query of account currently online.

	Can also be used with a Tsinghua-Secure connection.

*-a*,*--auth* _IP_VERSION_
	Specify using auth4 or auth6.

	Possible values of _IP_VERSION_ are _auto_, _4_ and _6_.

	The default _IP_VERSION_ is _auto_.

*--date-format* _DATE_FORMAT_
	Format string passed to *date* command.

	The default _DATE_FORMAT_ is *--rfc-3339 s*.

# EXAMPLES

*tunet_bash*
	No Options applied, defaults to make a status query.

*tunet_bash* *-c*
	Start an interactive prompt to configure username and password.

*tunet_bash* *-i*
	Make login request.

*tuent_bash* *-o* *-a* _6_
	Make logout request using auth6.

*tunet_bash* *-w* *-v* *--date-format* _"+%c"_
	Make detailed status query.

	Print log messages using *date* _"+%c"_

# ENVIRONMENT

*TUNET_LOG_LEVEL*
	Possible values are _debug_, _info_ or _error_.

	If set to others, no messages will be printed.

*TUNET_USERNAME*
	If set, it overrides username defined in _$HOME/.cache/tunet_bash/passwd_.

*TUNET_PASSWORD*
	If set, it overrides password defined in _$HOME/.cache/tunet_bash/passwd_.

# FILES

- $HOME/.cache/tunet_bash/passwd

# AUTHOR

Maintained by adamanteye <ada@adamanteye.cc>.++
Up-to-date sources are available at _https://github.com/adamanteye/tunet_bash_.

# SEE ALSO

*date*(1)

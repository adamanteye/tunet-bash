tunet-bash(1)

# NAME

tunet-bash - Tsinghua University network authentication utility

# SYNOPSIS

*tunet-bash* --config [--pass] [-v]++
*tunet-bash* --login [--auth auto|4|6|either] [-v] [--curl-extra-args ... ]++
*tunet-bash* --logout [--auth auto|4|6|either] [-v] [--curl-extra-args ... ]++
*tunet-bash* --whoami [-v] [--curl-extra-args ... ]++
*tunet-bash* --version

# DESCRIPTION

*tunet-bash* is a network authentication utility for Tsinghua University.++
It is written in bash with minimal dependencies and makes no assumptions about the user environment.

# OPTIONS

*-c*, *--config*
	Launch an interactive prompt to configure
	username and password for network authentication.

	Credentials are saved to _$HOME/.cache/tunet-bash/passwd_.

	Once configured, these credentials will be automatically used for login and logout operations.

*-i*, *--login*
	Authenticate and log in to the university network.

*-o*, *--logout*
	Log out from the university network.

*-w*, *--whoami*
	Query the current account status and connection information.

	This command also works with Tsinghua-Secure connections.

*-v*, *--verbose*
	Display detailed statistics when used with *-w*, *--whoami*.

	Set log level to _debug_.

*-a*, *--auth* _IP_VERSION_
	Specify the authentication protocol version.

	Valid values for _IP_VERSION_ are as follows:

	- _auto_: Automatically detect the appropriate version (default)
	- _4_: Enforce IPv4 authentication (auth4.tsinghua.edu.cn)
	- _6_: Enforce IPv6 authentication (auth6.tsinghua.edu.cn)
	- _either_: Use the default authentication server (auth.tsinghua.edu.cn)

*--pass*
	Use the pass password manager (_https://www.passwordstore.org/_) when configuring credentials with *-c*, *--config*.

	The interactive prompt will request your _pass-name_ instead of the actual password.

*--curl-extra-args*
	Pass extra arguments to *curl*.

	Can be specified multiple times.

*--version*
	Display version information and exit.

# EXAMPLES

*tunet-bash*
	Query current account status (default behavior when no options are specified).

*tunet-bash* *-c*
	Configure username and password interactively.

*tunet-bash* *-i*
	Log in to the university network.

*tunet-bash* *-o* *-a* _6_
	Log out using IPv6 authentication (auth6).

# ENVIRONMENT

*LOG*
	Control the verbosity of log messages.

	Valid values: _debug_, _info_, _error_.

	If set to any other value, no log messages will be displayed.

*USERNAME*
	Override the username stored in _$HOME/.cache/tunet-bash/passwd_.

*PASSWORD*
	Override the password stored in _$HOME/.cache/tunet-bash/passwd_.

*PASSNAME*
	Override the pass-name stored in _$HOME/.cache/tunet-bash/passwd_.

	When this is set, *PASSWORD* is ignored in favor of retrieving the password from the pass store.

# FILES

_$HOME/.cache/tunet-bash/passwd_
	Stores user credentials including username, password, or passname.

	This file is created with restricted permissions (600) for security.

# AUTHOR

Maintained by Xuelin Yang <xuelin@adamanteye.cc>.++
Source code and issue tracker: _https://github.com/adamanteye/tunet-bash_.

# SEE ALSO

*pass*(1) *curl*(1)

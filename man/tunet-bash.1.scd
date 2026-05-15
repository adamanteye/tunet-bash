tunet-bash(1)

# NAME

tunet-bash - Tsinghua University network authentication utility

# SYNOPSIS

*tunet-bash* _[OPTIONS]_

Common usage patterns:

*tunet-bash* --config [--pass] [-v]++
*tunet-bash* --login [--auth auto|4|6|generic] [-v] [--curl-extra-args ... ]++
*tunet-bash* --logout [--auth auto|4|6|generic] [-v] [--curl-extra-args ... ]++
*tunet-bash* --whoami [-v] [--curl-extra-args ... ]++
*tunet-bash* --version

When invoked without arguments, *tunet-bash* defaults to *--whoami*.

# DESCRIPTION

*tunet-bash* is a network authentication utility for Tsinghua University.++
It is implemented in POSIX-compatible bash with minimal external dependencies.

# OPTIONS

## Authentication and Account Management

*-c*, *--config*
	Launch an interactive prompt to configure
	username and password for network authentication.

	Credentials are saved to _$HOME/.cache/tunet-bash/passwd_.

	Once configured, the saved credentials are automatically used for subsequent
	login and logout.

*-i*, *--login*
	Authenticate and log in to the university network.

*-o*, *--logout*
	Log out from the university network.

*-w*, *--whoami*
	Query the current account status and connection information.

	This command also works when connected via Tsinghua-Secure.

## Output Control

*-v*, *--verbose*
	Display detailed statistics when used with *-w*, *--whoami*.

*-q*, *--quiet*
	Suppress all log output.

	Only command results are written to standard output.

## Endpoint Configuration

*-a*, *--auth* _IP_VERSION_
	Specify the authentication endpoint.

	Valid values for _IP_VERSION_ are as follows:

	- _auto_: Automatically detect the appropriate endpoint (default)
	- _4_: Enforce IPv4 (auth4.tsinghua.edu.cn)
	- _6_: Enforce IPv6 (auth6.tsinghua.edu.cn)
	- _generic_: Use the generic authentication endpoint (auth.tsinghua.edu.cn)

## Credential Management

*--pass*
	Use the pass password manager (_https://www.passwordstore.org/_) when
	configuring credentials with *-c*, *--config*.

	The interactive prompt will request your _pass-name_ instead of the
	actual password.

## Networking and Debugging

*--curl-extra-args* _ARG_
	Pass one extra argument to *curl*(1).

	Specify this option multiple times to pass multiple curl arguments.

## Informational Options

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

*tunet-bash* *-w* *-v* *--curl-extra-args* _'--interface'_ *--curl-extra-args* _'if!eth0'_
	Query current account status verbosely using interface eth0.

# ENVIRONMENT

*LOG*
	Control the verbosity of log messages.

	Valid values: _debug_, _info_, _error_.

	If set to any other value, logging is disabled.

*USERNAME*
	Override the username stored in the credential file.

*PASSWORD*
	Override the stored password.

	Ignored if *PASSNAME* is set.

*PASSNAME*
	Override the passname stored in _$HOME/.cache/tunet-bash/passwd_.

# FILES

_$HOME/.cache/tunet-bash/passwd_
	Stores user credentials including username, password, or passname.

	This file is created with permissions 0600 to restrict access.

# AUTHOR

Maintained by Xuelin Yang <xuelin@adamanteye.cc>.++
Source code and issue tracker: _https://github.com/adamanteye/tunet-bash_.

# SEE ALSO

*pass*(1) *curl*(1)

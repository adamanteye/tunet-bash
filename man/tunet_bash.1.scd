tunet_bash(1)

# NAME

tunet_bash - Tsinghua University authentication script

# SYNOPSIS

*tunet_bash* [_OPTIONS_]

# DESCRIPTION

*tunet_bash* is an authentication script for Tsinghua network. It is written in bash and C++ with minimal dependencies.

# OPTIONS

*--config*
	Specify username and password for account in use. They will be written to *$HOME/.cache/tunet_bash/passwd*.

	Once set, username and password will be read when login/logout.

*--login*
	Make login request.

*--logout*
	Make logout request.

*--whoami*
	Query account username currently online.

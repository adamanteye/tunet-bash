.PHONY: install uninstall

prefix := $(HOME)/.local

install: tunet_bash.1.gz 
	@install -Dm755 tunet_bash.sh $(prefix)/bin/tunet_bash
	@install -Dm644 tunet_bash.1.gz $(prefix)/share/man/man1/tunet_bash.1.gz

uninstall:
	@rm -f $(prefix)/bin/tunet_bash
	@rm -f $(prefix)/share/man/man1/tunet_bash.1.gz

tunet_bash.1.gz: man/tunet_bash.1.scd
	@scdoc < man/tunet_bash.1.scd > tunet_bash.1
	@gzip tunet_bash.1 -f

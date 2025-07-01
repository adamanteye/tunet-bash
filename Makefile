.PHONY: install uninstall clean

prefix := $(HOME)/.local

install: tunet-bash.1.gz
	@install -Dm755 tunet-bash.sh $(DESTDIR)$(prefix)/bin/tunet-bash
	@install -Dm644 tunet-bash.1.gz $(DESTDIR)$(prefix)/share/man/man1/tunet-bash.1.gz
	@install -Dm644 completions/tunet-bash.fish $(DESTDIR)$(prefix)/share/fish/vendor_completions.d/tunet-bash.fish
	@install -Dm644 completions/tunet-bash $(DESTDIR)$(prefix)/share/bash-completion/completions/tunet-bash

clean:
	@rm -f tunet-bash.1.gz

uninstall:
	@rm -f $(DESTDIR)$(prefix)/bin/tunet-bash
	@rm -f $(DESTDIR)$(prefix)/share/man/man1/tunet-bash.1.gz
	@rm -f $(DESTDIR)$(prefix)/share/fish/vendor_completions.d/tunet-bash.fish
	@rm -f $(DESTDIR)$(prefix)/share/bash-completion/completions/tunet-bash

tunet-bash.1.gz: man/tunet-bash.1.scd
	@scdoc < man/tunet-bash.1.scd > tunet-bash.1
	@gzip tunet-bash.1 -f

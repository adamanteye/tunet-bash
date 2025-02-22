.PHONY: install uninstall clean

prefix := $(HOME)/.local

install: tunet_bash.1.gz 
	@install -Dm755 tunet_bash.sh $(DESTDIR)$(prefix)/bin/tunet_bash
	@install -Dm644 tunet_bash.1.gz $(DESTDIR)$(prefix)/share/man/man1/tunet_bash.1.gz
	@install -Dm644 completions/tunet_bash.fish $(DESTDIR)$(prefix)/share/fish/vendor_completions.d/tunet_bash.fish

clean:
	@rm -f tunet_bash.1.gz

uninstall:
	@rm -f $(DESTDIR)$(prefix)/bin/tunet_bash
	@rm -f $(DESTDIR)$(prefix)/share/man/man1/tunet_bash.1.gz
	@rm -f $(DESTDIR)$(prefix)/share/fish/vendor_completions.d/tunet_bash.fish

tunet_bash.1.gz: man/tunet_bash.1.scd
	@scdoc < man/tunet_bash.1.scd > tunet_bash.1
	@gzip tunet_bash.1 -f

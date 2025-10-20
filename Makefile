.DELETE_ON_ERROR:
.PHONY: install uninstall clean

prefix := $(HOME)/.local
package := tunet-bash

install: $(package).1.gz
	@install -Dm755 $(package).sh $(destdir)$(prefix)/bin/$(package)
	@install -Dm644 $(package).1.gz $(destdir)$(prefix)/share/man/man1/$(package).1.gz
	@install -Dm644 completions/$(package).fish $(destdir)$(prefix)/share/fish/vendor_completions.d/$(package).fish

clean:
	@$(RM) $(package).1.gz

uninstall:
	@$(RM) $(destdir)$(prefix)/bin/$(package)
	@$(RM) $(destdir)$(prefix)/share/man/man1/$(package).1.gz
	@$(RM) $(destdir)$(prefix)/share/fish/vendor_completions.d/$(package).fish

$(package).1: man/$(package).1.scd
	@scdoc < man/$(package).1.scd > $(package).1

$(package).1.gz: $(package).1
	@gzip $(package).1 -f

.DELETE_ON_ERROR:
MAKEFLAGS += --no-builtin-rules

.PHONY: install uninstall clean
.DEFAULT_GOAL := install

prefix := $(HOME)/.local
package := tunet-bash
RM := rm -r

bindir := $(destdir)$(prefix)/bin
mandir := $(destdir)$(prefix)/share/man/man1
fishcompdir := $(destdir)$(prefix)/share/fish/vendor_completions.d

install: $(package).1.gz
	@install -d "$(bindir)" "$(mandir)" "$(fishcompdir)"
	@install -m 755 $(package).sh "$(bindir)/$(package)"
	@install -m 644 $(package).1.gz "$(mandir)/$(package).1.gz"
	@install -m 644 completions/$(package).fish "$(fishcompdir)/$(package).fish"
	@printf 'installed to %s\n' "$(destdir)$(prefix)"

clean:
	@$(RM) $(package).1.gz
	@$(RM) $(package).1

uninstall:
	@$(RM) "$(bindir)/$(package)"
	@$(RM) "$(mandir)/$(package).1.gz"
	@$(RM) "$(fishcompdir)/$(package).fish"
	@printf 'uninstalled from %s\n' "$(destdir)$(prefix)"

$(package).1: man/$(package).1.scd
	@scdoc < man/$(package).1.scd > $(package).1

$(package).1.gz: $(package).1
	@gzip $(package).1 -f

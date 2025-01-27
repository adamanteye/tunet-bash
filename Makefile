.PHONY: install man uninstall

PREFIX := $(HOME)/.local

install: tea.sh tunet_bash.sh
	@mkdir -p $(PREFIX)/share/tunet_bash
	@cp tea.sh $(PREFIX)/share/tunet_bash
	@mkdir -p $(PREFIX)/bin
	@cp tunet_bash.sh $(PREFIX)/bin/tunet_bash
	@chmod 755 $(PREFIX)/bin/tunet_bash
	@chmod 755 $(PREFIX)/share/tunet_bash/tea.sh
	@echo "installed to $(PREFIX)"

uninstall:
	@rm -rf $(PREFIX)/share/tunet_bash
	@rm -f $(PREFIX)/bin/tunet_bash

man: tunet_bash.1.gz

tunet_bash.1.gz: man/tunet_bash.1.scd
	@scdoc < man/tunet_bash.1.scd > tunet_bash.1
	@gzip tunet_bash.1 -f

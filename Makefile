.DELETE_ON_ERROR:
MAKEFLAGS += --no-builtin-rules

.PHONY: install uninstall man clean help
.DEFAULT_GOAL := help

prefix := $(HOME)/.local
package := tunet-bash
init := none

ifeq ($(V),1)
  Q :=
else
  Q := @
endif

define log
	@printf '  %-6s %s\n' "$(1)" "$(2)"
endef

bindir := $(destdir)$(prefix)/bin
mandir := $(destdir)$(prefix)/share/man/man1
fishcompdir := $(destdir)$(prefix)/share/fish/vendor_completions.d
systemdir := $(destdir)$(prefix)/lib/systemd/system

install: $(package).1.gz $(package).sh completions/$(package).fish
	$(call log,INST,"$(bindir)/$(package)")
	$(Q)mkdir -p "$(bindir)" "$(mandir)" "$(fishcompdir)"
	$(Q)install -m 755 $(package).sh "$(bindir)/$(package)"
	$(call log,INST,"$(mandir)/$(package).1.gz")
	$(Q)install -m 644 $(package).1.gz "$(mandir)/$(package).1.gz"
	$(call log,INST,"$(fishcompdir)/$(package).fish")
	$(Q)install -m 644 completions/$(package).fish "$(fishcompdir)/$(package).fish"
ifeq ($(init),systemd)
ifeq ($(prefix),/usr)
	$(call log,INST,"$(systemdir)/$(package).service")
	$(Q)mkdir -p "$(systemdir)"
	$(Q)install -m 644 systemd/$(package).service "$(systemdir)/$(package).service"
	$(call log,INST,"$(systemdir)/$(package).timer")
	$(Q)install -m 644 systemd/$(package).timer "$(systemdir)/$(package).timer"
endif
endif

clean:
	$(call log,RM,"$(package).1.gz")
	$(Q)$(RM) $(package).1.gz
	$(call log,RM,"$(package).1")
	$(Q)$(RM) $(package).1

uninstall:
	$(call log,RM,"$(bindir)/$(package)")
	$(Q)$(RM) "$(bindir)/$(package)"
	$(call log,RM,"$(mandir)/$(package).1.gz")
	$(Q)$(RM) "$(mandir)/$(package).1.gz"
	$(call log,RM,"$(fishcompdir)/$(package).fish")
	$(Q)$(RM) "$(fishcompdir)/$(package).fish"
ifeq ($(init),systemd)
ifeq ($(prefix),/usr)
	$(call log,RM,"$(destdir)$(prefix)/lib/systemd/system/$(package).service")
	$(Q)$(RM) "$(destdir)$(prefix)/lib/systemd/system/$(package).service"
	$(call log,RM,"$(destdir)$(prefix)/lib/systemd/system/$(package).timer")
	$(Q)$(RM) "$(destdir)$(prefix)/lib/systemd/system/$(package).timer"
endif
endif

man: $(package).1.gz

$(package).1: man/$(package).1.scd
	$(call log,MAN,$@)
	$(Q)scdoc < man/$(package).1.scd > $(package).1


$(package).1.gz: $(package).1
	$(call log,GZIP,$@)
	$(Q)gzip -c $< > $@

help:
	@echo "Targets:"
	@printf "  install    Install $(package) under $(prefix)\n"
	@printf "  uninstall  Remove installed files\n"
	@printf "  man        Generate manpage\n"
	@printf "  clean      Remove generated manpage files\n"
	@printf "  help       Show this help message\n"
	@echo
	@echo "Variables:"
	@printf "  prefix=<dir>     Installation prefix (default: $(prefix))\n"
	@printf "  destdir=<dir>    Staging directory for packaging (default: none)\n"
	@printf "  init=<system>    Init system (default: none, supported: systemd)\n"
	@printf "  V=1              Verbose mode (show commands)\n"

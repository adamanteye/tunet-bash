.DELETE_ON_ERROR:
MAKEFLAGS += --no-builtin-rules

.PHONY: install uninstall clean
.DEFAULT_GOAL := install

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

install: $(package).1.gz
	$(Q)mkdir -p "$(bindir)" "$(mandir)" "$(fishcompdir)"
	$(Q)install -m 755 $(package).sh "$(bindir)/$(package)"
	$(call log,INST,"$(bindir)/$(package)")
	$(Q)install -m 644 $(package).1.gz "$(mandir)/$(package).1.gz"
	$(call log,INST,"$(mandir)/$(package).1.gz")
	$(Q)install -m 644 completions/$(package).fish "$(fishcompdir)/$(package).fish"
	$(call log,INST,"$(fishcompdir)/$(package).fish")
ifeq ($(init),systemd)
ifeq ($(prefix),/usr)
	$(Q)mkdir -p "$(systemdir)"
	$(Q)install -m 644 systemd/$(package).service "$(systemdir)/$(package).service"
	$(call log,INST,"$(systemdir)/$(package).service")
	$(Q)install -m 644 systemd/$(package).timer "$(systemdir)/$(package).timer"
	$(call log,INST,"$(systemdir)/$(package).timer")
endif
endif

clean:
	$(Q)$(RM) $(package).1.gz
	$(call log,RM,"$(package).1.gz")
	$(Q)$(RM) $(package).1
	$(call log,RM,"$(package).1")

uninstall:
	$(Q)$(RM) "$(bindir)/$(package)"
	$(call log,RM,"$(bindir)/$(package)")
	$(Q)$(RM) "$(mandir)/$(package).1.gz"
	$(call log,RM,"$(mandir)/$(package).1.gz")
	$(Q)$(RM) "$(fishcompdir)/$(package).fish"
	$(call log,RM,"$(fishcompdir)/$(package).fish")
ifeq ($(init),systemd)
ifeq ($(prefix),/usr)
	$(Q)$(RM) "$(destdir)$(prefix)/lib/systemd/system/$(package).service"
	$(call log,RM,"$(destdir)$(prefix)/lib/systemd/system/$(package).service")
	$(Q)$(RM) "$(destdir)$(prefix)/lib/systemd/system/$(package).timer"
	$(call log,RM,"$(destdir)$(prefix)/lib/systemd/system/$(package).timer")
endif
endif

$(package).1: man/$(package).1.scd
	$(Q)scdoc < man/$(package).1.scd > $(package).1
	$(call log,MAN,$@)


$(package).1.gz: $(package).1
	$(Q)gzip -c $< > $@
	$(call log,GZIP,$@)

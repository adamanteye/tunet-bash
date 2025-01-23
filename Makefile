.PHONY: all clean install man

SHELL := /bin/bash
MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
CXX := $(shell if command -v clang++ &> /dev/null; then echo clang++; else echo g++; fi)
CFLAGS := -march=native -O2 -pipe -flto -Wall

TARGET := $(MAKEFILE_DIR)tunet_bash_tea
SRC := $(MAKEFILE_DIR)tea.cpp
PREFIX := $(HOME)/.local

all: $(TARGET)

install: $(TARGET) $(MAKEFILE_DIR)tunet_bash.sh
	@mkdir -p $(PREFIX)/share/tunet_bash
	@cp $(TARGET) $(PREFIX)/share/tunet_bash
	@mkdir -p $(PREFIX)/bin
	@cp $(MAKEFILE_DIR)tunet_bash.sh $(PREFIX)/bin/tunet_bash
	@chmod 755 $(PREFIX)/bin/tunet_bash
	@echo "installed to $(PREFIX)"

$(TARGET): $(SRC)
	$(CXX) $(CFLAGS) $(SRC) -o $(TARGET)

man: $(MAKEFILE_DIR)tunet_bash.1.gz

$(MAKEFILE_DIR)tunet_bash.1.gz: $(MAKEFILE_DIR)man/tunet_bash.1.scd
	@scdoc < $(MAKEFILE_DIR)man/tunet_bash.1.scd > $(MAKEFILE_DIR)tunet_bash.1
	@gzip $(MAKEFILE_DIR)tunet_bash.1

clean:
	rm -f $(TARGET)

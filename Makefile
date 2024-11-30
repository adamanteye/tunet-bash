.PHONY: all clean

MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
CC := $(shell if command -v clang++ &> /dev/null; then echo clang++; else echo g++; fi)
CFLAGS := -march=native -O2 -pipe

TARGET := $(MAKEFILE_DIR).tea
SRC := $(MAKEFILE_DIR)tea.cpp
PREFIX := $(HOME)/.tunet_bash

install: $(TARGET) $(MAKEFILE_DIR)tunet_bash.sh
	@echo "Installing to $(PREFIX)..."
	@mkdir -p $(PREFIX)
	cp $(TARGET) $(MAKEFILE_DIR)tunet_bash.sh $(PREFIX)
	@echo "Installed to $(PREFIX)"

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) $(SRC) -o $(TARGET)

clean:
	rm -f $(TARGET)

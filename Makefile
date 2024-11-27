.PHONY: all clean

MAKEFILE_DIR := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))
CC := $(shell if command -v clang++ &> /dev/null; then echo clang++; else echo g++; fi)
CFLAGS := -march=native -O2 -pipe

TARGET := $(MAKEFILE_DIR)/.tea
SRC := $(MAKEFILE_DIR)/tea.cpp

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) $(SRC) -o $(TARGET)

clean:
	rm -f $(TARGET)

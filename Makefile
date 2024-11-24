.PHONY: all clean

CC := $(shell if command -v clang++ &> /dev/null; then echo clang++; else echo g++; fi)
CFLAGS := -march=native -O2 -pipe

TARGET := tea
SRC := tea.cpp

all: $(TARGET)

$(TARGET): $(SRC)
	$(CC) $(CFLAGS) $(SRC) -o $(TARGET)

clean:
	rm -f $(TARGET)

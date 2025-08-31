CC=gcc
CFLAGS=-Wall -Wextra -std=c99 -I/usr/include/postgresql
LIBS=-lpq
TARGET=collector
SOURCE=main.c

all: $(TARGET)

$(TARGET): $(SOURCE)
	$(CC) $(CFLAGS) -o $(TARGET) $(SOURCE) $(LIBS)

clean:
	rm -f $(TARGET)

.PHONY: all clean

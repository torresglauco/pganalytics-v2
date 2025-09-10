CC=gcc
CFLAGS=-Wall -std=c99 -I/usr/include/postgresql
LIBS=-lpq -lpthread
TARGET=collector
SOURCE=main.c

all: $(TARGET)

$(TARGET): $(SOURCE)
	$(CC) $(CFLAGS) -o $(TARGET) $(SOURCE) $(LIBS)

clean:
	rm -f $(TARGET)
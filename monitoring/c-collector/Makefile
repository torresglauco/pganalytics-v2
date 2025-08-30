CC = gcc
CFLAGS = -Wall -Wextra -std=c99 -O2
LDFLAGS = -lpq -lmicrohttpd -lpthread

SRCDIR = src
OBJDIR = obj
SOURCES = $(wildcard $(SRCDIR)/*.c)
OBJECTS = $(SOURCES:$(SRCDIR)/%.c=$(OBJDIR)/%.o)
TARGET = pg_metrics_collector

.PHONY: all clean

all: $(TARGET)

$(TARGET): $(OBJECTS) | $(OBJDIR)
	$(CC) $(OBJECTS) -o $@ $(LDFLAGS)

$(OBJDIR)/%.o: $(SRCDIR)/%.c | $(OBJDIR)
	$(CC) $(CFLAGS) -c $< -o $@

$(OBJDIR):
	mkdir -p $(OBJDIR)

clean:
	rm -rf $(OBJDIR) $(TARGET)

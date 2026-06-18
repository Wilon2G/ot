# Define the compiler and flags
CC = gcc
CFLAGS = -Wall -Wextra -std=c99

# Define the final executable name
TARGET = test

# Define all object files (.o) that correspond to your .c files
OBJS = ot.o logger.o

# The default rule to build the target
$(TARGET): $(OBJS)
	$(CC) $(CFLAGS) -o $(TARGET) $(OBJS)

# Rule to compile main.c into main.o
main.o: ot.c config.h logger.h
	$(CC) $(CFLAGS) -c ot.c

# Rule to compile logger.c into logger.o
logger.o: logger.c logger.h
	$(CC) $(CFLAGS) -c logger.c

# Rule to clean up built files
clean:
	rm -f $(TARGET) $(OBJS)

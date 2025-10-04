CC = gcc
CFLAGS = -Wall -O2 -I../vendor
LIBS = -lpthread -lmbedtls -lmbedcrypto -lmbedx509

# Directories
BUILD_DIR = build
SRC_DIR = .

# Target executable name
TARGET = $(BUILD_DIR)/server

# Source files
SOURCES = server.c ../vendor/open62541.c

# Object files - use notdir to strip directory paths
OBJECTS = $(patsubst %.c,$(BUILD_DIR)/%.o,$(notdir $(SOURCES)))

# Default target
all: $(BUILD_DIR) $(TARGET)

# Create build directory
$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

# Link the executable
$(TARGET): $(OBJECTS)
	$(CC) $(OBJECTS) $(LIBS) -o $(TARGET)

# Compile server.c
$(BUILD_DIR)/server.o: server.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

# Compile open62541.c from vendor directory
$(BUILD_DIR)/open62541.o: ../vendor/open62541.c ../vendor/open62541.h | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

# Clean build artifacts
clean:
	rm -rf $(BUILD_DIR)

# Rebuild from scratch
rebuild: clean all

# Run the application
run: $(TARGET)
	$(TARGET)

.PHONY: all clean rebuild run

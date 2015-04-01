# Makefile to rebuild SM64 split image

################ Target Executable and Sources ###############

# TARGET is used to specify prefix in all build artifacts including
# output ROM is $(TARGET).z64
TARGET = sm64

# BUILD_DIR is location where all build artifacts are placed
BUILD_DIR = build

##################### Compiler Options #######################
CROSS = mips64-elf-
AS = $(CROSS)as
LD = $(CROSS)ld
OBJDUMP = $(CROSS)objdump
OBJCOPY = $(CROSS)objcopy

ASFLAGS = -mtune=vr4300 -march=vr4300
LDFLAGS = -Tn64.ld -Map $(BUILD_DIR)/sm64.map

####################### Other Tools #########################

# N64 tools
MIO0TOOL = ./tools/mio0
N64CKSUM = ./tools/n64cksum
N64GRAPHICS = ./tools/n64graphics
EMULATOR = mupen64plus
EMU_FLAGS = --noosd --verbose

######################## Targets #############################

default: all

# file dependencies generated by splitter
MAKEFILE_GEN = gen/Makefile.gen
include $(MAKEFILE_GEN)

all: $(TARGET).gen.z64

clean:
	rm -f $(BUILD_DIR)/$(TARGET).elf $(BUILD_DIR)/$(TARGET).o $(BUILD_DIR)/$(TARGET).bin $(TARGET).v64

$(MIO0_DIR)/%.mio0: $(MIO0_DIR)/%.bin
	$(MIO0TOOL) e $< 0 $@

$(BUILD_DIR):
	mkdir -p $(BUILD_DIR)

$(BUILD_DIR)/$(TARGET).o: gen/$(TARGET).s Makefile.as $(MAKEFILE_GEN) $(MIO0_FILES) $(LEVEL_FILES) | $(BUILD_DIR)
	$(AS) $(ASFLAGS) -o $@ $<

$(BUILD_DIR)/$(TARGET).elf: $(BUILD_DIR)/$(TARGET).o n64.ld
	$(LD) $(LDFLAGS) -o $@ $< $(LIBS)

$(BUILD_DIR)/$(TARGET).bin: $(BUILD_DIR)/$(TARGET).elf
	$(OBJCOPY) $< $@ -O binary

# final z64 updates checksum
$(TARGET).gen.z64: $(BUILD_DIR)/$(TARGET).bin
	$(N64CKSUM) $< $@

$(BUILD_DIR)/$(TARGET).gen.hex: $(TARGET).gen.z64
	xxd $< > $@

$(BUILD_DIR)/$(TARGET).objdump: $(BUILD_DIR)/$(TARGET).elf
	$(OBJDUMP) -D $< > $@

diff: $(BUILD_DIR)/$(TARGET).gen.hex
	diff sm64.hex $< | wc -l

test: $(TARGET).gen.z64
	$(EMULATOR) $(EMU_FLAGS) $<

.PHONY: all clean default diff test

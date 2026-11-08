PREFIX = arm-none-eabi-
SRC = startup led timer inputs video font game main
OBJ = $(addprefix build/,$(addsuffix .o,$(SRC)))

all: build/galaga.uf2

build/%.o: src/%.s src/defs.inc
	@mkdir -p build
	$(PREFIX)as -mcpu=cortex-m0plus -mthumb -I src -g $< -o $@

build/galaga.elf: $(OBJ) link.ld
	$(PREFIX)ld -T link.ld -Map build/galaga.map -o $@ $(OBJ)

build/%.bin: build/%.elf
	$(PREFIX)objcopy -O binary $< $@

build/%.uf2: build/%.bin
	python tools/bin2uf2.py $< $@

clean:
	rm -rf build

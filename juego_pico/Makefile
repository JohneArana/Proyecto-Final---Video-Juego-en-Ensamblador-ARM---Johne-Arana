PREFIX = arm-none-eabi-
SRC = startup timer inputs video font game main
OBJ = $(addprefix build/,$(addsuffix .o,$(SRC)))

all: build/juego.uf2

build/%.o: src/%.s src/defs.inc
	@mkdir -p build
	$(PREFIX)as -mcpu=cortex-m0plus -mthumb -I src -g $< -o $@

build/juego.elf: $(OBJ) link.ld
	$(PREFIX)ld -T link.ld -Map build/juego.map -o $@ $(OBJ)

build/juego.bin: build/juego.elf
	$(PREFIX)objcopy -O binary $< $@

build/juego.uf2: build/juego.bin
	python tools/bin2uf2.py $< $@

clean:
	rm -rf build

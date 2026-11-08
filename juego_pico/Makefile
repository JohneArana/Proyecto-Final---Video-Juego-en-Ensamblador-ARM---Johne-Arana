PREFIX = arm-none-eabi-
SRC = startup led timer inputs video font game main
TST = startup led timer inputs video font main_joytest
OBJ = $(addprefix build/,$(addsuffix .o,$(SRC)))
TOBJ = $(addprefix build/,$(addsuffix .o,$(TST)))

all: build/juego.uf2 build/prueba_joystick.uf2

build/%.o: src/%.s src/defs.inc
	@mkdir -p build
	$(PREFIX)as -mcpu=cortex-m0plus -mthumb -I src -g $< -o $@

build/juego.elf: $(OBJ) link.ld
	$(PREFIX)ld -T link.ld -Map build/juego.map -o $@ $(OBJ)

build/prueba_joystick.elf: $(TOBJ) link.ld
	$(PREFIX)ld -T link.ld -o $@ $(TOBJ)

build/%.bin: build/%.elf
	$(PREFIX)objcopy -O binary $< $@

build/%.uf2: build/%.bin
	python tools/bin2uf2.py $< $@

clean:
	rm -rf build

# Variante de emergencia: palanca a tope a la izquierda = botón Z
build/inputs_alt.o: src/inputs.s src/defs.inc
	@mkdir -p build
	$(PREFIX)as -mcpu=cortex-m0plus -mthumb -I src -g --defsym BTN_FALLBACK=1 $< -o $@

build/juego_boton_alterno.elf: $(filter-out build/inputs.o,$(OBJ)) build/inputs_alt.o link.ld
	$(PREFIX)ld -T link.ld -o $@ $(filter-out build/inputs.o,$(OBJ)) build/inputs_alt.o

alterno: build/juego_boton_alterno.uf2

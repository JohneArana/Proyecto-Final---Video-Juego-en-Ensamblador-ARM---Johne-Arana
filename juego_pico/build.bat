@echo off
rem Requiere: Arm GNU Toolchain (arm-none-eabi-*) en el PATH y Python
if not exist build mkdir build
set AS=arm-none-eabi-as -mcpu=cortex-m0plus -mthumb -I src -g
for %%f in (startup timer inputs video font game main) do (
  %AS% src\%%f.s -o build\%%f.o || exit /b 1
)
arm-none-eabi-ld -T link.ld -Map build\juego.map -o build\juego.elf build\startup.o build\timer.o build\inputs.o build\video.o build\font.o build\game.o build\main.o || exit /b 1
arm-none-eabi-objcopy -O binary build\juego.elf build\juego.bin || exit /b 1
python tools\bin2uf2.py build\juego.bin build\juego.uf2

@echo off
setlocal
rem ============================================================
rem  Compila METEOROS (ensamblador ARM Cortex-M0+ / RP2040)
rem  Requiere: Arm GNU Toolchain (arm-none-eabi-*) y Python en el PATH
rem  Genera en build\ :
rem    juego.uf2               juego normal (boton Z = GP22)
rem    juego_boton_alterno.uf2 igual, pero palanca a tope izquierda tambien cuenta como Z
rem    prueba_joystick.uf2     pantalla de prueba del joystick
rem ============================================================
where arm-none-eabi-as >nul 2>&1
if errorlevel 1 (
  echo ERROR: no encuentro arm-none-eabi-as. Instala el Arm GNU Toolchain y marca "Add path to environment variable".
  exit /b 1
)
set PY=python
where python >nul 2>&1
if errorlevel 1 set PY=py
if not exist build mkdir build

set AS=arm-none-eabi-as -mcpu=cortex-m0plus -mthumb -I src -g
for %%f in (startup led timer inputs video font game main main_joytest) do (
  %AS% src\%%f.s -o build\%%f.o || exit /b 1
)
%AS% --defsym BTN_FALLBACK=1 src\inputs.s -o build\inputs_alt.o || exit /b 1

set OBJ_JUEGO=build\startup.o build\led.o build\timer.o build\inputs.o build\video.o build\font.o build\game.o build\main.o
set OBJ_ALT=build\startup.o build\led.o build\timer.o build\inputs_alt.o build\video.o build\font.o build\game.o build\main.o
set OBJ_TEST=build\startup.o build\led.o build\timer.o build\inputs.o build\video.o build\font.o build\main_joytest.o

arm-none-eabi-ld -T link.ld -Map build\juego.map -o build\juego.elf %OBJ_JUEGO% || exit /b 1
arm-none-eabi-ld -T link.ld -o build\juego_boton_alterno.elf %OBJ_ALT% || exit /b 1
arm-none-eabi-ld -T link.ld -o build\prueba_joystick.elf %OBJ_TEST% || exit /b 1

for %%n in (juego juego_boton_alterno prueba_joystick) do (
  arm-none-eabi-objcopy -O binary build\%%n.elf build\%%n.bin || exit /b 1
  %PY% tools\bin2uf2.py build\%%n.bin build\%%n.uf2 || exit /b 1
)
echo.
echo Listo. Archivos en la carpeta build\

@echo off
setlocal
rem ============================================================
rem  Compila GALAGA (ensamblador ARM Cortex-M0+ / RP2040)
rem  Requiere: Arm GNU Toolchain (arm-none-eabi-*) y Python en el PATH
rem  Resultado: build\galaga.uf2  (y build\galaga.map = mapa de memoria)
rem ============================================================
where arm-none-eabi-as >nul 2>&1
if errorlevel 1 (
  echo ERROR: no encuentro arm-none-eabi-as. Instala el Arm GNU Toolchain y marca "Add path to environment variable".
  pause
  exit /b 1
)
set PY=python
where python >nul 2>&1
if errorlevel 1 set PY=py
if exist build rmdir /s /q build
mkdir build

set AS=arm-none-eabi-as -mcpu=cortex-m0plus -mthumb -I src -g
for %%f in (startup led timer inputs video font game main) do (
  echo Ensamblando %%f.s
  %AS% src\%%f.s -o build\%%f.o || goto :fallo
)

arm-none-eabi-ld -T link.ld -Map build\galaga.map -o build\galaga.elf build\startup.o build\led.o build\timer.o build\inputs.o build\video.o build\font.o build\game.o build\main.o || goto :fallo
arm-none-eabi-objcopy -O binary build\galaga.elf build\galaga.bin || goto :fallo
%PY% tools\bin2uf2.py build\galaga.bin build\galaga.uf2 || goto :fallo

echo.
echo Listo. Archivo para la Pico: build\galaga.uf2
pause
exit /b 0

:fallo
echo.
echo *** ERROR al compilar. Copia el mensaje de arriba y mandamelo. ***
pause
exit /b 1

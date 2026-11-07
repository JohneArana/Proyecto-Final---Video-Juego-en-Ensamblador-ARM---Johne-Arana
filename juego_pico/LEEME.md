# METEOROS - Videojuego en ensamblador ARM (Raspberry Pi Pico / RP2040)

## Conexiones (todo a 3.3 V)
| Componente | Pin Pico | Pin físico |
|---|---|---|
| OLED SDA | GP4 | 6 |
| OLED SCL | GP5 | 7 |
| OLED VCC / Joystick +5V (usar 3V3) | 3V3(OUT) | 36 |
| OLED GND / Joystick GND | GND | 38 |
| Joystick VRx (eje X) | GP26 (ADC0) | 31 |
| Joystick VRy (eje Y) | GP27 (ADC1) | 32 |
| Joystick SW (botón Z) | GP22 | 29 |

## Cargar el juego
1. Mantén BOOTSEL pulsado y conecta el Pico por USB (aparece la unidad RPI-RP2).
2. Arrastra `juego.uf2` a esa unidad. Corre desde RAM: si desconectas el USB hay que cargarlo de nuevo.

## Compilar
Instala Arm GNU Toolchain (arm-none-eabi-*) y Python, y ejecuta `build.bat` (Windows) o `make`.
Resultado: `build/juego.uf2`.

## Ajustes en src/defs.inc
- `INVERT_X` / `INVERT_Y` = 1 si el joystick mueve al revés.
- Si la pantalla sale de cabeza, en video.s cambia `0xA1`->`0xA0` y `0xC8`->`0xC0`.

## Módulos
startup.s (vectores, reloj, resets) | timer.s (ALARM0 + NVIC) | inputs.s (ADC, botón) |
video.s (I2C, SSD1306, framebuffer, sprites, texto) | font.s | game.s (lógica) | main.s (estados)

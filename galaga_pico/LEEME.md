# GALAGA - Videojuego en ensamblador ARM (Raspberry Pi Pico / RP2040)

## Conexiones (todo a 3.3 V)
| Componente | Pin Pico | Pin físico |
|---|---|---|
| OLED SDA | GP4 | 6 |
| OLED SCL | GP5 | 7 |
| OLED VCC / Joystick +5V (usar 3V3) | 3V3(OUT) | 36 |
| OLED GND / Joystick GND | GND | 38 |
| Joystick VRx | GP26 (ADC0) | 31 |
| Joystick VRy | GP27 (ADC1) | 32 |
| Joystick SW (no se usa para iniciar) | GP22 | 29 |

## Cómo se juega
Al encender aparece GALAGA. Mueve la palanca para iniciar. Esquiva los meteoros (3 vidas).
Al perder, suelta la palanca y vuelve a moverla para reiniciar.

## Compilar (Windows)
1. Instala Arm GNU Toolchain (marca "Add path to environment variable") y Python.
2. Doble clic en `build.bat`  ->  resultado: `build\galaga.uf2` y `build\galaga.map`.
   (En Linux/Mac: `make`)

## Cargar en la Pico
Mantén BOOTSEL pulsado, conecta el USB (aparece la unidad RPI-RP2) y arrastra `galaga.uf2`.
El programa corre desde RAM: si desconectas el USB hay que cargarlo de nuevo.

## Ajustes en src/defs.inc
- `SWAP_XY` = 1 joystick girado 90 grados (ya activado). Pon 0 si tu módulo va derecho.
- `INVERT_X` / `INVERT_Y`: pon 1 o 0 para invertir un sentido que salga al revés.
  (Ahora: INVERT_X=0, INVERT_Y=1.)
- `MOVE_THRESH` = cuánto hay que empujar la palanca para iniciar (1000 de 2048).
- Si la pantalla sale de cabeza, en video.s cambia `0xA1`->`0xA0` y `0xC8`->`0xC0`.

## Módulos
startup.s | timer.s | inputs.s | video.s | font.s | game.s | led.s | main.s | defs.inc

## LED de diagnóstico (GP25)
- Apagado siempre: no arrancó (repetir la carga con BOOTSEL).
- Encendido fijo: arrancó pero se detuvo antes del menú.
- Parpadeo lento (~1 Hz): menú listo y la OLED respondió.
- Parpadeo rápido (~8 Hz): la OLED NO respondió (revisar SDA, SCL, VCC, GND).

#!/usr/bin/env python3
"""Convierte un .bin cargado en SRAM (0x20000000) a UF2 para el RP2040."""
import struct, sys
src, dst = sys.argv[1], sys.argv[2]
data = open(src, 'rb').read()
data += b'\0' * ((-len(data)) % 256)
n = len(data) // 256
out = bytearray()
for i in range(n):
    hdr = struct.pack('<8I', 0x0A324655, 0x9E5D5157, 0x00002000,
                      0x20000000 + i * 256, 256, i, n, 0xE48BFF56)
    out += hdr + data[i*256:(i+1)*256] + b'\0' * 220 + struct.pack('<I', 0x0AB16F30)
open(dst, 'wb').write(out)
print(f"{dst}: {n} bloques, {len(data)} bytes")

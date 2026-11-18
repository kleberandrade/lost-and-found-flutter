"""Generate the project's original infinity mark without remote assets."""
from pathlib import Path
import json
import math
import struct
import zlib

ROOT = Path(__file__).resolve().parents[1]

def icon(path, size):
    pixels = [bytearray(bytes((23, 107, 96)) * size) for _ in range(size)]
    radius = max(1, size * .034)
    for step in range(max(200, size * 3)):
        angle = step / max(200, size * 3) * math.tau
        x = size * (.5 + .30 * math.sin(angle))
        y = size * (.5 + .145 * math.sin(2 * angle))
        for iy in range(max(0, int(y-radius)), min(size, int(y+radius)+1)):
            for ix in range(max(0, int(x-radius)), min(size, int(x+radius)+1)):
                if (ix-x)**2 + (iy-y)**2 <= radius**2:
                    pixels[iy][ix*3:ix*3+3] = bytes((252, 251, 247))
    def chunk(kind, data):
        return struct.pack('>I', len(data)) + kind + data + struct.pack('>I', zlib.crc32(kind+data) & 0xffffffff)
    path.write_bytes(b'\x89PNG\r\n\x1a\n' + chunk(b'IHDR', struct.pack('>IIBBBBB', size, size, 8, 2, 0, 0, 0)) + chunk(b'IDAT', zlib.compress(b''.join(b'\0'+row for row in pixels))) + chunk(b'IEND', b''))

for path in (ROOT/'web/icons').glob('*.png'):
    icon(path, 512 if '512' in path.name else 192)
icon(ROOT/'web/favicon.png', 32)
for folder, size in [('mdpi',48),('hdpi',72),('xhdpi',96),('xxhdpi',144),('xxxhdpi',192)]:
    icon(ROOT/f'android/app/src/main/res/mipmap-{folder}/ic_launcher.png', size)
base = ROOT/'ios/Runner/Assets.xcassets/AppIcon.appiconset'
for image in json.loads((base/'Contents.json').read_text())['images']:
    if 'filename' in image:
        size = round(float(image['size'].split('x')[0]) * float(image['scale'].rstrip('x')))
        icon(base/image['filename'], size)

from pathlib import Path
import struct
root = Path(__file__).resolve().parent
iconset = root / '.build/SpeedPeek.iconset'
entries = [('icp4', 'icon_16x16.png'), ('icp5', 'icon_32x32.png'),
           ('icp6', 'icon_32x32@2x.png'), ('ic07', 'icon_128x128.png'),
           ('ic08', 'icon_256x256.png'), ('ic09', 'icon_512x512.png'),
           ('ic10', 'icon_512x512@2x.png'), ('ic11', 'icon_16x16@2x.png'),
           ('ic12', 'icon_32x32@2x.png'), ('ic13', 'icon_128x128@2x.png'),
           ('ic14', 'icon_256x256@2x.png')]
chunks = []
for kind, name in entries:
    data = (iconset / name).read_bytes()
    assert data.startswith(b'\x89PNG\r\n\x1a\n')
    chunks.append(kind.encode('ascii') + struct.pack('>I', len(data) + 8) + data)
payload = b''.join(chunks)
(root / 'SpeedPeek.app/Contents/Resources/SpeedPeek.icns').write_bytes(b'icns' + struct.pack('>I', len(payload) + 8) + payload)
print('PASS: ICNS assembled with 11 standard PNG image representations')

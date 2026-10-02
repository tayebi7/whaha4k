#!/usr/bin/env bash
# يعدّل مشروع أندرويد المُولَّد بـ `flutter create`:
# - إذن الإنترنت + السماح بروابط http (أغلب سيرفرات IPTV)
# - الاتجاه الأفقي + اسم التطبيق
set -e
M=android/app/src/main/AndroidManifest.xml
python3 - "$M" <<'EOF'
import sys, re
p = sys.argv[1]
s = open(p, encoding='utf-8').read()
if 'android.permission.INTERNET' not in s:
    s = s.replace('<application',
        '<uses-permission android:name="android.permission.INTERNET"/>\n'
        '    <uses-permission android:name="android.permission.WAKE_LOCK"/>\n'
        '    <application', 1)
if 'usesCleartextTraffic' not in s:
    s = s.replace('<application', '<application android:usesCleartextTraffic="true"', 1)
s = re.sub(r'android:label="[^"]*"', 'android:label="Waha 4K"', s, count=1)
if 'screenOrientation' not in s:
    s = s.replace('<activity', '<activity android:screenOrientation="sensorLandscape"', 1)
open(p, 'w', encoding='utf-8').write(s)
print('manifest patched')
EOF

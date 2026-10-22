#!/usr/bin/env python3
\"\"\"Adiciona permissões BLE ao AndroidManifest gerado pelo Flutter.\"\"\"

from pathlib import Path

manifest = Path("android/app/src/main/AndroidManifest.xml")
if not manifest.exists():
    raise SystemExit(
        "AndroidManifest.xml não encontrado. Execute primeiro: "
        "flutter create . --platforms=android --project-name=roleta_missao12 --org=br.clubrobot"
    )

content = manifest.read_text(encoding="utf-8")
permissions = [
    '<uses-permission android:name="android.permission.BLUETOOTH_SCAN" android:usesPermissionFlags="neverForLocation" />',
    '<uses-permission android:name="android.permission.BLUETOOTH_CONNECT" />',
    '<uses-permission android:name="android.permission.BLUETOOTH" android:maxSdkVersion="30" />',
    '<uses-permission android:name="android.permission.BLUETOOTH_ADMIN" android:maxSdkVersion="30" />',
    '<uses-permission android:name="android.permission.ACCESS_FINE_LOCATION" android:maxSdkVersion="30" />',
]
missing = [permission for permission in permissions if permission.split('"')[1] not in content]
if missing:
    marker = "<application"
    if marker not in content:
        raise SystemExit("Não foi encontrado o elemento <application> no manifesto.")
    content = content.replace(marker, "\n    " + "\n    ".join(missing) + "\n\n    " + marker, 1)
    manifest.write_text(content, encoding="utf-8")
    print("Permissões Bluetooth adicionadas ao AndroidManifest.xml.")
else:
    print("As permissões Bluetooth já estão presentes.")

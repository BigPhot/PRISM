# -*- mode: python ; coding: utf-8 -*-

# 👇 Import os module (optional if you want to dynamically build paths)
import os

# 👇 Add this: includes the whole 'data' folder
data_folder = [('data', 'data')]

a = Analysis(
    ['main.py'],
    pathex=[],
    binaries=[],
    datas=data_folder,  # 👈 COPY the entire external 'data' folder
    hiddenimports=[],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=['PyQt5', 'PyQt6'],
    noarchive=False,
    optimize=0,
)

pyz = PYZ(a.pure)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name='main',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=True,
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)

coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,  # 👈 This now includes your data folder
    strip=False,
    upx=True,
    upx_exclude=[],
    name='main',
)

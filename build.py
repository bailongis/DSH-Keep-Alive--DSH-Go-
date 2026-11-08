#!/usr/bin/env python3
"""Build the flashable module zip from module.prop / service.sh / uninstall.sh."""
import os
import re
import zipfile

ROOT = os.path.dirname(os.path.abspath(__file__))
FILES = ("module.prop", "service.sh", "uninstall.sh")


def main():
    with open(os.path.join(ROOT, "module.prop"), encoding="utf-8") as f:
        text = f.read()
    version = re.search(r"^version=(.+)$", text, re.M).group(1).strip()
    out = os.path.join(ROOT, f"dsh-keepalive-{version}.zip")

    with zipfile.ZipFile(out, "w", zipfile.ZIP_DEFLATED) as z:
        for name in FILES:
            path = os.path.join(ROOT, name)
            data = open(path, "rb").read()
            info = zipfile.ZipInfo(name)
            info.external_attr = (0o755 if name.endswith(".sh") else 0o644) << 16
            info.compress_type = zipfile.ZIP_DEFLATED
            z.writestr(info, data)

    print(f"built {out} ({os.path.getsize(out)} bytes)")


if __name__ == "__main__":
    main()

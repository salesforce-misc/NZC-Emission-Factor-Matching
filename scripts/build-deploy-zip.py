#!/usr/bin/env python3
"""Build the Metadata API deploy zip (package.xml at the zip root) from force-app/main/default.

package.xml is generated from the folders, so it can't drift from the contents, and
non-metadata files (jsconfig.json, .gitkeep, tests) are left out.
Usage: python3 scripts/build-deploy-zip.py [out.zip]
"""
import sys
import xml.etree.ElementTree as ET
import zipfile
from pathlib import Path

SRC = Path(__file__).resolve().parent.parent / "force-app/main/default"
API_VERSION = "65.0"  # highest apiVersion used by the bundles in this repo
# folder -> (metadata type, file suffix of the primary file)
TYPES = {
    "classes": ("ApexClass", ".cls"),
    "triggers": ("ApexTrigger", ".trigger"),
    "objects": ("CustomObject", ".object"),
    "layouts": ("Layout", ".layout"),
    "permissionsets": ("PermissionSet", ".permissionset"),
    "lwc": ("LightningComponentBundle", None),  # one member per bundle folder
}
# child elements of a .object file that must also be declared in package.xml as Object.Name
OBJECT_CHILDREN = {
    "fields": "CustomField", "listViews": "ListView", "validationRules": "ValidationRule",
    "recordTypes": "RecordType", "webLinks": "WebLink", "compactLayouts": "CompactLayout",
    "fieldSets": "FieldSet", "businessProcesses": "BusinessProcess", "sharingReasons": "SharingReason",
}
SKIP = {"jsconfig.json", ".eslintrc.json", ".gitkeep", ".DS_Store"}


def keep(p: Path) -> bool:
    return p.is_file() and p.name not in SKIP and "__tests__" not in p.parts


def members(folder: str, suffix):
    d = SRC / folder
    if suffix is None:
        return sorted(c.name for c in d.iterdir() if c.is_dir())
    return sorted(f.name[: -len(suffix)] for f in d.glob("*" + suffix))


def object_children() -> dict:
    found = {}
    for f in sorted((SRC / "objects").glob("*.object")):
        for el in ET.parse(f).getroot():
            kind = OBJECT_CHILDREN.get(el.tag.rpartition("}")[2])
            name = el.find("{*}fullName")
            if kind and name is not None:
                found.setdefault(kind, []).append(f"{f.stem}.{name.text}")
    return found


def package_xml() -> str:
    out = ['<?xml version="1.0" encoding="UTF-8"?>',
           '<Package xmlns="http://soap.sforce.com/2006/04/metadata">',
           "    <fullName>EmissionFactorMatching</fullName>"]
    groups = [(name, members(folder, suffix)) for folder, (name, suffix) in TYPES.items()]
    groups += sorted((k, sorted(v)) for k, v in object_children().items())
    for name, ms in groups:
        if not ms:
            continue
        out.append("    <types>")
        out += [f"        <members>{m}</members>" for m in ms]
        out += [f"        <name>{name}</name>", "    </types>"]
    out += [f"    <version>{API_VERSION}</version>", "</Package>", ""]
    return "\n".join(out)


def main(dest: Path):
    with zipfile.ZipFile(dest, "w", zipfile.ZIP_DEFLATED) as z:
        z.writestr("package.xml", package_xml())
        for folder in TYPES:
            for f in sorted((SRC / folder).rglob("*")):
                if keep(f):
                    z.write(f, f.relative_to(SRC).as_posix())
    print(f"wrote {dest}")


if __name__ == "__main__":
    main(Path(sys.argv[1] if len(sys.argv) > 1 else "NZC-Emission-Factor-Matching-Deploy.zip"))

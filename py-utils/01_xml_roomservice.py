#!/usr/bin/python3

import sys
import xml
from urllib.request import Request, urlopen
from xml.etree import ElementTree

import _01_xml_manifest_gen


def fetch_device_vendor(local_manifest, remote_manifest, device: str) -> xml:
    for projects in remote_manifest.findall("project"):
        if projects.get("groups").__contains__(device):
            if projects.get("remote") == "":
                remote = ""
            else:
                remote = projects.get("remote")

            if projects.get("revision") == "":
                revision = ""
            else:
                revision = projects.get("revision")

            local_manifest = _01_xml_manifest_gen.add_project_to_manifest(
                manifest=local_manifest,
                project_name=projects.get("name"),
                project_path=projects.get("path"),
                project_remote=remote,
                project_revision=revision,
            )

            ElementTree.indent(local_manifest)
    return local_manifest


def main() -> None:
    devices = f"muppets_{sys.argv[1]}".split(",")
    branch = sys.argv[2]

    url = f"https://github.com/TheMuppets/manifests/raw/refs/heads/{branch}/muppets.xml"
    request = Request(url, headers={"User-Agent": "Mozilla/5.0"})
    source_manifest = urlopen(request).read()
    remote_manifest = ElementTree.fromstring(source_manifest)

    local_manifest = ElementTree.Element("manifest")
    for device in devices:
        local_manifest = fetch_device_vendor(local_manifest, remote_manifest, device)

    print('<?xml version="1.0" encoding="UTF-8"?>')
    print(ElementTree.tostring(local_manifest).decode())


if __name__ == "__main__":
    main()

#!/usr/bin/python3

from xml.etree import ElementTree
import sys
from urllib.request import urlopen, Request


def is_in_manifest(manifest: str, project_path: str = "", project_remote: str = "") -> bool:
    for manifest_project in manifest.findall("project"):
        if project_path == manifest_project.get("path"):
            return True

    for manifest_project in manifest.findall("remote"):
        if project_remote == manifest_project.get("name"):
            return True

    return False


def add_project_to_manifest(manifest: str, project_name: str, project_path: str, project_remote: str = "",
                            project_revision: str = "") -> str:
    if is_in_manifest(manifest=manifest, project_path=project_path):
        return manifest

    element = ElementTree.Element(
        "project",
        attrib={
            "name": project_name,
            "path": project_path,
        },
    )

    if project_remote:
        element.attrib["remote"] = project_remote

    if project_revision:
        element.attrib["revision"] = project_revision

    manifest.append(element)
    return manifest


def add_remote_to_manifest(manifest: str, remote_name: str, remote_fetch: str, remote_revision: str = "") -> str:
    if is_in_manifest(manifest=manifest, project_remote=remote_name):
        return manifest

    element = ElementTree.Element(
        "remote",
        attrib={
            "name": remote_name,
            "fetch": remote_fetch,
        },
    )

    if remote_revision:
        element.attrib["revision"] = remote_revision

    manifest.append(element)
    return manifest


def generate_manifest(local_manifest: str, remote_manifest: str) -> str:
    for projects in remote_manifest.findall("remote"):
        if projects.get("revision") == "":
            revision = ""
        else:
            revision = projects.get("revision")

        local_manifest = add_remote_to_manifest(
            manifest=local_manifest,
            remote_name=projects.get("name"),
            remote_fetch=projects.get("fetch"),
            remote_revision=revision
        )

    for projects in remote_manifest.findall("project"):
        if projects.get("remote") == "":
            remote = ""
        else:
            remote = projects.get("remote")

        if projects.get("revision") == "":
            revision = ""
        else:
            revision = projects.get("revision")

        local_manifest = add_project_to_manifest(
            manifest=local_manifest,
            project_name=projects.get("name"),
            project_path=projects.get("path"),
            project_remote=remote,
            project_revision=revision
        )

    ElementTree.indent(local_manifest)
    return local_manifest


def main() -> None:
    local_manifest = ElementTree.Element("manifest")

    for urls in sys.argv[1].split(","):
        request = Request(urls, headers={"User-Agent": "Mozilla/5.0"})
        source_manifest = urlopen(request).read()
        remote_manifest = ElementTree.fromstring(source_manifest)

        local_manifest = generate_manifest(local_manifest, remote_manifest)

    print('<?xml version="1.0" encoding="UTF-8"?>')
    print(ElementTree.tostring(local_manifest).decode())


if __name__ == '__main__':
    main()

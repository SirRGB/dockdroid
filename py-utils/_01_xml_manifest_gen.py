#!/usr/bin/python3

import sys
import xml
from urllib.request import Request, urlopen
from xml.etree import ElementTree


def is_in_manifest(
    manifest: xml,
    project_path: str = "",
    project_remote: str = "",
    project_remove: str = "",
) -> bool:
    for manifest_project in manifest.findall("project"):
        if project_path == manifest_project.get("path"):
            return True

    for manifest_project in manifest.findall("remove-project"):
        if project_remove == manifest_project.get("name"):
            return True

    for manifest_project in manifest.findall("remote"):
        if project_remote == manifest_project.get("name"):
            return True

    return False


def add_project_to_manifest(
    manifest: xml,
    project_name: str,
    project_path: str,
    project_remote: str = "",
    project_revision: str = "",
) -> xml:
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


def add_project_remove_to_manifest(manifest: xml, project_remove_name: str) -> xml:
    if is_in_manifest(manifest=manifest, project_remove=project_remove_name):
        return manifest

    element = ElementTree.Element(
        "remove-project",
        attrib={
            "name": project_remove_name,
        },
    )

    manifest.append(element)
    return manifest


def add_remote_to_manifest(
    manifest: xml, remote_name: str, remote_fetch: str, remote_revision: str = ""
) -> xml:
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


def generate_manifest(local_manifest: xml, remote_manifest: xml) -> xml:
    for projects in remote_manifest.findall("remote"):
        if projects.get("revision") == "":
            revision = ""
        else:
            revision = projects.get("revision")

        local_manifest = add_remote_to_manifest(
            manifest=local_manifest,
            remote_name=projects.get("name"),
            remote_fetch=projects.get("fetch"),
            remote_revision=revision,
        )

    for projects in remote_manifest.findall("remove-project"):
        local_manifest = add_project_remove_to_manifest(
            manifest=local_manifest, project_remove_name=projects.get("name")
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
            project_revision=revision,
        )

    ElementTree.indent(local_manifest)
    return local_manifest


def main() -> None:
    local_manifest = ElementTree.Element("manifest")

    for urls in sys.argv[1].split(","):
        request = Request(urls)
        source_manifest = urlopen(request, timeout=5).read()
        remote_manifest = ElementTree.fromstring(source_manifest)

        local_manifest = generate_manifest(local_manifest, remote_manifest)

    print('<?xml version="1.0" encoding="UTF-8"?>')
    print(ElementTree.tostring(local_manifest).decode())


if __name__ == "__main__":
    main()

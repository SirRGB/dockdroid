#!/usr/bin/python3

import argparse
import json
import sys

import requests


def arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("-p", "--path", required=True)
    return parser.parse_args()


def main(args: argparse.Namespace) -> None:
    try:
        response = requests.get(
            "https://api.github.com/repos/adoptium/temurin8-binaries/releases/latest"
        )
        response.raise_for_status()
    except requests.exceptions.HTTPError:
        print(f"http code: {response.status_code}")
        print(response)
        sys.exit(1)

    tag = json.loads(response.content)["tag_name"]
    jdk_name = "OpenJDK8U-jdk_x64_linux_hotspot_" + tag.replace("-", "")[3:] + ".tar.gz"
    try:
        with requests.get(
            "https://github.com/adoptium/temurin8-binaries/releases/download/"
            + tag
            + "/"
            + jdk_name,
            stream=True,
        ) as r:
            response.raise_for_status()
            with open(args.path + "/" + jdk_name, "wb") as f:
                f.writelines(r.iter_content(chunk_size=8192))
    except requests.exceptions.HTTPError:
        print(f"http code: {response.status_code}")
        print(response)
        sys.exit(1)
    print(tag)


if __name__ == "__main__":
    main(arguments())

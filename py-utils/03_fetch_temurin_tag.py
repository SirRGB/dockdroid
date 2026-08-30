#!/usr/bin/python3

import json
import sys

import requests


def main() -> None:
    try:
        response = requests.get(
            "https://api.github.com/repos/adoptium/temurin8-binaries/releases/latest"
        )
        response.raise_for_status()
    except requests.exceptions.HTTPError:
        print(f"http code: {response.status_code}")
        print(response)
        sys.exit(1)

    print(json.loads(response.content)["tag_name"])


if __name__ == "__main__":
    main()

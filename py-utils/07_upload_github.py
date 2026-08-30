#!/usr/bin/python3

import argparse
import json
import subprocess
import sys

import requests


def arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("-u", "--url", required=True)
    parser.add_argument("-t", "--token", required=True)
    parser.add_argument("-f", "--file", required=True)
    return parser.parse_args()


def upload_file(args: argparse.Namespace) -> None:
    file_size = subprocess.run(
        "stat -c%s " + args.file, shell=True, check=True, capture_output=True, text=True
    ).stdout
    file_type = subprocess.run(
        "file -b --mime-type " + args.file,
        shell=True,
        check=True,
        capture_output=True,
        text=True,
    ).stdout.strip()

    headers = {
        "Accept": "application/vnd.github+json",
        "Authorization": "Token " + args.token,
        "X-GitHub-Api-Version": "2026-03-10",
        "Content-Length": file_size,
        "Content-Type": file_type,
    }

    with open(args.file, "rb") as f:
        data = {"files": f.read}

    params = {
        "name": args.file.split("/")[-1],
    }

    try:
        response = requests.put(
            args.url + "?name=" + args.file.split("/")[-1],
            params=params,
            headers=headers,
            data=data,
        )

        print(args.url + "?name=" + args.file.split("/")[-1])
        response.raise_for_status()
    except requests.exceptions.HTTPError:
        print(f"http code: {response.status_code}")
        print(response)
        sys.exit(1)

    print(json.loads(response.content)["browser_download_url"])


if __name__ == "__main__":
    upload_file(arguments())

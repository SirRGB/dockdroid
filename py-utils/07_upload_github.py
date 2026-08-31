#!/usr/bin/python3

import argparse
import json
import sys

import requests


def arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("-u", "--url", required=True)
    parser.add_argument("-t", "--token", required=True)
    parser.add_argument("-f", "--file", required=True)
    return parser.parse_args()


def upload_file(args: argparse.Namespace) -> None:
    headers = {
        "Accept": "application/vnd.github+json",
        "Authorization": "Token " + args.token,
        "X-GitHub-Api-Version": "2026-03-10",
        "Content-Type": "application/octet-stream",
    }

    with open(args.file, "rb") as f:
        data = f.read()

    params = {
        "name": args.file.split("/")[-1],
    }

    url = f"{args.url}?name={args.file.split('/')[-1]}"
    try:
        response = requests.post(url=url, params=params, headers=headers, data=data)

        response.raise_for_status()
    except requests.exceptions.HTTPError:
        print(f"http code: {response.status_code}")
        print(response)
        sys.exit(1)

    print(json.loads(response.content)["browser_download_url"])


if __name__ == "__main__":
    upload_file(arguments())

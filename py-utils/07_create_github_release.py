#!/usr/bin/python3

import argparse
import sys

import requests


def arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("-r", "--repo", required=True)
    parser.add_argument("-t", "--token", required=True)
    parser.add_argument("-n", "--name", required=True)
    parser.add_argument("-d", "--desc", required=True)
    return parser.parse_args()


def create_release(args: argparse.Namespace) -> None:
    headers = {
        "Accept": "application/vnd.github+json",
        "Authorization": "Token " + args.token,
        "X-GitHub-Api-Version": "2026-03-10",
    }

    headers.update({"Content-Type": "application/x-www-form-urlencoded"})
    data = '{ "tag_name": "' + args.name + '", "body": "' + args.desc + '" }'

    release_repo = args.repo.strip("\"'")
    try:
        response = requests.post(
            "https://api.github.com/repos/" + release_repo + "/releases",
            headers=headers,
            data=data,
        )
        response.raise_for_status()
    except requests.exceptions.HTTPError:
        print(f"http code: {response.status_code}")
        print(response)
        sys.exit(1)

    print(response.json()["upload_url"].split("{")[0])


if __name__ == "__main__":
    create_release(arguments())

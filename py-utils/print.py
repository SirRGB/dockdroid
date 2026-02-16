#!/usr/bin/python3
import os
import sys

import requests


def send_telegram_message(msg: str):
    telegram_token = os.getenv("TELEGRAM_TOKEN", False)
    if not telegram_token:
        return

    data = {
        "chat_id": telegram_token,
        "parse_mode": "Markdown",
        "text": msg,
    }
    response = requests.post(
        f"https://api.telegram.org/{os.environ["TELEGRAM_TOKEN"]}/sendMessage",
        data=data,
    )


def send_telegram_end():
    telegram_token = os.getenv("TELEGRAM_TOKEN", False)
    if not telegram_token:
        return

    data = {
        "chat_id": telegram_token,
        "parse_mode": "HTML",
        "sticker": "CAADBQADGgEAAixuhBPbSa3YLUZ8DBYE",
    }
    response = requests.post(
        f"https://api.telegram.org/{os.environ["TELEGRAM_TOKEN"]}/sendMessage",
        data=data,
    )


# Skeleton for printing to stdout
def print_success(msg):
    print("\033[32m{}\033[00m".format(msg))
    send_telegram_message(msg)


def print_error(msg):
    print("\033[31m{}\033[00m".format(msg))
    send_telegram_message(msg)
    send_telegram_end()


if __name__ == "__main__":
    if len(sys.argv) > 2:
        globals()[sys.argv[1]](sys.argv[2])
    else:
        globals()[sys.argv[1]]()

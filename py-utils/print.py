#!/usr/bin/python3

import argparse
import os

import requests


def arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("-a", "--action", required=True)
    parser.add_argument("-m", "--message")

    return parser.parse_args()


def eval_arg(args: argparse.Namespace) -> None:
    match args.action:
        case "print_success":
            print_success(args.message)
        case "print_error":
            print_error(args.message)
        case "send_telegram_end":
            send_telegram_end()


def send_telegram_message(msg: str) -> None:
    telegram_token = os.getenv("TELEGRAM_TOKEN", "")
    if not telegram_token:
        return

    data = {
        "chat_id": telegram_token,
        "parse_mode": "Markdown",
        "text": msg,
    }
    requests.post(
        f"https://api.telegram.org/{os.environ['TELEGRAM_TOKEN']}/sendMessage",
        data=data,
    )


def send_telegram_end() -> None:
    telegram_token = os.getenv("TELEGRAM_TOKEN", "")
    if not telegram_token:
        return

    data = {
        "chat_id": telegram_token,
        "parse_mode": "HTML",
        "sticker": "CAADBQADGgEAAixuhBPbSa3YLUZ8DBYE",
    }
    requests.post(
        f"https://api.telegram.org/{os.environ['TELEGRAM_TOKEN']}/sendMessage",
        data=data,
    )


# Skeleton for printing to stdout
def print_success(msg) -> None:
    print(f"\033[32m{msg}\033[00m")
    send_telegram_message(msg)


def print_error(msg) -> None:
    print(f"\033[31m{msg}\033[00m")
    send_telegram_message(msg)
    send_telegram_end()


if __name__ == "__main__":
    eval_arg(arguments())

#!/usr/bin/python3

import argparse

import requests


def arguments() -> argparse.Namespace:
    parser = argparse.ArgumentParser()
    parser.add_argument("-a", "--action", required=True)
    parser.add_argument("-m", "--message")
    parser.add_argument("-t", "--token")
    parser.add_argument("-c", "--chat")
    parser.add_argument("-f", "--failed")

    return parser.parse_args()


def eval_arg(args: argparse.Namespace) -> None:
    match args.action:
        case "print_message":
            print_message(args, args.failed)
        case "send_telegram_end":
            if args.token and args.chat:
                send_telegram_end(args.token, args.chat)


def send_telegram_message(msg: str, telegram_token: str, telegram_chat: str) -> None:
    data = {
        "chat_id": telegram_chat,
        "parse_mode": "Markdown",
        "text": msg,
    }

    requests.post(
        "https://api.telegram.org/bot" + telegram_token + "/sendMessage",
        data=data,
    )


def send_telegram_end(telegram_token: str, telegram_chat: str) -> None:
    data = {
        "chat_id": telegram_chat,
        "parse_mode": "HTML",
        "sticker": "CAADBQADGgEAAixuhBPbSa3YLUZ8DBYE",
    }

    requests.post(
        "https://api.telegram.org/bot" + telegram_token + "/sendSticker",
        data=data,
    )


# Skeleton for printing to stdout
def print_message(args: argparse.Namespace, failed: bool = False) -> None:
    green = "\033[32m"
    red = "\033[31m"
    no_colour = "\033[00m"

    print(f"{green if not failed else red}{args.message}{no_colour}")
    if args.token and args.chat:
        send_telegram_message(args.message, args.token, args.chat)
        if failed:
            send_telegram_end(args.token, args.chat)


if __name__ == "__main__":
    eval_arg(arguments())

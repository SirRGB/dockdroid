#!/usr/bin/python3

import json
import sys


def main():
    try:
        json_target = json.loads(str(sys.stdin.read()))
        search_target = str(sys.argv[1])
    except TypeError:
        print("Invalid arguments")
        sys.exit(1)

    try:
        print(json_target[search_target])
    except KeyError:
        print("Argument not found")
        sys.exit(1)


if __name__ == '__main__':
    main()

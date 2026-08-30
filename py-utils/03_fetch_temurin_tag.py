#!/usr/bin/python3

import json

import requests

response = requests.get(
    "https://api.github.com/repos/adoptium/temurin8-binaries/releases/latest"
)
print(json.loads(response.content)["tag_name"])

#!venv/bin/python

import json
import os

vps_ip = os.environ.get("VPS_IP")
vps_user = os.environ.get("VPS_USER")

inventory = {
    "all": {
        "children": ["bootstrap", "provision"],
    },
    "bootstrap": {
        "hosts": ["bootstrap_host"],
        "vars": {
            "ansible_host": vps_ip,
            "ansible_user": "root",
            "ansible_ssh_common_args": "-o StrictHostKeyChecking=no",
        },
    },
    "provision": {
        "hosts": ["provision_host"],
        "vars": {
            "ansible_host": vps_ip,
            "ansible_user": vps_user,
            "ansible_ssh_common_args": "-o StrictHostKeyChecking=no",
        },
    },
    "_meta": {
        "hostvars": {},
    },
}

print(json.dumps(inventory))  # noqa: T201

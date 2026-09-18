#!/usr/bin/env python3
# Emits firewall (ufw) status/rules + real user accounts for the Sys > Sec
# sub-tab, mirroring textual-config's App/Logic/{firewall,users}.py (kept
# standalone here since that's a separate application, not a dependency).
import json
import re
import subprocess
from pathlib import Path

NOLOGIN = {"/usr/sbin/nologin", "/sbin/nologin", "/bin/false", "/usr/bin/nologin", "/bin/sync", "/usr/bin/false"}


def run(cmd):
    try:
        r = subprocess.run(cmd, capture_output=True, text=True, timeout=10)
        return r.returncode, r.stdout
    except Exception:
        return 1, ""


def get_firewall():
    code, out = run(["ufw", "status", "numbered"])
    if code != 0:
        avail, _ = run(["which", "ufw"])
        return {"available": avail == 0, "active": False, "rules": []}

    lines = out.splitlines()
    active = "active" in lines[0].lower() if lines else False
    rules = []
    for line in lines:
        line = line.strip()
        if not line.startswith("["):
            continue
        m = re.match(r"\[\s*(\d+)\]\s+(.+?)\s{2,}(ALLOW|DENY|REJECT|LIMIT)(?:\s+(IN|OUT))?\s{2,}(.+)", line)
        if m:
            rules.append({
                "num": int(m.group(1)),
                "to": m.group(2).strip(),
                "action": f"{m.group(3)} {m.group(4) or ''}".strip(),
                "from": m.group(5).strip(),
            })
    return {"available": True, "active": active, "rules": rules}


def parse_groups():
    """username -> comma-joined group names, for every user in /etc/group."""
    by_user = {}
    for line in Path("/etc/group").read_text().splitlines():
        parts = line.split(":")
        if len(parts) < 4:
            continue
        group_name = parts[0]
        for member in parts[3].split(","):
            if member:
                by_user.setdefault(member, []).append(group_name)
    return {user: ", ".join(names) for user, names in by_user.items()}


def get_users():
    groups_by_user = parse_groups()
    users = []
    for line in Path("/etc/passwd").read_text().splitlines():
        parts = line.split(":")
        if len(parts) < 7:
            continue
        username, _, uid_s, _, gecos, home, shell = parts[:7]
        try:
            uid = int(uid_s)
        except ValueError:
            continue
        if uid < 1000 or shell in NOLOGIN:
            continue
        users.append({
            "username": username,
            "uid": uid,
            "full_name": gecos.split(",")[0] if gecos else "",
            "groups": groups_by_user.get(username, ""),
        })
    return users


print(json.dumps({"firewall": get_firewall(), "users": get_users()}))

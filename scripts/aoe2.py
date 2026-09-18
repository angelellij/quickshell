#!/usr/bin/env python3
# Backend of the AOE2 tab, two modes:
#   aoe2.py        fetches the current AoE2 DE 1v1 Random Map rating (and
#                  its all-time peak) of the followed players, keeps the last
#                  known values, and prints them as JSON grouped by group
#                  name, each group sorted by all-time peak (highest first),
#                  best group first.
#   aoe2.py live   prints the matches in progress that include followed players,
#                  with all their players (rivals too) and each one's ratings.
#
# Followed players: ~/.config/quickshell/aoe2-players.csv, one "id group name"
# per line (separated by a comma or whitespace; the name may have spaces, and
# the same id may appear in several groups). Anything after a '#' is a
# comment. Created with a default list if missing.
# Last known values: ~/.local/share/quickshell/aoe2-last.json (one entry per
# followed player, overwritten on every successful fetch). No history is kept.
#
# Ratings come from the game's own community API (aoe-api.worldsedgelink.com),
# which returns every requested profile in a single call, no key needed.
# If the request fails the last known values are printed instead (with
# "stale": true), so the tab still shows something offline.
# Live matches come from aoe2companion (data.aoe2companion.com), where a match
# in progress is one without a "finished" time.
import json
import os
import re
import sys
import time
from datetime import datetime
import urllib.request

PLAYERS_FILE = os.path.expanduser("~/.config/quickshell/aoe2-players.csv")
LAST_FILE = os.path.expanduser("~/.local/share/quickshell/aoe2-last.json")
DEFAULT_PLAYERS = ["1324391", "5304079", "3123520"]
NO_GROUP = "Sin grupo"
API = "https://aoe-api.worldsedgelink.com/community/leaderboard/GetPersonalStat?title=age2&profile_ids=[{}]"
LB_1V1 = 3  # 1v1 Random Map ladder
MATCHES_API = "https://data.aoe2companion.com/api/matches?profile_ids={}&page={}"
MAX_MATCH_AGE = 4 * 3600  # an unfinished match older than this is a stuck record, not a live game


def read_players():
    """[(profile_id, group)], in file order, without repeated pairs."""
    if not os.path.exists(PLAYERS_FILE):
        os.makedirs(os.path.dirname(PLAYERS_FILE), exist_ok=True)
        with open(PLAYERS_FILE, "w") as f:
            f.write("# Jugadores seguidos de AOE2: id grupo (separados por coma o espacio).\n")
            f.write("# El grupo puede tener espacios; el mismo id puede estar en varios grupos.\n")
            f.write("\n".join(DEFAULT_PLAYERS) + "\n")
    entries = []
    with open(PLAYERS_FILE) as f:
        for line in f:
            m = re.match(r"\s*(\d+)\s*[,;\t ]?\s*(.*)", line.split("#", 1)[0])
            if not m:
                continue
            entry = (int(m.group(1)), m.group(2).strip().strip('"').strip() or NO_GROUP)
            if entry not in entries:
                entries.append(entry)
    return entries


def read_last():
    """{profile_id: {"name", "elo", "max", "t"}} from the last successful fetch."""
    try:
        with open(LAST_FILE) as f:
            return {int(pid): row for pid, row in json.load(f).items()}
    except (OSError, ValueError):
        return {}


def write_last(last):
    os.makedirs(os.path.dirname(LAST_FILE), exist_ok=True)
    tmp = LAST_FILE + ".tmp"
    with open(tmp, "w") as f:
        json.dump(last, f)
    os.replace(tmp, LAST_FILE)


def fetch_stats(ids):
    """({profile_id: alias}, {profile_id: (1v1 rating, all-time peak)}) for these profile ids."""
    data = get_json(API.format(",".join(map(str, ids))))
    if data.get("result", {}).get("code") != 0:
        raise RuntimeError("API error")
    group_owner, names = {}, {}
    for g in data.get("statGroups", []):
        for m in g.get("members", []):
            group_owner[g["id"]] = m["profile_id"]
            names[m["profile_id"]] = m.get("alias") or str(m["profile_id"])
    ratings = {}
    for s in data.get("leaderboardStats", []):
        pid = group_owner.get(s["statgroup_id"])
        if pid is not None and s["leaderboard_id"] == LB_1V1:
            ratings[pid] = (s["rating"], s.get("highestrating"))
    return names, ratings


def fetch(ids):
    names, ratings = fetch_stats(ids)
    now = int(time.time())
    return [
        {"t": now, "id": pid, "name": names[pid], "elo": ratings.get(pid, (None, None))[0], "max": ratings.get(pid, (None, None))[1]}
        for pid in ids if pid in names
    ]


def build(entries, last, stale):
    groups = {}
    for pid, group in entries:
        row = last.get(pid)
        groups.setdefault(group, []).append({
            "id": pid,
            "name": row["name"] if row else "#%d" % pid,
            "elo": row["elo"] if row else None,
            "max": row["max"] if row else None,
            "t": row["t"] if row else None,
        })

    def by_peak(p):
        # All-time peak first; the current rating stands in when the peak is unknown.
        peak = p["max"] if p["max"] is not None else p["elo"]
        return (peak is None, -(peak or 0))

    for players in groups.values():
        players.sort(key=by_peak)
    ranked = [{"name": name, "players": players} for name, players in groups.items()]
    ranked.sort(key=lambda g: by_peak(g["players"][0]))
    updated = max((p["t"] or 0 for g in ranked for p in g["players"]), default=0)
    return {"stale": stale, "updated": updated, "groups": ranked}


def get_json(url):
    # aoe2companion answers 403 to urllib's default User-Agent.
    req = urllib.request.Request(url, headers={"User-Agent": "quickshell-jde"})
    with urllib.request.urlopen(req, timeout=15) as r:
        return json.load(r)


def recent_matches(ids):
    """Latest matches of the followed players, newest first. The API always
    returns 20 per page (it ignores `count`), so keep paging (up to 3 pages)
    only while the page still reaches back into the window where a match
    could be live."""
    matches = []
    for page in (1, 2, 3):
        batch = get_json(MATCHES_API.format(",".join(map(str, ids)), page)).get("matches", [])
        matches += batch
        if len(batch) < 20 or not batch[-1].get("started"):
            break
        oldest = datetime.fromisoformat(batch[-1]["started"].replace("Z", "+00:00")).timestamp()
        if time.time() - oldest > MAX_MATCH_AGE:
            break
    return matches


def live(entries):
    """Matches in progress that include a followed player, with every player
    of both sides and their 1v1 rating / peak:
    {"matches": [{"id", "type", "since", "teams": [[{"id", "name", "elo", "max"}]]}]},
    or {"matches": null} if the matches request fails."""
    ids = list({pid for pid, _ in entries})
    if not ids:
        return {"matches": []}
    try:
        matches = recent_matches(ids)
    except Exception:
        return {"matches": None}
    now = time.time()
    found = []
    for m in matches:
        if m.get("finished") or not m.get("started"):
            continue
        since = datetime.fromisoformat(m["started"].replace("Z", "+00:00")).timestamp()
        if now - since > MAX_MATCH_AGE:
            continue
        if any(p["profileId"] in ids for t in m.get("teams", []) for p in t.get("players", [])):
            found.append((m, int(since)))
    if not found:
        return {"matches": []}

    # One ratings request for everybody in every live match (rivals included).
    everyone = list({p["profileId"] for m, _ in found for t in m["teams"] for p in t["players"]})
    try:
        _, ratings = fetch_stats(everyone)
    except Exception:
        ratings = {}

    out = []
    for m, since in found:
        out.append({
            "id": m["matchId"],
            "type": m.get("leaderboardName") or m.get("leaderboardId") or "Partida",
            "since": since,
            "teams": [
                [
                    {
                        "id": p["profileId"],
                        "name": p.get("name") or "#%d" % p["profileId"],
                        "elo": ratings.get(p["profileId"], (None, None))[0],
                        "max": ratings.get(p["profileId"], (None, None))[1],
                    }
                    for p in t.get("players", [])
                ]
                for t in m.get("teams", [])
            ],
        })
    return {"matches": out}


def main():
    entries = read_players()
    if sys.argv[1:] == ["live"]:
        print(json.dumps(live(entries)))
        return
    ids = list(dict.fromkeys(pid for pid, _ in entries))
    last = read_last()
    stale = False
    if ids:
        try:
            last.update({row["id"]: row for row in fetch(ids)})
            # Only the currently followed players are kept.
            last = {pid: row for pid, row in last.items() if pid in ids}
            write_last({str(pid): row for pid, row in last.items()})
        except Exception:
            stale = True
    print(json.dumps(build(entries, last, stale)))


main()

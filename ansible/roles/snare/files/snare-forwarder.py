#!/usr/bin/env python3
"""Ships Snare web-honeypot requests to the SecDash ingest endpoint.

Snare's own access log (inside the container) is the only place that records the
real client address; Tanner's log does not. This follows that log, builds one
JSON event per request and POSTs batches to SecDash.
"""
import json
import os
import re
import subprocess
import sys
import time
import urllib.request
from datetime import datetime, timezone

INGEST = os.environ.get("SECDASH_INGEST", "http://10.0.2.4:8081/api/ingest/stream?sensor=vm-snare")
CONTAINER = os.environ.get("SNARE_CONTAINER", "snare-snare-1")
LOGFILE = "/opt/snare/snare.log"
STATE = os.environ.get("STATE_FILE", "/var/lib/snare-forwarder/last_ts")

LINE = re.compile(
    r'aiohttp\.access:log: (?P<ip>\S+) \[(?P<ts>[^\]]+)\] "(?P<method>\S+) (?P<path>\S+) HTTP/[\d.]+" '
    r'(?P<status>\d{3}) \S+ "[^"]*" "(?P<ua>.*)"$'
)


def load_state():
    try:
        with open(STATE) as f:
            return float(f.read().strip())
    except (OSError, ValueError):
        return time.time()  # first run: do not replay history (already ingested without addresses)


def save_state(ts):
    try:
        os.makedirs(os.path.dirname(STATE), exist_ok=True)
        with open(STATE, "w") as f:
            f.write(str(ts))
    except OSError:
        pass


def parse(line):
    m = LINE.search(line.rstrip("\n"))
    if not m:
        return None
    try:
        when = datetime.strptime(m["ts"], "%d/%b/%Y:%H:%M:%S %z")
    except ValueError:
        return None
    ev = {
        "eventid": "snare.http.request",
        "timestamp": when.astimezone(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "src_ip": m["ip"],
        "dst_port": 80,
        "protocol": "http",
        "input": "%s %s HTTP/1.1" % (m["method"], m["path"]),
        "status": int(m["status"]),
        "user_agent": m["ua"],
    }
    return when.timestamp(), ev


def post(batch):
    req = urllib.request.Request(INGEST, data=json.dumps(batch).encode(), headers={"Content-Type": "application/json"})
    with urllib.request.urlopen(req, timeout=5) as r:
        return r.status < 300


def main():
    last = load_state()
    pending = []
    proc = subprocess.Popen(
        ["docker", "exec", CONTAINER, "tail", "-n", "+1", "-F", LOGFILE],
        stdout=subprocess.PIPE, stderr=subprocess.DEVNULL, text=True, bufsize=1,
    )
    for line in proc.stdout:
        parsed = parse(line)
        if parsed and parsed[0] >= last:
            pending.append(parsed)
        if pending:
            try:
                if post([e for _, e in pending]):
                    last = max(last, max(t for t, _ in pending))
                    save_state(last)
                    pending = []
            except Exception as exc:  # network error: keep the batch and retry with the next line
                print("ingest failed: %s" % exc, file=sys.stderr)
                pending = pending[-1000:]
                time.sleep(2)
    return proc.wait() or 1  # container stopped; systemd restarts us


if __name__ == "__main__":
    sys.exit(main())

#!/usr/bin/env python3
"""Expose tunet-bash JSON status in Prometheus text format."""

import argparse
from datetime import datetime
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
import json
import os
import signal
import socket
import subprocess
import sys
import threading
import time


def label(value):
    return (
        str(value)
        .replace("\\", "\\\\")
        .replace("\n", "\\n")
        .replace('"', '\\"')
    )


def sample(name, value, labels=None):
    if labels:
        label_set = ",".join(
            '{}="{}"'.format(key, label(val)) for key, val in labels.items()
        )
        name += "{" + label_set + "}"
    return "{} {}".format(name, value)


def family(lines, name, description, samples):
    lines.append("# HELP {} {}".format(name, description))
    lines.append("# TYPE {} gauge".format(name))
    lines.extend(sample(name, value, labels) for value, labels in samples)


def render_metrics(data, duration, success=True):
    lines = []
    family(
        lines,
        "tunet_exporter_scrape_success",
        "Whether tunet-bash returned valid status JSON.",
        [(int(success), None)],
    )
    family(
        lines,
        "tunet_exporter_scrape_duration_seconds",
        "Time spent querying tunet-bash.",
        [(duration, None)],
    )
    if not success:
        return "\n".join(lines) + "\n"

    start = datetime.fromisoformat(data["session"]["start"])
    devices = data["network"]["devices"]

    values = (
        (
            "tunet_session_start_time_seconds",
            "Start time of the current session, Unix seconds.",
            start.timestamp(),
        ),
        (
            "tunet_session_duration_seconds",
            "Duration of the current session in seconds.",
            data["session"]["seconds"],
        ),
        (
            "tunet_account_balance_cny",
            "Account balance in CNY.",
            data["billing"]["balance"],
        ),
        (
            "tunet_online_devices",
            "Number of online devices reported by tunet-bash.",
            data["network"]["device_count"],
        ),
        (
            "tunet_session_inbound_bytes",
            "Inbound bytes in the current session.",
            data["traffic"]["inbound"],
        ),
        (
            "tunet_session_outbound_bytes",
            "Outbound bytes in the current session.",
            data["traffic"]["outbound"],
        ),
        (
            "tunet_session_total_bytes",
            "Total bytes in the current session.",
            data["traffic"]["total"],
        ),
        (
            "tunet_monthly_traffic_bytes",
            "Monthly traffic in bytes.",
            data["traffic"]["monthly"],
        ),
    )
    for name, description, value in values:
        family(lines, name, description, [(value, None)])

    family(
        lines,
        "tunet_account_info",
        "Account and billing information.",
        [
            (
                1,
                {
                    "user": data["user"],
                    "billing_name": data["billing"]["name"],
                    "product": data["billing"]["product"],
                    "system_version": data["system"]["version"],
                },
            )
        ],
    )
    family(
        lines,
        "tunet_network_info",
        "Current network addresses.",
        [
            (
                1,
                {
                    "ip": data["network"]["ip"],
                    "mac": data["network"]["mac"],
                },
            )
        ],
    )

    online = []
    info = []
    for device in devices:
        rad_label = {"rad_online_id": device["rad"]}
        online.append((1, rad_label))
        info.append(
            (
                1,
                {
                    **rad_label,
                    "ipv4": device["ipv4"] or "",
                    "ipv6": device["ipv6"] or "",
                    "class": device["class"] or "",
                    "os": device["os"] or "",
                },
            )
        )
    family(
        lines,
        "tunet_device_online",
        "Online device identified by RAD online ID.",
        online,
    )
    family(
        lines,
        "tunet_device_info",
        "Online device address and system information.",
        info,
    )
    return "\n".join(lines) + "\n"


def collect(command, timeout):
    started = time.monotonic()
    try:
        result = subprocess.run(
            command,
            capture_output=True,
            text=True,
            encoding="utf-8",
            timeout=timeout,
            check=False,
        )
        if result.returncode:
            raise ValueError(
                "tunet-bash exited with status {}: {}".format(
                    result.returncode, result.stderr.strip()
                )
            )
        data = json.loads(result.stdout)
        return render_metrics(data, time.monotonic() - started)
    except (
        OSError,
        subprocess.TimeoutExpired,
        ValueError,
        KeyError,
        TypeError,
    ) as exc:
        print("tunet-exporter: scrape failed: {}".format(exc), file=sys.stderr)
        return render_metrics(None, time.monotonic() - started, success=False)


def keepalive(command, interval):
    while True:
        subprocess.run(command, check=False)
        time.sleep(interval)


class MetricsHandler(BaseHTTPRequestHandler):
    def do_GET(self):
        if self.path != "/metrics":
            self.send_error(404)
            return
        body = collect(
            self.server.tunet_command, self.server.tunet_timeout
        ).encode("utf-8")
        self.send_response(200)
        self.send_header(
            "Content-Type", "text/plain; version=0.0.4; charset=utf-8"
        )
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)


class DualStackServer(ThreadingHTTPServer):
    address_family = socket.AF_INET6

    def server_bind(self):
        self.socket.setsockopt(socket.IPPROTO_IPV6, socket.IPV6_V6ONLY, 0)
        super().server_bind()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument(
        "--host",
        default="::",
        help="listen address (default: ::, IPv4 and IPv6)",
    )
    parser.add_argument(
        "--port", type=int, default=9877, help="listen port (default: 9877)"
    )
    parser.add_argument(
        "--timeout",
        type=float,
        default=15,
        help="tunet-bash timeout in seconds",
    )
    parser.add_argument(
        "--tunet-command",
        default="tunet-bash",
        help="path to tunet-bash executable",
    )
    parser.add_argument(
        "--auth",
        choices=("auto", "4", "6", "generic"),
        help="authentication endpoint passed to tunet-bash",
    )
    parser.add_argument(
        "--curl-extra-arg",
        action="append",
        default=[],
        help="extra curl argument passed to tunet-bash; repeat as needed",
    )
    args = parser.parse_args()
    mode = os.environ.get("TUNET_MODE", "exporter")
    if mode not in ("exporter", "keepalive", "both"):
        parser.error("TUNET_MODE must be exporter, keepalive, or both")

    tunet_args = []
    if args.auth:
        tunet_args += ["--auth", args.auth]
    for extra in args.curl_extra_arg:
        tunet_args += ["--curl-extra-args", extra]

    command = [
        args.tunet_command,
        "--whoami",
        "--verbose",
        "--output",
        "json",
    ] + tunet_args
    keepalive_command = [args.tunet_command, "--assert"] + tunet_args

    def stop(_signum, _frame):
        raise KeyboardInterrupt

    signal.signal(signal.SIGTERM, stop)

    if mode == "keepalive":
        try:
            keepalive(
                keepalive_command,
                float(os.environ.get("TUNET_KEEPALIVE_INTERVAL", "120")),
            )
        except KeyboardInterrupt:
            pass
        return

    if mode == "both":
        interval = float(os.environ.get("TUNET_KEEPALIVE_INTERVAL", "120"))
        threading.Thread(
            target=keepalive, args=(keepalive_command, interval), daemon=True
        ).start()

    server_type = DualStackServer if ":" in args.host else ThreadingHTTPServer
    server = server_type((args.host, args.port), MetricsHandler)
    server.tunet_command = command
    server.tunet_timeout = args.timeout
    address = "[{}]".format(args.host) if ":" in args.host else args.host
    print(
        "tunet-exporter listening on {}:{}".format(address, args.port),
        file=sys.stderr,
    )

    try:
        server.serve_forever()
    except KeyboardInterrupt:
        pass
    finally:
        server.server_close()


if __name__ == "__main__":
    main()

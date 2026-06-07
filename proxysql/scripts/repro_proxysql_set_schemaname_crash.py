#!/usr/bin/env python3
"""
ProxySQL crash repro helper focused on COM_INIT_DB/schema handling.

This script intentionally sends high-volume COM_INIT_DB packets with edge-case
and malformed schema payloads while keeping packet sequencing valid, to stress
MySQL_Session::get_pkts_from_client() and set_schemaname() code paths.

Requires: pip install pymysql
"""

import argparse
import os
import random
import threading
import time

import pymysql


def _send_packet(conn, payload: bytes) -> None:
    """Send one raw MySQL packet with current sequence id."""
    length = len(payload)
    if length > 0xFFFFFF:
        raise ValueError("Payload too large for single packet")

    seq = conn._next_seq_id & 0xFF
    header = bytes((length & 0xFF, (length >> 8) & 0xFF, (length >> 16) & 0xFF, seq))
    conn._sock.sendall(header + payload)
    conn._next_seq_id = (seq + 1) & 0xFF


def _send_com_init_db(conn, db_payload: bytes) -> None:
    """Send COM_INIT_DB (0x02) with arbitrary bytes as schema payload."""
    # New command cycle: client command packet should start with seq=0.
    conn._next_seq_id = 0

    payload = b"\x02" + db_payload
    _send_packet(conn, payload)

    # Keep protocol synchronized by reading exactly one server response packet.
    # ProxySQL usually returns OK or ERR for COM_INIT_DB.
    try:
        conn._read_packet()
    except Exception:
        # Expected in many malformed cases; caller handles reconnect/retry.
        raise


def _edge_case_payloads(max_len: int):
    """Generate deterministic + random payloads for schema fuzzing."""
    # Deterministic cases first
    cases = [
        b"",
        b"mysql",
        b"information_schema",
        b"performance_schema",
        b"sys",
        b"a",
        b"A" * 63,
        b"B" * 64,
        b"C" * 255,
        b"D" * 256,
        b"E" * 1024,
        b"x\x00y",
        b"\x00",
        b"\x00\x00\x00",
        b"db\xff\xfe\xfd",
    ]

    for c in cases:
        if len(c) <= max_len:
            yield c

    # Random binary payloads
    for _ in range(32):
        ln = random.randint(0, max_len)
        yield os.urandom(ln)


def worker(args, wid):
    random.seed((int(time.time() * 1000000) ^ (wid * 7919)) & 0xFFFFFFFF)

    for i in range(args.loops):
        try:
            conn = pymysql.connect(
                host=args.host,
                port=args.port,
                user=args.user,
                password=args.password,
                autocommit=True,
                connect_timeout=3,
                read_timeout=3,
                write_timeout=3,
                charset="utf8mb4",
            )

            # Establish baseline valid path first.
            try:
                conn.select_db("mysql")
            except Exception:
                pass

            sent = 0
            for db_payload in _edge_case_payloads(args.max_db_len):
                if sent >= args.burst:
                    break
                try:
                    _send_com_init_db(conn, db_payload)
                except Exception:
                    # Connection likely dropped by ProxySQL for malformed input.
                    break
                sent += 1

            conn.close()
        except Exception:
            # Ignore and continue, this is a stress/fuzz repro loop.
            pass

        if wid == 0 and i % 200 == 0:
            print(f"[worker {wid}] iteration={i}")

        if args.sleep_ms:
            time.sleep(args.sleep_ms / 1000.0)


def main():
    p = argparse.ArgumentParser(description="ProxySQL COM_INIT_DB crash repro stressor")
    p.add_argument("--host", required=True)
    p.add_argument("--port", type=int, default=6033)
    p.add_argument("--user", required=True)
    p.add_argument("--password", required=True)
    p.add_argument("--workers", type=int, default=8)
    p.add_argument("--loops", type=int, default=20000)
    p.add_argument("--burst", type=int, default=24, help="COM_INIT_DB packets per connection")
    p.add_argument("--max-db-len", type=int, default=8192, help="max schema payload bytes")
    p.add_argument("--sleep-ms", type=int, default=0)
    args = p.parse_args()

    threads = []
    for wid in range(args.workers):
        t = threading.Thread(target=worker, args=(args, wid), daemon=True)
        t.start()
        threads.append(t)

    for t in threads:
        t.join()


if __name__ == "__main__":
    main()

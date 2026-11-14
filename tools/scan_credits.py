#!/usr/bin/env python3
"""Rescan MIA work pages for explicit bylines and refresh catalog credits.

Usage:
    python3 tools/scan_credits.py --language pt
    python3 tools/scan_credits.py --language pt --limit 200
    python3 tools/scan_credits.py --language pt --apply

The scan is resumable (SQLite under tools/.cache), polite (a shared rate limit),
and conservative: only visible source bylines are recorded. PDFs, missing
bylines, redirects, and fetch failures stay uncredited and are reported as such.
The resulting ``tools/credits-<lang>.json`` is merged by the catalog builders,
so a later full rebuild keeps the evidence.

The hosting archive is never used as a fallback author. A work found in
Lenin's archive can therefore carry another person's explicitly printed byline.
"""
import argparse
import concurrent.futures
import json
import os
import sqlite3
import sys
import threading
import time
import urllib.error
import urllib.request
from datetime import datetime, timezone
from pathlib import Path
from urllib.parse import quote, urldefrag, urljoin

import credits

ROOT = Path(__file__).resolve().parent.parent
CATALOGS = {
    "pt": ("https://www.marxists.org/portugues/", ROOT / "ios/Praxis/Resources/catalog-pt.json"),
    "en": ("https://www.marxists.org/", ROOT / "ios/Praxis/Resources/catalog-en.json"),
    "es": ("https://www.marxists.org/espanol/", ROOT / "ios/Praxis/Resources/catalog-es.json"),
}
RATE_LOCK = "/private/tmp/praxis-credit-scan-rate.lock"
RATE_LOCK_THREAD = threading.Lock()
NEXT_REQUEST = 0.0
MAX_BYTES = 64 * 1024
USER_AGENT = "PraxisCreditScan/1.0 (catalog attribution audit)"


def pace(delay):
    """Share one request window across threads and concurrent Praxis scans."""
    global NEXT_REQUEST
    with RATE_LOCK_THREAD:
        now = time.monotonic()
        wait = max(0.0, NEXT_REQUEST - now)
        NEXT_REQUEST = max(now, NEXT_REQUEST) + delay
    if wait:
        time.sleep(wait)
    with open(RATE_LOCK, "a+") as handle:
        try:
            import fcntl
            fcntl.flock(handle, fcntl.LOCK_EX)
            handle.seek(0)
            try:
                last = float(handle.read().strip())
            except ValueError:
                last = 0.0
            shared_wait = delay - (time.time() - last)
            if shared_wait > 0:
                time.sleep(shared_wait)
            handle.seek(0)
            handle.truncate()
            handle.write(str(time.time()))
            handle.flush()
            fcntl.flock(handle, fcntl.LOCK_UN)
        except (ImportError, OSError):
            pass


def catalog_paths(language):
    """Unique HTML work paths listed under authors in a bundled catalog."""
    _, catalog_file = CATALOGS[language]
    data = json.loads(catalog_file.read_text(encoding="utf-8"))
    seen = set()
    for author in data.get("authors", []):
        for row in author.get("works", []):
            if len(row) < 2 or not isinstance(row[1], str) or not row[1]:
                continue
            path = urldefrag(row[1])[0]
            if path.lower().split("?")[0].endswith(".pdf"):
                continue
            seen.add(path)
    return sorted(seen)


def looks_like_error_page(text):
    head = text[:4000].lower()
    return "<title>object not found" in head or "error 404" in head and "not found" in head


def inspect(path, base, delay):
    url = urljoin(base, quote(path, safe="/%?=&:+@"))
    if not url.startswith(base):
        return dict(status="error", error="outside archive", url=url)
    pace(delay)
    request = urllib.request.Request(
        url,
        headers={
            "User-Agent": USER_AGENT,
            "Range": "bytes=0-%d" % (MAX_BYTES - 1),
            "Accept-Encoding": "identity",
        },
    )
    try:
        with urllib.request.urlopen(request, timeout=30) as response:
            if not response.geturl().startswith(base):
                return dict(status="error", error="redirect outside archive", url=url)
            raw = response.read(MAX_BYTES)
            charset = response.headers.get_content_charset() or "utf-8"
        try:
            text = raw.decode(charset, errors="replace")
        except LookupError:
            text = raw.decode("utf-8", errors="replace")
        if looks_like_error_page(text):
            return dict(status="error", error="source returned an error page", url=url)
        found = credits.extract_credit(text)
        if not found:
            return dict(status="no_byline", url=url)
        return dict(status="credited", url=url, **found)
    except urllib.error.HTTPError as error:
        return dict(status="error", error="HTTP %s" % error.code, url=url)
    except (urllib.error.URLError, TimeoutError, OSError, ValueError) as error:
        return dict(status="error", error=str(error)[:300], url=url)


def open_db(path):
    database = sqlite3.connect(str(path))
    database.execute("PRAGMA busy_timeout = 5000")
    database.execute(
        "CREATE TABLE IF NOT EXISTS scan ("
        "path TEXT PRIMARY KEY, status TEXT, credit TEXT, evidence TEXT, "
        "url TEXT, error TEXT, fetched TEXT)"
    )
    # Kept in a separate table so a scan started with an older module can keep
    # inserting its seven scan columns without a schema mismatch. Rows with no
    # provenance, or with an older extractor version, are not exported.
    database.execute(
        "CREATE TABLE IF NOT EXISTS scan_provenance ("
        "path TEXT PRIMARY KEY, extractor TEXT NOT NULL, recorded TEXT)"
    )
    return database


def pending_paths(database, paths, refresh=False, retry_errors=False):
    """Paths that still need a scan with the current extractor."""
    pending = []
    for path in paths:
        row = database.execute(
            "SELECT s.status, p.extractor FROM scan AS s "
            "LEFT JOIN scan_provenance AS p ON p.path = s.path WHERE s.path = ?",
            (path,),
        ).fetchone()
        if row and not refresh:
            status, extractor = row
            if extractor == str(credits.EXTRACTOR_VERSION) and not (
                retry_errors and status == "error"
            ):
                continue
        pending.append(path)
    return pending


def write_credits_file(database, language, output):
    rows = database.execute(
        "SELECT s.path, s.credit, s.evidence, s.url FROM scan AS s "
        "JOIN scan_provenance AS p ON p.path = s.path "
        "WHERE s.status='credited' AND s.credit IS NOT NULL AND s.credit != '' "
        "AND p.extractor = ? ORDER BY s.path",
        (str(credits.EXTRACTOR_VERSION),),
    ).fetchall()
    base, _ = CATALOGS[language]
    entries = {}
    for path, credit, evidence, url in rows:
        normalized = credits.normalize_credit(credit)
        if not normalized:
            continue
        entries[path] = {"credit": normalized, "evidence": evidence or "", "url": url or ""}
    payload = {
        "version": 2,
        "language": language,
        "source": base,
        "extractor": credits.EXTRACTOR_VERSION,
        "generated": datetime.now(timezone.utc).strftime("%Y-%m-%d"),
        "credits": entries,
    }
    output.parent.mkdir(parents=True, exist_ok=True)
    temporary = output.with_suffix(output.suffix + ".tmp")
    temporary.write_text(
        json.dumps(payload, ensure_ascii=False, separators=(",", ":")) + "\n",
        encoding="utf-8",
    )
    os.replace(str(temporary), str(output))
    return len(entries)


def apply_to_catalog(language, credits_file):
    _, catalog_file = CATALOGS[language]
    data = json.loads(catalog_file.read_text(encoding="utf-8"))
    credit_map = credits.load_credit_map(
        str(credits_file), expected_language=language
    )
    if not credit_map:
        return 0
    changed = 0
    for author in data.get("authors", []):
        rows = author.get("works", [])
        if not isinstance(rows, list):
            continue
        before = [list(row) if isinstance(row, list) else row for row in rows]
        credits.apply_credit_map(rows, credit_map)
        changed += sum(1 for old, new in zip(before, rows) if old != new)
    if not changed:
        return 0
    temporary = catalog_file.with_suffix(catalog_file.suffix + ".tmp")
    temporary.write_text(
        json.dumps(data, ensure_ascii=False, separators=(",", ":")),
        encoding="utf-8",
    )
    os.replace(str(temporary), str(catalog_file))
    return changed


def counts(database):
    return dict(database.execute("SELECT status, count(*) FROM scan GROUP BY status"))


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--language", choices=sorted(CATALOGS), required=True)
    parser.add_argument("--limit", type=int, default=0, help="stop after N new scans")
    parser.add_argument("--workers", type=int, default=3)
    parser.add_argument("--delay", type=float, default=0.5, help="seconds between requests")
    parser.add_argument("--retry-errors", action="store_true")
    parser.add_argument("--refresh", action="store_true", help="rescan completed paths too")
    parser.add_argument("--apply", action="store_true", help="fill empty catalog credits")
    parser.add_argument("--output", type=Path, help="default tools/credits-<lang>.json")
    parser.add_argument("--db", type=Path, help="default tools/.cache/credits-<lang>.sqlite")
    args = parser.parse_args()

    base, _ = CATALOGS[args.language]
    output = args.output or ROOT / ("tools/credits-%s.json" % args.language)
    database_path = args.db or ROOT / ("tools/.cache/credits-%s.sqlite" % args.language)
    database_path.parent.mkdir(parents=True, exist_ok=True)
    database = open_db(database_path)

    paths = catalog_paths(args.language)
    pending = pending_paths(
        database, paths, refresh=args.refresh, retry_errors=args.retry_errors
    )
    already_scanned = len(paths) - len(pending)
    total_pending = len(pending)
    if args.limit:
        pending = pending[: args.limit]

    print(
        "%d catalog paths; %d already scanned; %d pending%s"
        % (
            len(paths),
            already_scanned,
            len(pending),
            " (of %d)" % total_pending if len(pending) != total_pending else "",
        ),
        flush=True,
    )
    workers = max(1, min(args.workers, 4))
    processed = 0
    with concurrent.futures.ThreadPoolExecutor(max_workers=workers) as pool:
        futures = {pool.submit(inspect, path, base, args.delay): path for path in pending}
        for future in concurrent.futures.as_completed(futures):
            path = futures[future]
            try:
                result = future.result()
            except Exception as error:  # defensive: one bad page must not stop the scan
                result = dict(status="error", error=str(error)[:300], url="")
            fetched = datetime.now(timezone.utc).isoformat(timespec="seconds")
            database.execute(
                "INSERT OR REPLACE INTO scan VALUES (?,?,?,?,?,?,?)",
                (
                    path,
                    result.get("status", "error"),
                    result.get("credit", ""),
                    result.get("evidence", ""),
                    result.get("url", ""),
                    result.get("error", ""),
                    fetched,
                ),
            )
            database.execute(
                "INSERT OR REPLACE INTO scan_provenance VALUES (?,?,?)",
                (path, str(credits.EXTRACTOR_VERSION), fetched),
            )
            database.commit()
            processed += 1
            if processed % 100 == 0:
                print("  %d/%d %s" % (processed, len(pending), counts(database)), flush=True)

    written = write_credits_file(database, args.language, output)
    print("wrote %d credited paths -> %s" % (written, output), flush=True)
    if args.apply:
        changed = apply_to_catalog(args.language, output)
        print("filled %d empty catalog credits" % changed, flush=True)
    print("scan totals: %s" % counts(database), flush=True)


if __name__ == "__main__":
    sys.exit(main())

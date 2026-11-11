#!/usr/bin/env python3
"""Audit Portuguese catalog credits against source pages; never guesses authorship.

Writes a JSONL report, one line per catalog entry. PDF records are flagged for
manual inspection; a writer's archive and a matching title are not bylines.
"""
import argparse
import concurrent.futures
import html
from html.parser import HTMLParser
import json
import os
from pathlib import Path
import re
import threading
import time
import unicodedata
import urllib.error
import urllib.request
from urllib.parse import urljoin, urldefrag

BASE = 'https://www.marxists.org/portugues/'
RATE_LOCK = threading.Lock()
NEXT_REQUEST = 0.0

def pace_requests():
    global NEXT_REQUEST
    with RATE_LOCK:
        now = time.monotonic()
        delay = max(0, NEXT_REQUEST - now)
        NEXT_REQUEST = max(now, NEXT_REQUEST) + 1.0
    if delay:
        time.sleep(delay)
ROOT = Path(__file__).resolve().parents[1]
CATALOG = ROOT / 'ios/Praxis/Resources/catalog-pt.json'

class Headings(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.depth = 0
        self.capture = False
        self.chunks = []
        self.meta = []
    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag in ('h1', 'h2', 'h3', 'h4'):
            self.capture = True
            self.chunks.append([])
        if tag == 'meta' and attrs.get('name', '').lower() in ('author', 'dc.creator', 'dc.author'):
            self.meta.append(attrs.get('content', ''))
    def handle_endtag(self, tag):
        if tag in ('h1', 'h2', 'h3', 'h4'):
            self.capture = False
    def handle_data(self, data):
        if self.capture and self.chunks:
            self.chunks[-1].append(data)
    def texts(self):
        return [' '.join(' '.join(v).split()) for v in self.chunks] + self.meta

def folded(s):
    return ''.join(c for c in unicodedata.normalize('NFKD', s.casefold()) if c.isalnum() and not unicodedata.combining(c))

def audit(entry):
    author, work = entry
    title, path = work[:2]
    base = {'path': path, 'title': title, 'listed_author': author.get('full') or author['name']}
    if len(work) > 4:
        base.update(status='indexed_credit' if work[4] else 'unverified', credit=work[4], evidence='archive index')
        return base
    if urldefrag(path)[0].lower().split('?', 1)[0].endswith('.pdf'):
        return dict(base, status='unverified', reason='PDF requires credit inspection')
    url = urljoin(BASE, path)
    if not url.startswith(BASE):
        return dict(base, status='unverified', reason='external URL')
    try:
        pace_requests()
        req = urllib.request.Request(url, headers={'User-Agent': 'PraxisAuthorshipAudit/1.0 (catalog verification)'})
        with urllib.request.urlopen(req, timeout=20) as response:
            data = response.read(1024 * 1024)
            encoding = response.headers.get_content_charset() or 'utf-8'
        parser = Headings()
        parser.feed(data.decode(encoding, errors='replace'))
        texts = [t for t in parser.texts() if t and len(t) < 220]
        # A heading containing the source's complete name is evidence. A surname
        # alone can appear in the title of another person's essay.
        full = re.sub(r'\s*\([^)]*\)', '', base['listed_author']).strip()
        normalized = folded(full)
        title_norm = folded(title)
        matches = [t for t in texts if len(normalized) >= 7 and folded(t) == normalized and folded(t) != title_norm]
        if matches:
            return dict(base, status='matched_heading', evidence=matches[0], url=url)
        return dict(base, status='unverified', reason='no matching explicit byline', headings=texts[:8], url=url)
    except (OSError, ValueError, LookupError) as e:
        return dict(base, status='unverified', reason='fetch failed: ' + str(e), url=url)

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument('--output', required=True)
    ap.add_argument('--workers', type=int, default=3)
    args = ap.parse_args()
    data = json.loads(CATALOG.read_text())
    entries = [(a, w) for a in data['authors'] for w in a.get('works', [])]
    completed = set()
    out = Path(args.output)
    if out.exists():
        with out.open() as f:
            for line in f:
                try:
                    row = json.loads(line)
                    
                    if not row.get('reason', '').startswith('fetch failed:'):
                        completed.add((row['path'], row['listed_author']))
                except (ValueError, KeyError):
                    pass
    pending = [(a, w) for a, w in entries if (w[1], a.get('full') or a['name']) not in completed]
    counts = {}
    with out.open('a') as f, concurrent.futures.ThreadPoolExecutor(max_workers=max(1, min(args.workers, 3))) as pool:
        for i, row in enumerate(pool.map(audit, pending), 1):
            f.write(json.dumps(row, ensure_ascii=False) + '\n')
            f.flush()
            counts[row['status']] = counts.get(row['status'], 0) + 1
            if i % 100 == 0:
                print(f'{i}/{len(pending)}: {counts}', flush=True)
    print('Finished:', counts, flush=True)

if __name__ == '__main__':
    main()

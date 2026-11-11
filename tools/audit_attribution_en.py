#!/usr/bin/env python3
"""Resumable, conservative audit of English MIA work-page authorship.

Results are evidence for human review, not automatic catalog edits. HTML headers
and explicit author meta tags are sampled; PDFs and absent/ambiguous bylines are
marked for manual review. Downloads share a 0.4 second rate limit with other
Praxis auditors. Retry failures with --retry-errors; results survive restarts.
"""
import argparse
import fcntl
import html
from html.parser import HTMLParser
import json
import os
from pathlib import Path
import re
import sqlite3
import time
from urllib.error import HTTPError, URLError
from urllib.parse import urljoin, urldefrag, quote
from urllib.request import Request, urlopen

ROOT = Path(__file__).resolve().parent.parent
BASE = 'https://www.marxists.org/'
LOCK = '/private/tmp/praxis-archive-audit-rate.lock'

class Headers(HTMLParser):
    def __init__(self):
        super().__init__(convert_charrefs=True)
        self.active = []
        self.candidates = []
    def handle_starttag(self, tag, attrs):
        attrs = dict(attrs)
        if tag == 'meta' and (attrs.get('name','').lower() in ('author','dc.creator','dcterms.creator')):
            self.candidates.append(('meta', attrs.get('content','')))
        cls = attrs.get('class','').lower().split()
        if tag in ('h1','h2','h3') or any(x in cls for x in ('author','byline','writer')):
            self.active.append([tag, []])
    def handle_data(self, text):
        for element in self.active:
            element[1].append(text)
    def handle_endtag(self, tag):
        for i in range(len(self.active)-1, -1, -1):
            if self.active[i][0] == tag:
                _, parts = self.active.pop(i)
                value = re.sub(r'\s+', ' ', ' '.join(parts)).strip()
                if value and len(value) <= 200:
                    self.candidates.append(('header', value))
                break

def rate_limit():
    with open(LOCK, 'a+') as f:
        fcntl.flock(f, fcntl.LOCK_EX)
        f.seek(0)
        try: last = float(f.read().strip())
        except ValueError: last = 0
        delay = 0.4 - (time.time() - last)
        if delay > 0: time.sleep(delay)
        f.seek(0); f.truncate(); f.write(str(time.time())); f.flush()
        fcntl.flock(f, fcntl.LOCK_UN)

def inspect(path, expected):
    cleanpath = urldefrag(path)[0]
    if cleanpath.lower().endswith('.pdf'):
        return ('manual_pdf', '', 'PDF needs source or first-page review')
    url = urljoin(BASE, quote(cleanpath, safe='/%?=&:+@'))
    if not url.startswith(BASE): return ('error', '', 'outside archive')
    try:
        rate_limit()
        req = Request(url, headers={'User-Agent':'PraxisAuthorshipAudit/1.0', 'Range':'bytes=0-262143'})
        with urlopen(req, timeout=25) as response:
            if not response.geturl().startswith(BASE): return ('error', '', 'redirect outside archive')
            raw = response.read(262144)
            encoding = response.headers.get_content_charset() or 'utf-8'
        parser = Headers(); parser.feed(raw.decode(encoding, errors='replace'))
        evidence = []
        for kind, text in parser.candidates:
            if kind == 'meta' or re.search(r'\b(?:by|author|written by)\b', text, re.I):
                evidence.append((kind, text))
        if not evidence: return ('manual_no_byline', '', '')
        return ('review_byline', json.dumps(evidence[:8], ensure_ascii=False), '')
    except (HTTPError, URLError, TimeoutError, OSError, ValueError) as error:
        return ('error', '', str(error)[:300])

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument('--db',default='/private/tmp/praxis-en-attribution-audit.sqlite')
    ap.add_argument('--retry-errors',action='store_true')
    ap.add_argument('--limit',type=int,default=0,help='max number of entries to process; zero means all')
    args=ap.parse_args()
    data=json.loads((ROOT/'ios/Praxis/Resources/catalog-en.json').read_text())
    db=sqlite3.connect(args.db)
    db.execute('CREATE TABLE IF NOT EXISTS audit (path TEXT PRIMARY KEY, expected TEXT, status TEXT, evidence TEXT, error TEXT)')
    count=0
    for author in data['authors']:
        for work in author['works']:
            path=work[1]
            row=db.execute('SELECT status FROM audit WHERE path=?',(path,)).fetchone()
            if row and not (args.retry_errors and row[0]=='error'): continue
            expected = work[4] if len(work)>4 else author.get('full', author['name'])
            status,evidence,error=inspect(path,expected)
            db.execute('INSERT OR REPLACE INTO audit VALUES (?,?,?,?,?)',(path,expected,status,evidence,error))
            db.commit(); count+=1
            if count%50==0:
                counts=dict(db.execute('SELECT status, count(*) FROM audit GROUP BY status').fetchall())
                print('processed',count,'total',sum(counts.values()),counts,flush=True)
            if args.limit and count>=args.limit: break
        if args.limit and count>=args.limit: break
    counts=dict(db.execute('SELECT status, count(*) FROM audit GROUP BY status').fetchall())
    print('finished',sum(counts.values()),counts,flush=True)

if __name__ == '__main__': main()

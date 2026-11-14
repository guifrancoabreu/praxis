"""Tests for the rescan's catalog merging and report writing (no network)."""
import json
import sqlite3
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import scan_credits


class ScanCreditsTests(unittest.TestCase):
    def setUp(self):
        self.original = scan_credits.CATALOGS["pt"]

    def tearDown(self):
        scan_credits.CATALOGS["pt"] = self.original

    def test_error_page_detection(self):
        self.assertTrue(scan_credits.looks_like_error_page("<title>Object not found</title>"))
        self.assertTrue(
            scan_credits.looks_like_error_page("<title>Error 404</title><p>not found</p>")
        )
        self.assertFalse(scan_credits.looks_like_error_page("<h1>Um texto</h1>"))

    def test_apply_fills_empty_catalog_credits_only(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            catalog_file = root / "catalog-pt.json"
            catalog_file.write_text(
                json.dumps(
                    {
                        "authors": [
                            {
                                "id": "a",
                                "name": "Archive A",
                                "works": [
                                    ["Explicit", "a.htm", "", 0, "Keep me"],
                                    ["Empty", "b.htm", "", 0],
                                    ["Fragment", "c.htm#page=2", "", 0],
                                    ["Unknown", "d.htm", "", 0],
                                ],
                            }
                        ]
                    }
                ),
                encoding="utf-8",
            )
            credits_file = root / "credits-pt.json"
            credits_file.write_text(
                json.dumps(
                    {
                        "version": 2,
                        "language": "pt",
                        "extractor": scan_credits.credits.EXTRACTOR_VERSION,
                        "credits": {
                            "a.htm": {"credit": "Override"},
                            "b.htm": {"credit": "Source B"},
                            "c.htm": {"credit": "Source C"},
                        },
                    }
                ),
                encoding="utf-8",
            )
            scan_credits.CATALOGS["pt"] = ("https://www.marxists.org/portugues/", catalog_file)

            changed = scan_credits.apply_to_catalog("pt", credits_file)

            works = json.loads(catalog_file.read_text(encoding="utf-8"))["authors"][0]["works"]
            self.assertEqual(changed, 2)
            self.assertEqual(works[0][4], "Keep me")
            self.assertEqual(works[1][4], "Source B")
            self.assertEqual(works[2][4], "Source C")
            self.assertEqual(works[3], ["Unknown", "d.htm", "", 0])

    def test_report_includes_only_credited_paths(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            catalog_file = root / "catalog-pt.json"
            catalog_file.write_text('{"authors":[]}', encoding="utf-8")
            scan_credits.CATALOGS["pt"] = ("https://www.marxists.org/portugues/", catalog_file)
            output = root / "credits-pt.json"

            database = sqlite3.connect(":memory:")
            database.execute(
                "CREATE TABLE scan (path TEXT PRIMARY KEY, status TEXT, credit TEXT, "
                "evidence TEXT, url TEXT, error TEXT, fetched TEXT)"
            )
            database.execute(
                "CREATE TABLE scan_provenance (path TEXT PRIMARY KEY, "
                "extractor TEXT NOT NULL, recorded TEXT)"
            )
            database.executemany(
                "INSERT INTO scan VALUES (?,?,?,?,?,?,?)",
                [
                    ("a.htm", "credited", "Chris Harman", "h2 after h1", "https://example/a", "", "now"),
                    ("b.htm", "no_byline", "", "", "https://example/b", "", "now"),
                    ("c.htm", "error", "", "", "https://example/c", "timeout", "now"),
                    ("d.htm", "credited", "AUTOR", "h2 after h1", "https://example/d", "", "now"),
                ],
            )
            database.executemany(
                "INSERT INTO scan_provenance VALUES (?,?,?)",
                [
                    ("a.htm", str(scan_credits.credits.EXTRACTOR_VERSION), "now"),
                    ("b.htm", str(scan_credits.credits.EXTRACTOR_VERSION), "now"),
                    ("c.htm", str(scan_credits.credits.EXTRACTOR_VERSION), "now"),
                    ("d.htm", str(scan_credits.credits.EXTRACTOR_VERSION), "now"),
                ],
            )

            written = scan_credits.write_credits_file(database, "pt", output)

            payload = json.loads(output.read_text(encoding="utf-8"))
            self.assertEqual(written, 1)
            self.assertEqual(list(payload["credits"]), ["a.htm"])
            self.assertEqual(payload["credits"]["a.htm"]["credit"], "Chris Harman")
            self.assertEqual(payload["language"], "pt")


if __name__ == "__main__":
    unittest.main()

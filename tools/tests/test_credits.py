"""Tests for explicit source-credit extraction (no network access)."""
import contextlib
import io
import json
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))

import credits


def page(body):
    return "<!doctype html><html><head></head><body>%s</body></html>" % body


class ExtractCreditTests(unittest.TestCase):
    def test_portuguese_standard_byline(self):
        html = page("<h1>A Que Herança Renunciamos?</h1><h2>V. I. Lénine</h2><h3>1897</h3><p>...</p>")
        self.assertEqual(
            credits.extract_credit(html),
            {"credit": "V. I. Lénine", "evidence": "h2 after h1"},
        )

    def test_portuguese_chapter_byline(self):
        html = page("<h3>A Que Herança Renunciamos?</h3><h4>V. I. Lénine</h4><hr>")
        self.assertEqual(credits.extract_credit(html)["credit"], "V. I. Lénine")

    def test_english_byline_before_title(self):
        html = page("<h2>Chris Harman</h2><h1>Cuba behind the myths</h1><h3>(Summer 2006)</h3>")
        self.assertEqual(
            credits.extract_credit(html),
            {"credit": "Chris Harman", "evidence": "h2 before h1"},
        )

    def test_section_label_before_title_is_skipped(self):
        html = page("<h2>Philip Coben</h2><h4>Books in Review</h4><h1>Their Morals and Ours</h1>")
        self.assertEqual(credits.extract_credit(html)["credit"], "Philip Coben")

    def test_visible_byline_beats_stale_meta(self):
        # The archive's meta tag says Vygotsky, but the page's visible header is
        # El'konin. The visible source byline is the evidence.
        html = page(
            '<meta name="Author" content="Lev Vygotsky">'
            '<p class="title">D.B. El\'konin </p>'
            "<h3>Toward The Problem of Stages</h3>"
        )
        self.assertEqual(credits.extract_credit(html)["credit"], "D.B. El'konin")

    def test_header_block_with_trailing_year(self):
        html = page('<p class="title">Dora B. Montefiore 1909</p><h3>Justice Articles</h3>')
        self.assertEqual(credits.extract_credit(html)["credit"], "Dora B. Montefiore")

    def test_archive_header_does_not_corroborate_meta(self):
        # "Nestor Makhno Archive" is navigation, not a byline.
        html = page(
            '<meta name="author" content="Nestor Makhno">'
            '<p class="title">Nestor Makhno Archive</p>'
            "<h3>The Russian Revolution in Ukraine</h3>"
        )
        self.assertIsNone(credits.extract_credit(html))

    def test_complete_visible_byline_corroborates_meta(self):
        html = page(
            '<meta name="author" content="Nestor Makhno">'
            "<h1>The Russian Revolution in Ukraine</h1>"
            "<h3>Nestor Makhno</h3>"
        )
        self.assertEqual(
            credits.extract_credit(html),
            {"credit": "Nestor Makhno", "evidence": "corroborated meta author"},
        )

    def test_uncorroborated_meta_is_not_used(self):
        html = page(
            '<meta name="author" content="Lev Vygotsky">'
            "<h1>On the problem of stages</h1><h3>1971</h3>"
        )
        self.assertIsNone(credits.extract_credit(html))

    def test_surname_in_title_does_not_corroborate_meta(self):
        html = page(
            '<meta name="author" content="Lev Vygotsky">'
            "<h1>Vygotsky and education</h1><h3>1971</h3>"
        )
        self.assertIsNone(credits.extract_credit(html))

    def test_no_byline_stays_uncredited(self):
        html = page("<h1>A Revolução Russa</h1><h3>1905</h3><p>Texto anônimo.</p>")
        self.assertIsNone(credits.extract_credit(html))

    def test_subtitle_is_not_a_byline(self):
        html = page("<h1>Que Fazer?</h1><h2>A Revolução Russa</h2><h3>1902</h3>")
        self.assertIsNone(credits.extract_credit(html))

    def test_title_like_subtitle_with_year_is_not_a_byline(self):
        html = page("<h1>Textos escolhidos</h1><h2>História da Rússia 1905</h2>")
        self.assertIsNone(credits.extract_credit(html))

    def test_byline_label_is_removed(self):
        html = page("<h2>By Chris Harman</h2><h1>Cuba behind the myths</h1>")
        self.assertEqual(credits.extract_credit(html)["credit"], "Chris Harman")

    def test_section_labels_are_not_bylines(self):
        for body in (
            "<h1>Textos</h1><h2>Biografia</h2>",
            "<h1>Textos</h1><h2>Book Reviews</h2>",
            "<h2>Book Review</h2><h1>Their Morals and Ours</h1>",
        ):
            with self.subTest(body=body):
                self.assertIsNone(credits.extract_credit(page(body)))

    def test_book_header_before_unnamed_preface_is_not_a_byline(self):
        # "O Capital" is the book; the page is an unsigned preface by Engels.
        # Crediting the book's author from the header would be a guess.
        html = page(
            "<h3>O Capital <span>Crítica da Economia Política</span></h3>"
            "<h4>Karl Marx</h4>"
            '<p class="titulo-capitulo">Prefácio à edição inglesa</p>'
            "<p>Texto do prefácio.</p>"
        )
        self.assertIsNone(credits.extract_credit(html))

    def test_unclassed_preface_after_book_header_is_not_a_byline(self):
        html = page(
            "<h3>O Capital</h3><h4>Karl Marx</h4>"
            "<h5>Prefácio à edição inglesa</h5><p>Texto do prefácio.</p>"
        )
        self.assertIsNone(credits.extract_credit(html))

    def test_chapter_heading_after_header_keeps_byline(self):
        html = page(
            "<h3>A Que Herança Renunciamos?</h3>"
            "<h4>V. I. Lénine</h4>"
            '<h4 class="titulo-capitulo">II - Os Acrescentos do Populismo</h4>'
        )
        self.assertEqual(credits.extract_credit(html)["credit"], "V. I. Lénine")

    def test_broken_initial_spacing_is_repaired(self):
        html = page("<h1>Reunião</h1><h2>V. I. L énine</h2><h3>1917</h3>")
        self.assertEqual(credits.extract_credit(html)["credit"], "V. I. Lénine")


class ApplyCreditMapTests(unittest.TestCase):
    def test_only_empty_credits_are_filled(self):
        rows = [
            ["Existing", "a.htm", "", 0, "Index credit"],
            ["Missing", "b.htm", "", 0],
            ["Legacy", "c.htm", "", 0],
            ["Fragment", "d.htm#part", "", 0],
        ]
        credits.apply_credit_map(
            rows,
            {"a.htm": "Source credit", "b.htm": "Source B", "d.htm": "Source D"},
        )
        self.assertEqual(rows[0][4], "Index credit")
        self.assertEqual(rows[1][4], "Source B")
        self.assertEqual(rows[2], ["Legacy", "c.htm", "", 0])
        self.assertEqual(rows[3][4], "Source D")

    def test_missing_data_file_is_empty(self):
        self.assertEqual(credits.load_credit_map("/definitely/not/here.json"), {})

    def test_short_rows_keep_fields_aligned(self):
        rows = [["Short", "e.htm", "1900"], ["Tiny", "f.htm"]]
        credits.apply_credit_map(rows, {"e.htm": "Source E", "f.htm": "Source F"})
        self.assertEqual(rows[0], ["Short", "e.htm", "1900"])
        self.assertEqual(rows[1], ["Tiny", "f.htm"])

    def test_non_string_credits_are_ignored(self):
        rows = [["Work", "a.htm", "", 0]]
        credits.apply_credit_map(rows, {"a.htm": 7})
        self.assertEqual(rows[0], ["Work", "a.htm", "", 0])

    def test_placeholder_credit_is_rejected(self):
        rows = [["Work", "a.htm", "", 0]]
        credits.apply_credit_map(rows, {"a.htm": "AUTOR"})
        self.assertEqual(rows[0], ["Work", "a.htm", "", 0])

    def test_descriptor_prefix_is_removed(self):
        rows = [["Work", "a.htm", "", 0]]
        credits.apply_credit_map(rows, {"a.htm": "Dissertação de Jussara Valéria de Miranda"})
        self.assertEqual(rows[0][4], "Jussara Valéria de Miranda")

    def _load_credit_file(self, payload, **kwargs):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "credits.json"
            path.write_text(json.dumps(payload, ensure_ascii=False), encoding="utf-8")
            with contextlib.redirect_stderr(io.StringIO()):
                return credits.load_credit_map(str(path), **kwargs)

    def test_current_credit_file_is_loaded(self):
        payload = {
            "version": 2,
            "language": "pt",
            "extractor": credits.EXTRACTOR_VERSION,
            "credits": {
                "a.htm": {"credit": "Chris Harman"},
                "b.htm": "Dora B. Montefiore",
            },
        }
        self.assertEqual(
            self._load_credit_file(payload, expected_language="pt"),
            {"a.htm": "Chris Harman", "b.htm": "Dora B. Montefiore"},
        )

    def test_stale_or_unstamped_credit_file_is_rejected(self):
        payload = {
            "version": 1,
            "language": "pt",
            "credits": {"a.htm": {"credit": "Chris Harman"}},
        }
        self.assertEqual(
            self._load_credit_file(payload, expected_language="pt"),
            {},
        )

    def test_wrong_language_or_extractor_is_rejected(self):
        payload = {
            "version": 2,
            "language": "en",
            "extractor": credits.EXTRACTOR_VERSION + 1,
            "credits": {"a.htm": {"credit": "Chris Harman"}},
        }
        self.assertEqual(
            self._load_credit_file(payload, expected_language="pt"),
            {},
        )

    def test_malformed_credit_values_are_skipped(self):
        payload = {
            "version": 2,
            "language": "pt",
            "extractor": credits.EXTRACTOR_VERSION,
            "credits": {
                "a.htm": {"credit": 7},
                "b.htm": ["Chris Harman"],
                "c.htm": {"credit": "   "},
                "d.htm": "Dora B. Montefiore",
                "e.htm": "AUTOR",
                "f.htm": "Dissertação de Jussara Valéria de Miranda",
            },
        }
        self.assertEqual(
            self._load_credit_file(payload, expected_language="pt"),
            {"d.htm": "Dora B. Montefiore", "f.htm": "Jussara Valéria de Miranda"},
        )


if __name__ == "__main__":
    unittest.main()

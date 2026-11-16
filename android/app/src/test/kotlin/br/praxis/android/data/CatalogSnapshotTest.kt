package br.praxis.android.data

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File

/**
 * Parses the catalog snapshot the app actually ships. The numbers here are the same ones the iOS
 * tests assert, so a regression on either platform shows up as a failing count.
 */
class CatalogSnapshotTest {
    private fun shared(name: String): File {
        // JVM tests run with android/app as the working directory.
        val file = File("../../shared/catalog/$name")
        assertTrue("missing ${file.path}", file.isFile)
        return file
    }

    @Test
    fun `portuguese snapshot decodes with every author and work`() {
        val catalog = Catalog.parse(shared("catalog-pt.json").readText(), Language.pt)
        assertEquals(510 + 1, catalog.authors.size) // Marx and Engels are split into two entries
        // 17 works carry a shared Marx/Engels credit and therefore appear under both authors,
        // exactly as the iOS parser counts them.
        assertEquals(7500, catalog.authors.sumOf { it.works.size })
        assertEquals(21, catalog.themes.size)
        assertEquals(4125, catalog.figures.size)
        assertEquals("2026-11-09", catalog.generated)
    }

    @Test
    fun `marx and engels are separated by credit`() {
        val catalog = Catalog.parse(shared("catalog-pt.json").readText(), Language.pt)
        val marx = catalog.authors.first { it.id == "marx" }
        val engels = catalog.authors.first { it.id == "engels" }
        assertEquals("Karl Marx", marx.full)
        assertEquals("Friedrich Engels", engels.full)
        assertTrue(engels.works.isNotEmpty())
        assertTrue(engels.works.all { it.credit == "Friedrich Engels" || it.credit == "Karl Marx e Friedrich Engels" })
    }

    @Test
    fun `english snapshot carries history collections`() {
        val catalog = Catalog.parse(shared("catalog-en.json").readText(), Language.en)
        assertEquals(645, catalog.authors.size)
        assertEquals(69, catalog.themes.size)
        assertEquals(32, catalog.history.size)
    }

    @Test
    fun `portrait urls follow the archive photo priority`() {
        val catalog = Catalog.parse(shared("catalog-pt.json").readText(), Language.pt)
        val lenin = catalog.authors.first { it.id == "lenin" }
        val url = Portraits.url(lenin, Language.pt)
        assertTrue("expected an archive portrait", url != null && url.startsWith("https://www.marxists.org/portugues/"))
    }
}

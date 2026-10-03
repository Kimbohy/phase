package com.kimbohy.phase

import org.json.JSONObject
import org.junit.Assert.assertEquals
import org.junit.Test
import java.io.File
import java.time.LocalDateTime

class WidgetEngineTest {

    private fun JSONObject.str(key: String): String? = if (isNull(key)) null else getString(key)

    @Test
    fun sharedVectors() {
        // Le répertoire courant des tests est android/app : on remonte à test/.
        val data = JSONObject(File("../../test/test_vectors.json").readText(Charsets.UTF_8))
        val plannings = data.getJSONObject("plannings")
        val cases = data.getJSONArray("cases")

        for (i in 0 until cases.length()) {
            val c = cases.getJSONObject(i)
            val label = c.getString("name")
            val state = WidgetEngine.compute(
                plannings.getJSONObject(c.getString("planning")).toString(),
                LocalDateTime.parse(c.getString("now")),
            )
            val expected = c.getJSONObject("expected")

            assertEquals(label, expected.getString("kind"), state.kind)
            assertEquals(label, expected.str("title"), state.title)
            assertEquals(label, expected.str("sub"), state.sub?.testLabel)
            assertEquals(label, expected.str("next"), state.nextTitle)
        }
    }
}
package com.huaweiappfactory.receiptlens.util

import java.text.DateFormat
import java.text.SimpleDateFormat
import java.util.Calendar
import java.util.Date
import java.util.Locale
import java.util.regex.Pattern

object DateUtils {

    fun formatDate(timestamp: Long, locale: Locale = Locale.getDefault()): String {
        val date = Date(timestamp)
        val format = DateFormat.getDateInstance(DateFormat.MEDIUM, locale)
        return format.format(date)
    }

    fun formatDateTime(timestamp: Long, locale: Locale = Locale.getDefault()): String {
        val date = Date(timestamp)
        val format = DateFormat.getDateTimeInstance(DateFormat.MEDIUM, DateFormat.SHORT, locale)
        return format.format(date)
    }

    fun formatIsoDate(timestamp: Long): String {
        val sdf = SimpleDateFormat("yyyy-MM-dd", Locale.US)
        return sdf.format(Date(timestamp))
    }

    fun isSameMonthAndYear(t1: Long, t2: Long): Boolean {
        val c1 = Calendar.getInstance().apply { timeInMillis = t1 }
        val c2 = Calendar.getInstance().apply { timeInMillis = t2 }
        return c1.get(Calendar.YEAR) == c2.get(Calendar.YEAR) &&
                c1.get(Calendar.MONTH) == c2.get(Calendar.MONTH)
    }

    fun formatMonthYear(timestamp: Long, locale: Locale = Locale.getDefault()): String {
        val sdf = SimpleDateFormat("MMM yyyy", locale)
        return sdf.format(Date(timestamp))
    }

    /**
     * Parses a date found in receipt text using deterministic heuristic regex patterns.
     * Returns timestamp in milliseconds, or null if no valid date could be identified.
     */
    fun parseReceiptDate(text: String): Long? {
        val now = System.currentTimeMillis()
        val calendar = Calendar.getInstance()

        // 1. Standard ISO: 2026-09-04 or 2026/09/04
        val isoPattern = Pattern.compile("\\b(20[1-3][0-9])[-/.](0[1-9]|1[0-2])[-/.](0[1-9]|[12][0-9]|3[01])\\b")
        val isoMatcher = isoPattern.matcher(text)
        if (isoMatcher.find()) {
            val y = isoMatcher.group(1)?.toIntOrNull() ?: return null
            val m = (isoMatcher.group(2)?.toIntOrNull() ?: return null) - 1
            val d = isoMatcher.group(3)?.toIntOrNull() ?: return null
            calendar.set(y, m, d, 12, 0, 0)
            val time = calendar.timeInMillis
            if (time <= now + 86400000L && time >= now - (365L * 5 * 86400000L)) {
                return time
            }
        }

        // 2. Day-Month-Year: 04/09/2026 or 04.09.2026 or 04-09-2026
        val dmyPattern = Pattern.compile("\\b(0[1-9]|[12][0-9]|3[01])[-/.](0[1-9]|1[0-2])[-/.](20[1-3][0-9])\\b")
        val dmyMatcher = dmyPattern.matcher(text)
        if (dmyMatcher.find()) {
            val d = dmyMatcher.group(1)?.toIntOrNull() ?: return null
            val m = (dmyMatcher.group(2)?.toIntOrNull() ?: return null) - 1
            val y = dmyMatcher.group(3)?.toIntOrNull() ?: return null
            calendar.set(y, m, d, 12, 0, 0)
            val time = calendar.timeInMillis
            if (time <= now + 86400000L && time >= now - (365L * 5 * 86400000L)) {
                return time
            }
        }

        // 3. Month-Day-Year: 09/04/2026
        val mdyPattern = Pattern.compile("\\b(0[1-9]|1[0-2])[-/.](0[1-9]|[12][0-9]|3[01])[-/.](20[1-3][0-9])\\b")
        val mdyMatcher = mdyPattern.matcher(text)
        if (mdyMatcher.find()) {
            val m = (mdyMatcher.group(1)?.toIntOrNull() ?: return null) - 1
            val d = mdyMatcher.group(2)?.toIntOrNull() ?: return null
            val y = mdyMatcher.group(3)?.toIntOrNull() ?: return null
            calendar.set(y, m, d, 12, 0, 0)
            val time = calendar.timeInMillis
            if (time <= now + 86400000L && time >= now - (365L * 5 * 86400000L)) {
                return time
            }
        }

        // 4. Word-based date: e.g. "04 Sep 2026", "Sep 04 2026"
        val wordFormats = listOf(
            "dd MMM yyyy", "MMM dd yyyy", "dd-MMM-yyyy", "dd/MMM/yyyy", "MMM dd, yyyy"
        )
        for (pattern in wordFormats) {
            try {
                val sdf = SimpleDateFormat(pattern, Locale.ENGLISH)
                sdf.isLenient = false
                val wordRegex = Pattern.compile("[0-9]{1,2}[ -/][A-Za-z]{3,9}[ -/][0-9]{4}")
                val m = wordRegex.matcher(text)
                if (m.find()) {
                    val parsed = sdf.parse(m.group(0) ?: "")
                    if (parsed != null && parsed.time <= now + 86400000L) {
                        return parsed.time
                    }
                }
            } catch (_: Exception) {
            }
        }

        return null
    }
}

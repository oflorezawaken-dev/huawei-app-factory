package com.huaweiappfactory.receiptlens.ml

import com.huaweiappfactory.receiptlens.domain.model.ReceiptCategory
import com.huaweiappfactory.receiptlens.util.CurrencyUtils
import com.huaweiappfactory.receiptlens.util.DateUtils
import java.util.regex.Pattern

data class ParsedReceipt(
    val merchantName: String?,
    val transactionDate: Long?,
    val totalAmount: Long?, // Minor units (e.g. cents)
    val taxAmount: Long?, // Minor units (e.g. cents)
    val currency: String,
    val category: String,
    val rawText: String,
    val isConfidenceLow: Boolean
)

object ReceiptParser {

    private val TOTAL_HIGH_PRIORITY_KEYWORDS = listOf(
        "GRAND TOTAL", "AMOUNT DUE", "BALANCE DUE", "TOTAL DUE", "TOTAL AMOUNT",
        "IMPORTE TOTAL", "TOTAL GENERAL", "NET A PAYER", "TOTAL TTC", "ENDSUMME",
        "GESAMTBETRAG", "IMPORTO TOTALE", "GENEL TOPLAM", "ODENECEK TUTAR",
        "المبلغ المستحق", "الإجمالي النهائي", "应付金额", "实付金额", "合计"
    )

    private val TOTAL_STANDARD_KEYWORDS = listOf(
        "TOTAL", "SOMME", "SUMME", "GESAMT", "TOTALE", "TOPLAM", "VALOR TOTAL",
        "المجموع", "الإجمالي", "总额", "总计"
    )

    private val SUBTOTAL_KEYWORDS = listOf(
        "SUBTOTAL", "SUB TOTAL", "SUB-TOTAL", "SOUS-TOTAL", "ZWISCHENSUMME",
        "SUBTOTAL GENERAL", "NET", "BASE IMPONIBLE", "ARA TOPLAM"
    )

    private val TAX_KEYWORDS = listOf(
        "TAX", "VAT", "IVA", "TVA", "MWST", "GST", "IMPUESTO", "KDV", "TAX AMOUNT",
        "SALES TAX", "IMPUESTOS", "STEUER", "الضريبة", "税", "税额"
    )

    private val DISCOUNT_KEYWORDS = listOf(
        "DISCOUNT", "SAVINGS", "RABATT", "DESCUENTO", "REMISE", "INDİRİM",
        "AHORRO", "خصم", "折扣", "优惠"
    )

    private val PRICE_PATTERN = Pattern.compile("([0-9]{1,4}(?:[.,][0-9]{2,3})*(?:[.,][0-9]{2}))")

    fun parse(rawText: String, defaultCurrency: String = "USD"): ParsedReceipt {
        if (rawText.isBlank()) {
            return ParsedReceipt(
                merchantName = null,
                transactionDate = System.currentTimeMillis(),
                totalAmount = null,
                taxAmount = null,
                currency = defaultCurrency,
                category = ReceiptCategory.OTHER.id,
                rawText = "",
                isConfidenceLow = true
            )
        }

        val lines = rawText.lines()
            .map { it.trim() }
            .filter { it.isNotBlank() }

        val detectedCurrency = CurrencyUtils.detectCurrency(rawText, defaultCurrency)
        val detectedDate = DateUtils.parseReceiptDate(rawText) ?: System.currentTimeMillis()

        // Merchant extraction
        val detectedMerchant = extractMerchantName(lines)

        // Total & Tax extraction
        val (detectedTotal, detectedTax, totalConfidence) = extractFinancialAmounts(lines, detectedCurrency)

        // Category suggestion
        val detectedCategory = suggestCategory(detectedMerchant, lines)

        val isLowConfidence = detectedMerchant == null || detectedTotal == null || !totalConfidence

        return ParsedReceipt(
            merchantName = detectedMerchant,
            transactionDate = detectedDate,
            totalAmount = detectedTotal,
            taxAmount = detectedTax,
            currency = detectedCurrency,
            category = detectedCategory.id,
            rawText = rawText,
            isConfidenceLow = isLowConfidence
        )
    }

    private fun extractMerchantName(lines: List<String>): String? {
        val noisePatterns = listOf(
            "\\b(?:RECEIPT|TICKET|FACTURA|INVOICE|QUITTUNG|BON|RECIBO)\\b",
            "\\b(?:TEL|PHONE|FAX|MOBILE)\\b",
            "\\b(?:HTTP|HTTPS|WWW|\\.COM|\\.ES|\\.FR|\\.DE|\\.NET|\\.ORG)\\b",
            "\\b(?:VAT|CIF|NIF|RFC|TAX ID|REG|UID|ID NO)\\b",
            "\\b(?:WELCOME|THANK YOU|GRACIAS|MERCI|DANKE|GRAZIE|TEŞEKKÜRLER)\\b",
            "\\b(?:CASHIER|REGISTER|SERVER|CLERK|TABLE)\\b"
        ).map { Pattern.compile(it, Pattern.CASE_INSENSITIVE) }

        // Check first 5 lines
        val candidateLines = lines.take(5)
        for (line in candidateLines) {
            val upper = line.uppercase()

            // Skip lines that look purely like dates or times
            if (line.matches(".*\\b\\d{1,2}[:/.-]\\d{1,2}(?:[:/.-]\\d{2,4})?\\b.*".toRegex())) {
                continue
            }

            // Skip if matches noise patterns
            if (noisePatterns.any { it.matcher(upper).find() }) {
                continue
            }

            // Must have at least 2 alphanumeric characters
            val letterCount = line.count { it.isLetter() }
            if (letterCount >= 3) {
                // Clean up merchant name candidate
                val cleaned = line.replace("[#*~_|=]+".toRegex(), "").trim()
                if (cleaned.length in 3..40) {
                    return cleaned
                }
            }
        }
        return null
    }

    private data class AmountsResult(
        val total: Long?,
        val tax: Long?,
        val hasConfidentTotal: Boolean
    )

    private fun extractFinancialAmounts(
        lines: List<String>,
        currencyCode: String
    ): AmountsResult {
        var highPriorityTotal: Long? = null
        var standardTotal: Long? = null
        var fallbackMaxAmount: Long? = null
        var extractedTax: Long? = null

        for (line in lines) {
            val upper = line.uppercase()
            val matcher = PRICE_PATTERN.matcher(line)
            val lineAmounts = mutableListOf<Long>()

            while (matcher.find()) {
                val matchStr = matcher.group(1) ?: continue
                val parsed = CurrencyUtils.parseAmountToMinorUnits(matchStr, currencyCode)
                if (parsed != null && parsed > 0 && parsed < 100_000_000L) { // sanity bound < 1M currency units
                    lineAmounts.add(parsed)
                }
            }

            if (lineAmounts.isEmpty()) continue

            // The last amount on a labeled line is typically the line item's final figure
            val candidateAmount = lineAmounts.last()

            // 1. Check for Tax keywords
            if (TAX_KEYWORDS.any { upper.contains(it) } && !upper.contains("TOTAL")) {
                if (extractedTax == null || candidateAmount < (highPriorityTotal ?: standardTotal ?: Long.MAX_VALUE)) {
                    extractedTax = candidateAmount
                }
                continue
            }

            // 2. Check for Discount keywords - ignore for total
            if (DISCOUNT_KEYWORDS.any { upper.contains(it) }) {
                continue
            }

            // 3. Check for Subtotal keywords - ignore for total
            if (SUBTOTAL_KEYWORDS.any { upper.contains(it) }) {
                continue
            }

            // 4. High-priority Total keywords
            if (TOTAL_HIGH_PRIORITY_KEYWORDS.any { upper.contains(it) }) {
                highPriorityTotal = candidateAmount
                continue
            }

            // 5. Standard Total keywords
            if (TOTAL_STANDARD_KEYWORDS.any { upper.contains(it) }) {
                standardTotal = candidateAmount
                continue
            }

            // Track largest candidate in bottom lines as fallback
            if (candidateAmount > (fallbackMaxAmount ?: 0L)) {
                fallbackMaxAmount = candidateAmount
            }
        }

        return when {
            highPriorityTotal != null -> AmountsResult(
                total = highPriorityTotal,
                tax = extractedTax,
                hasConfidentTotal = true
            )
            standardTotal != null -> AmountsResult(
                total = standardTotal,
                tax = extractedTax,
                hasConfidentTotal = true
            )
            fallbackMaxAmount != null -> AmountsResult(
                total = fallbackMaxAmount,
                tax = extractedTax,
                hasConfidentTotal = false
            )
            else -> AmountsResult(
                total = null,
                tax = extractedTax,
                hasConfidentTotal = false
            )
        }
    }

    private fun suggestCategory(merchant: String?, lines: List<String>): ReceiptCategory {
        val fullText = ((merchant ?: "") + " " + lines.joinToString(" ")).lowercase()

        // Grocery keywords
        val groceryKeywords = listOf(
            "grocery", "supermarket", "market", "walmart", "carrefour", "mercadona",
            "aldi", "lidl", "kroger", "target", "whole foods", "trader joe", "bakery",
            "panaderia", "boulangerie", "bäckerei", "produce", "meat", "dairy"
        )
        if (groceryKeywords.any { fullText.contains(it) }) return ReceiptCategory.GROCERIES

        // Food & Dining keywords
        val foodKeywords = listOf(
            "restaurant", "cafe", "coffee", "pizza", "burger", "starbucks", "mcdonald",
            "subway", "diner", "sushi", "bistro", "bar", "grill", "taco", "kebab",
            "kitchen", "eatery", "food", "dining", "steakhouse", "tapas"
        )
        if (foodKeywords.any { fullText.contains(it) }) return ReceiptCategory.FOOD

        // Transport keywords
        val transportKeywords = listOf(
            "uber", "lyft", "taxi", "cab", "gas", "fuel", "petrol", "shell", "bp",
            "chevron", "exxon", "totalenergies", "subway", "metro", "parking", "transit",
            "train", "bus", "rail", "toll", "station"
        )
        if (transportKeywords.any { fullText.contains(it) }) return ReceiptCategory.TRANSPORT

        // Health & Wellness keywords
        val healthKeywords = listOf(
            "pharmacy", "chemist", "drugstore", "cvs", "walgreens", "boots", "apotheke",
            "hospital", "clinic", "dental", "doctor", "optician", "health", "care", "wellness"
        )
        if (healthKeywords.any { fullText.contains(it) }) return ReceiptCategory.HEALTH

        // Bills & Utilities keywords
        val billsKeywords = listOf(
            "electric", "water", "power", "utility", "telecom", "internet", "verizon",
            "at&t", "orange", "vodafone", "o2", "rent", "insurance", "cable", "bill", "energy"
        )
        if (billsKeywords.any { fullText.contains(it) }) return ReceiptCategory.BILLS

        // Entertainment keywords
        val entertainmentKeywords = listOf(
            "cinema", "theatre", "movie", "bowling", "game", "ticket", "museum",
            "concert", "stadium", "amusement", "theatre", "park", "show"
        )
        if (entertainmentKeywords.any { fullText.contains(it) }) return ReceiptCategory.ENTERTAINMENT

        // Travel keywords
        val travelKeywords = listOf(
            "hotel", "motel", "airbnb", "hostel", "flight", "airline", "airport",
            "resort", "lodging", "ryanair", "lufthansa", "emirates", "travel"
        )
        if (travelKeywords.any { fullText.contains(it) }) return ReceiptCategory.TRAVEL

        // Work & Office keywords
        val workKeywords = listOf(
            "office", "supplies", "staples", "depot", "printing", "software",
            "hardware", "coworking", "business"
        )
        if (workKeywords.any { fullText.contains(it) }) return ReceiptCategory.WORK

        // Shopping keywords
        val shoppingKeywords = listOf(
            "clothing", "apparel", "shoes", "zara", "h&m", "uniqlo", "boutique",
            "fashion", "department store", "amazon", "electronics", "mall", "store", "shop"
        )
        if (shoppingKeywords.any { fullText.contains(it) }) return ReceiptCategory.SHOPPING

        return ReceiptCategory.OTHER
    }
}

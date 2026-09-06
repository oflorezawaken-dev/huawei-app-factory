package com.huaweiappfactory.receiptlens.ui.screens

import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ReceiptLong
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.Clear
import androidx.compose.material.icons.filled.FilterList
import androidx.compose.material.icons.filled.Search
import androidx.compose.material.icons.filled.SearchOff
import androidx.compose.material3.Button
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.FilterChipDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.huaweiappfactory.receiptlens.R
import com.huaweiappfactory.receiptlens.ads.AdPlacement
import com.huaweiappfactory.receiptlens.ads.PetalBanner
import androidx.compose.foundation.layout.fillMaxWidth
import com.huaweiappfactory.receiptlens.domain.model.ReceiptCategory
import com.huaweiappfactory.receiptlens.ui.components.EmptyStateView
import com.huaweiappfactory.receiptlens.ui.components.ReceiptCard

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HistoryScreen(
    viewModel: HistoryViewModel,
    onNavigateToDetail: (Long) -> Unit,
    onNavigateToScan: () -> Unit,
    modifier: Modifier = Modifier
) {
    val uiState by viewModel.uiState.collectAsState()
    var sortMenuExpanded by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = stringResource(R.string.history_title),
                        style = MaterialTheme.typography.titleLarge,
                        fontWeight = FontWeight.Bold
                    )
                },
                actions = {
                    IconButton(
                        onClick = { sortMenuExpanded = true },
                        modifier = Modifier.testTag("button_sort_receipts")
                    ) {
                        Icon(imageVector = Icons.Default.FilterList, contentDescription = "Sort Options")
                    }
                    DropdownMenu(
                        expanded = sortMenuExpanded,
                        onDismissRequest = { sortMenuExpanded = false }
                    ) {
                        DropdownMenuItem(
                            text = { Text(stringResource(R.string.filter_sort_newest)) },
                            onClick = {
                                viewModel.onSortChange("NEWEST")
                                sortMenuExpanded = false
                            }
                        )
                        DropdownMenuItem(
                            text = { Text(stringResource(R.string.filter_sort_oldest)) },
                            onClick = {
                                viewModel.onSortChange("OLDEST")
                                sortMenuExpanded = false
                            }
                        )
                        DropdownMenuItem(
                            text = { Text(stringResource(R.string.filter_sort_highest)) },
                            onClick = {
                                viewModel.onSortChange("HIGHEST")
                                sortMenuExpanded = false
                            }
                        )
                        DropdownMenuItem(
                            text = { Text(stringResource(R.string.filter_sort_lowest)) },
                            onClick = {
                                viewModel.onSortChange("LOWEST")
                                sortMenuExpanded = false
                            }
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background
                )
            )
        },
        modifier = modifier
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
        ) {
            // Search Input Field
            OutlinedTextField(
                value = uiState.searchQuery,
                onValueChange = { viewModel.onSearchQueryChange(it) },
                placeholder = { Text(stringResource(R.string.search_hint)) },
                leadingIcon = {
                    Icon(imageVector = Icons.Default.Search, contentDescription = null)
                },
                trailingIcon = {
                    if (uiState.searchQuery.isNotEmpty()) {
                        IconButton(onClick = { viewModel.onSearchQueryChange("") }) {
                            Icon(imageVector = Icons.Default.Clear, contentDescription = "Clear search")
                        }
                    }
                },
                singleLine = true,
                shape = RoundedCornerShape(16.dp),
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 16.dp, vertical = 6.dp)
                    .testTag("input_history_search")
            )

            // Category Filter Chips
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .horizontalScroll(rememberScrollState())
                    .padding(horizontal = 16.dp, vertical = 4.dp),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                FilterChip(
                    selected = uiState.selectedCategory == "ALL",
                    onClick = { viewModel.onCategorySelect("ALL") },
                    label = { Text(stringResource(R.string.filter_all_categories)) },
                    colors = FilterChipDefaults.filterChipColors(
                        selectedContainerColor = MaterialTheme.colorScheme.primaryContainer,
                        selectedLabelColor = MaterialTheme.colorScheme.onPrimaryContainer
                    ),
                    modifier = Modifier.testTag("filter_category_all")
                )
                ReceiptCategory.entries.forEach { cat ->
                    val isSelected = uiState.selectedCategory.equals(cat.id, ignoreCase = true)
                    FilterChip(
                        selected = isSelected,
                        onClick = { viewModel.onCategorySelect(cat.id) },
                        label = { Text(stringResource(cat.titleRes)) },
                        colors = FilterChipDefaults.filterChipColors(
                            selectedContainerColor = MaterialTheme.colorScheme.primaryContainer,
                            selectedLabelColor = MaterialTheme.colorScheme.onPrimaryContainer
                        ),
                        modifier = Modifier.testTag("filter_category_${cat.id.lowercase()}")
                    )
                }
            }

            // Currency Filter Chips (if more than 1 currency exists in db)
            if (uiState.availableCurrencies.size > 1) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .horizontalScroll(rememberScrollState())
                        .padding(horizontal = 16.dp, vertical = 2.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = stringResource(R.string.field_currency) + ":",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    FilterChip(
                        selected = uiState.selectedCurrency == "ALL",
                        onClick = { viewModel.onCurrencySelect("ALL") },
                        label = { Text(stringResource(R.string.filter_all_currencies)) },
                        modifier = Modifier.testTag("filter_currency_all")
                    )
                    uiState.availableCurrencies.forEach { curr ->
                        FilterChip(
                            selected = uiState.selectedCurrency.equals(curr, ignoreCase = true),
                            onClick = { viewModel.onCurrencySelect(curr) },
                            label = { Text(curr) },
                            modifier = Modifier.testTag("filter_currency_$curr")
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(6.dp))

            // Receipts List or Empty States
            if (uiState.receipts.isEmpty()) {
                val isFiltering = uiState.searchQuery.isNotBlank() ||
                        uiState.selectedCategory != "ALL" ||
                        uiState.selectedCurrency != "ALL"

                if (isFiltering) {
                    EmptyStateView(
                        icon = Icons.Default.SearchOff,
                        title = stringResource(R.string.history_empty_search),
                        description = stringResource(R.string.clear_filters),
                        actionButton = {
                            OutlinedButton(
                                onClick = { viewModel.clearFilters() },
                                modifier = Modifier.testTag("button_clear_filters")
                            ) {
                                Text(stringResource(R.string.clear_filters))
                            }
                        },
                        modifier = Modifier.fillMaxSize()
                    )
                } else {
                    EmptyStateView(
                        icon = Icons.AutoMirrored.Filled.ReceiptLong,
                        title = stringResource(R.string.home_empty_title),
                        description = stringResource(R.string.history_empty_all),
                        actionButton = {
                            Button(
                                onClick = onNavigateToScan,
                                modifier = Modifier.testTag("button_history_scan_empty")
                            ) {
                                Icon(imageVector = Icons.Default.CameraAlt, contentDescription = null)
                                Spacer(modifier = Modifier.width(8.dp))
                                Text(stringResource(R.string.home_scan_receipt))
                            }
                        },
                        modifier = Modifier.fillMaxWidth().weight(1f)
                    )
                }
            } else {
                LazyColumn(
                    modifier = Modifier
                        .fillMaxWidth()
                        .weight(1f)
                        .testTag("history_receipts_list"),
                    contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
                    verticalArrangement = Arrangement.spacedBy(12.dp)
                ) {
                    items(uiState.receipts, key = { it.id }) { receipt ->
                        ReceiptCard(
                            receipt = receipt,
                            onClick = { onNavigateToDetail(receipt.id) }
                        )
                    }
                }
            }
            PetalBanner(placement = AdPlacement.HISTORY_BOTTOM_BANNER)
        }
    }
}

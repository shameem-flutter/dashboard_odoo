import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/riverpod_providers.dart';
// import '../providers/theme_provider.dart'; // REMOVED

class FiltersBar extends ConsumerStatefulWidget {
  const FiltersBar({super.key});

  @override
  ConsumerState<FiltersBar> createState() => _FiltersBarState();
}

class _FiltersBarState extends ConsumerState<FiltersBar> {
  final TextEditingController _presetController = TextEditingController();

  String? selectedPresetName;
  bool _isExclusive = true; // true = exclusive, false = inclusive

  @override
  void dispose() {
    _presetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // final themeProvider = context.watch<ThemeProvider>(); // REMOVED
    final filtersAsync = ref.watch(availableFiltersProvider);
    final selectedFilters = ref.watch(selectedFiltersProvider);
    const isDark = false; // Forced Light Mode

    return filtersAsync.when(
      skipLoadingOnReload: true,
      loading: () => _PanelShell(
        isDark: isDark,
        child: const SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, st) => Text('Error: $e'),
      data: (filters) {
        if (filters == null) return const SizedBox.shrink();

        return LayoutBuilder(
          builder: (context, constraints) {
            const gap = 16.0;
            final compact = constraints.maxWidth < 760;
            final horizontalPadding = compact ? 16.0 : 24.0;

            // Pass the padding into the calculation to prevent overflows!
            final itemWidth = _calculateItemWidth(
              maxWidth: constraints.maxWidth,
              gap: gap,
              horizontalPadding: horizontalPadding,
            );

            final wideItemWidth = compact ? itemWidth : 300.0;

            return _PanelShell(
              isDark: isDark,
              padding: EdgeInsets.all(horizontalPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      SizedBox(
                        width: itemWidth,
                        child: _FilterDropdown(
                          hint: 'Valuation',
                          items: filters.valuationMethods,
                          value: selectedFilters['valuation_method'],
                          onChanged: (v) => ref
                              .read(selectedFiltersProvider.notifier)
                              .updateFilter('valuation_method', v),
                          isDark: isDark,
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _FilterDropdown(
                          hint: 'Store',
                          items: filters.stores,
                          value: selectedFilters['store'],
                          onChanged: (v) => ref
                              .read(selectedFiltersProvider.notifier)
                              .updateFilter('store', v),
                          isDark: isDark,
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _FilterDropdown(
                          hint: 'Salesperson',
                          items: filters.salespersons,
                          value: selectedFilters['salesperson'],
                          onChanged: (v) => ref
                              .read(selectedFiltersProvider.notifier)
                              .updateFilter('salesperson', v),
                          isDark: isDark,
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _FilterDropdown(
                          hint: 'Channel',
                          items: filters.channels,
                          value: selectedFilters['channel'],
                          onChanged: (v) => ref
                              .read(selectedFiltersProvider.notifier)
                              .updateFilter('channel', v),
                          isDark: isDark,
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _FilterDropdown(
                          hint: 'Customer',
                          items: filters.customers,
                          value: selectedFilters['customer'],
                          onChanged: (v) => ref
                              .read(selectedFiltersProvider.notifier)
                              .updateFilter('customer', v),
                          isDark: isDark,
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _FilterDropdown(
                          hint: 'Product',
                          items: filters.products,
                          value: selectedFilters['product'],
                          onChanged: (v) => ref
                              .read(selectedFiltersProvider.notifier)
                              .updateFilter('product', v),
                          isDark: isDark,
                        ),
                      ),
                      SizedBox(
                        width: itemWidth,
                        child: _FilterDropdown(
                          hint: 'Txn Type',
                          items: filters.transactionTypes,
                          value: selectedFilters['transaction_type'],
                          onChanged: (v) => ref
                              .read(selectedFiltersProvider.notifier)
                              .updateFilter('transaction_type', v),
                          isDark: isDark,
                        ),
                      ),
                      SizedBox(
                        width: wideItemWidth,
                        child: _DateField(
                          value: selectedFilters['start_date'],
                          placeholder: 'Start Date',
                          isDark: isDark,
                          onTap: () => _pickDate(
                            context,
                            initialText: selectedFilters['start_date'],
                            onSelected: (v) => ref
                                .read(selectedFiltersProvider.notifier)
                                .updateFilter('start_date', v),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: wideItemWidth,
                        child: _DateField(
                          value: selectedFilters['end_date'],
                          placeholder: 'End Date',
                          isDark: isDark,
                          onTap: () => _pickDate(
                            context,
                            initialText: selectedFilters['end_date'],
                            onSelected: (v) => ref
                                .read(selectedFiltersProvider.notifier)
                                .updateFilter('end_date', v),
                          ),
                        ),
                      ),
                    ],
                  ),

                  Padding(
                    padding: EdgeInsets.symmetric(vertical: compact ? 20 : 28),
                    child: Divider(height: 1, color: const Color(0xFFF0F2F8)),
                  ),

                  // Bottom Action Bar
                  Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    alignment:
                        WrapAlignment.spaceBetween, // Pushes items to edges
                    children: [
                      // Left side controls
                      Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          SizedBox(
                            width: compact ? itemWidth : null,
                            child: _ExclusiveToggle(
                              isDark: isDark,
                              isExclusive: _isExclusive,
                              onChanged: (v) {
                                setState(() => _isExclusive = v);
                                // Wire to API: exclusive -> 'exclusive', inclusive -> 'inclusive'
                                ref
                                    .read(selectedFiltersProvider.notifier)
                                    .updateFilter(
                                      'tax_type',
                                      v ? 'exclusive' : 'inclusive',
                                    );
                              },
                            ),
                          ),
                          SizedBox(
                            width: compact ? itemWidth : null,
                            child: _ActionButton(
                              label: 'Reset All',
                              backgroundColor: const Color(0xFFFEE2E2),
                              foregroundColor: const Color(0xFFEF4444),
                              onTap: () {
                                ref
                                    .read(selectedFiltersProvider.notifier)
                                    .clearFilters();
                                setState(
                                  () => _isExclusive = true,
                                ); // Reset to exclusive (now the global default)
                              },
                            ),
                          ),
                        ],
                      ),

                      // Right side controls
                      Wrap(
                        spacing: gap,
                        runSpacing: gap,
                        children: [
                          // SizedBox(
                          //   width: compact ? itemWidth : 200,
                          //   child: _PresetNameField(
                          //     controller: _presetController,
                          //     isDark: isDark,
                          //   ),
                          // ),
                          // SizedBox(
                          //   width: compact ? itemWidth : null,
                          //   child: _ActionButton(
                          //     label: 'Save Preset',
                          //     backgroundColor: const Color(0xFF5450E8),
                          //     foregroundColor: Colors.white,
                          //     onTap: () => _savePreset(provider),
                          //   ),
                          // ),
                          // SizedBox(
                          //   width: compact ? constraints.maxWidth : 180,
                          //   child: _PresetDropdown(
                          //     isDark: isDark,
                          //     value: _selectedPresetName,
                          //     items: _savedPresets.keys.toList(),
                          //     onChanged: _loadPreset,
                          //   ),
                          // ),
                          // Theme toggle removed
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // Improved calculation that accounts for padding to prevent overflows
  double _calculateItemWidth({
    required double maxWidth,
    required double gap,
    required double horizontalPadding,
  }) {
    final availableWidth = maxWidth - (horizontalPadding * 2);

    if (availableWidth >= 1200) return (availableWidth - (gap * 4)) / 5;
    if (availableWidth >= 900) return (availableWidth - (gap * 3)) / 4;
    if (availableWidth >= 600) return (availableWidth - (gap * 2)) / 3;
    if (availableWidth >= 350) return (availableWidth - gap) / 2;
    return availableWidth; // Fallback to full width for extremely small screens
  }

  Future<void> _pickDate(
    BuildContext context, {
    required String? initialText,
    required ValueChanged<String> onSelected,
  }) async {
    DateTime initialDate = DateTime.now();
    if (initialText != null && initialText.isNotEmpty) {
      try {
        // API expects yyyy-MM-dd format
        initialDate = DateFormat('yyyy-MM-dd').parseStrict(initialText);
      } catch (_) {}
    }

    final selected = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (selected != null) {
      // Format as yyyy-MM-dd to match API expectation
      onSelected(DateFormat('yyyy-MM-dd').format(selected));
    }
  }
}

class _PanelShell extends StatelessWidget {
  final bool isDark;
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _PanelShell({
    required this.isDark,
    required this.child,
    this.padding = const EdgeInsets.all(24),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF161B2B)
            : Colors.white, // Matched KPI dark mode
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF262D40) : const Color(0xFFF0F2F8),
          width: 1.5,
        ),
        boxShadow: isDark
            ? null
            : const [
                BoxShadow(
                  color: Color(0x0A000000), // Softer shadow
                  blurRadius: 16,
                  offset: Offset(0, 6),
                ),
              ],
      ),
      child: child,
    );
  }
}

class _FilterDropdown extends StatelessWidget {
  final String hint;
  final List<String> items;
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool isDark;

  const _FilterDropdown({
    required this.hint,
    required this.items,
    required this.value,
    required this.onChanged,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveValue = items.contains(value) ? value : null;
    return Container(
      height: 52, // Reduced from 58 for a sleeker look
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B2135) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2D354A) : const Color(0xFFE2E8F0),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: effectiveValue,
          icon: Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 20,
            color: isDark ? const Color(0xFF8F9BB3) : const Color(0xFF64748B),
          ),
          dropdownColor: isDark ? const Color(0xFF1B2135) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFFF4F6FF) : const Color(0xFF0F172A),
          ),
          items: [
            DropdownMenuItem<String>(
              value: null,
              child: Text(
                hint,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isDark
                      ? const Color(0xFF8F9BB3)
                      : const Color(0xFF64748B),
                ),
              ),
            ),
            ...items.map(
              (item) => DropdownMenuItem<String>(
                value: item,
                child: Text(item, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String? value;
  final String placeholder;
  final bool isDark;
  final VoidCallback onTap;

  const _DateField({
    required this.value,
    required this.placeholder,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null && value!.isNotEmpty;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1B2135) : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF2D354A) : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.calendar_today_outlined,
              size: 18,
              color: hasValue
                  ? (isDark ? const Color(0xFF5450E8) : const Color(0xFF3B82F6))
                  : (isDark
                        ? const Color(0xFF8F9BB3)
                        : const Color(0xFF64748B)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                hasValue ? value! : placeholder,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: hasValue
                      ? (isDark
                            ? const Color(0xFFF4F6FF)
                            : const Color(0xFF0F172A))
                      : (isDark
                            ? const Color(0xFF8F9BB3)
                            : const Color(0xFF64748B)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final String label;
  final Color backgroundColor;
  final Color foregroundColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.backgroundColor,
    required this.foregroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12), // Matched border radius
          ),
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.2,
          ),
        ),
        child: Text(label),
      ),
    );
  }
}

class _ExclusiveToggle extends StatelessWidget {
  final bool isDark;
  final bool isExclusive;
  final ValueChanged<bool> onChanged;

  const _ExclusiveToggle({
    required this.isDark,
    required this.isExclusive,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.all(4), // Tighter padding for segmented look
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111522) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF2D354A) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Expanded(
            child: _ToggleChip(
              label: 'Exclusive',
              selected: isExclusive,
              onTap: () => onChanged(true),
            ),
          ),
          Expanded(
            child: _ToggleChip(
              label: 'Inclusive',
              selected: !isExclusive,
              onTap: () => onChanged(false),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ToggleChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? (Colors.white) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow:
              selected && Theme.of(context).brightness == Brightness.light
              ? [
                  const BoxShadow(
                    color: Color(0x1A000000),
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected
                ? (const Color(0xFF0F172A))
                : const Color(0xFF64748B),
          ),
        ),
      ),
    );
  }
}

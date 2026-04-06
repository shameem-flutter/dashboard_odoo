import re
import sys

filepath = 'lib/widgets/filters_bar.dart'
try:
    with open(filepath, 'r', encoding='utf-8') as f:
        text = f.read()

    # Imports
    text = text.replace("import 'package:provider/provider.dart';", "import 'package:provider/provider.dart';\nimport 'package:flutter_riverpod/flutter_riverpod.dart';")
    text = text.replace("import '../providers/dashboard_provider.dart';", "import '../providers/riverpod_providers.dart';")

    # State classes
    text = text.replace("class FiltersBar extends StatefulWidget", "class FiltersBar extends ConsumerStatefulWidget")
    text = text.replace("class _FiltersBarState extends State<FiltersBar>", "class _FiltersBarState extends ConsumerState<FiltersBar>")

    # Build signature
    text = re.sub(
        r"Widget build\(BuildContext context\) \{[\s\S]*?if \(filters == null\) \{[\s\S]*?return _PanelShell\([\s\S]*?child: const SizedBox\([\s\S]*?height: 120,[\s\S]*?child: Center\(child: CircularProgressIndicator\(\)\),[\s\S]*?\),[\s\S]*?\);[\s\S]*?\}",
        """Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final filtersAsync = ref.watch(availableFiltersProvider);
    final selectedFilters = ref.watch(selectedFiltersProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return filtersAsync.when(
      loading: () => _PanelShell(
        isDark: isDark,
        child: const SizedBox(
          height: 120,
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, st) => Text('Error: $e'),
      data: (filters) {
        if (filters == null) return const SizedBox.shrink();""",
        text
    )

    # Filter references
    text = text.replace("provider.selectedFilters", "selectedFilters")
    text = text.replace("provider.updateFilter", "ref.read(selectedFiltersProvider.notifier).updateFilter")
    text = text.replace("provider.clearFilters()", "ref.read(selectedFiltersProvider.notifier).clearFilters()")

    # Close the async when
    text = re.sub(
        r"      \},[\s]*\);[\s]*\}[\s]*// Improved calculation",
        "      },\n    );\n      },\n    );\n  }\n\n  // Improved calculation",
        text
    )

    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(text)
    print("Updated filters_bar.dart successfully.")
except Exception as e:
    print(e)

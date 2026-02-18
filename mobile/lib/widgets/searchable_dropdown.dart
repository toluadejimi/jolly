import 'package:flutter/material.dart';

/// A dropdown-style field that opens a searchable list in a bottom sheet.
class SearchableDropdown<T> extends StatelessWidget {
  const SearchableDropdown({
    super.key,
    required this.items,
    required this.label,
    required this.displayString,
    required this.value,
    required this.onChanged,
    this.hint = 'Search...',
    this.errorText,
  });

  final List<T> items;
  final String label;
  final String Function(T) displayString;
  final T? value;
  final ValueChanged<T?> onChanged;
  final String hint;
  final String? errorText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: items.isEmpty ? null : () => _showPicker(context),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          errorText: errorText,
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          value != null ? displayString(value as T) : '',
          style: value != null
              ? theme.textTheme.bodyLarge
              : theme.textTheme.bodyLarge?.copyWith(
                  color: theme.hintColor,
                ),
        ),
      ),
    );
  }

  void _showPicker(BuildContext context) {
    List<T> filtered = List.from(items);
    final searchController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx2, setModalState) {
            void filter(String q) {
              final lower = q.trim().toLowerCase();
              if (lower.isEmpty) {
                setModalState(() => filtered = List.from(items));
              } else {
                setModalState(() {
                  filtered = items
                      .where((t) =>
                          displayString(t).toLowerCase().contains(lower))
                      .toList();
                });
              }
            }

            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.3,
              maxChildSize: 0.9,
              expand: false,
              builder: (_, scrollController) => Padding(
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(ctx).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          hintText: hint,
                          prefixIcon: const Icon(Icons.search),
                          border: const OutlineInputBorder(),
                        ),
                        onChanged: filter,
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        controller: scrollController,
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final t = filtered[i];
                          final selected = value == t;
                          return ListTile(
                            title: Text(displayString(t)),
                            selected: selected,
                            onTap: () {
                              onChanged(t);
                              Navigator.pop(ctx);
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

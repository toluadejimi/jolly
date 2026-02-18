// ignore: file_names
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:giftfr/constants/size_config.dart';
import 'package:giftfr/models/category.dart';
import 'package:giftfr/services/api_service.dart';
import 'package:giftfr/screens/product_list_screen.dart';
import '../../../constants/widget_utils.dart';

class TabCategory extends StatefulWidget {
  const TabCategory({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _TabCategoryState();
}

class _TabCategoryState extends State<TabCategory> {
  List<CategoryItem> _categories = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final api = context.read<ApiService>();
    final res = await api.getCategories();
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (res.success && res.data != null) {
        _categories = res.data!;
        _error = null;
      } else {
        _error = res.error ?? 'Failed to load categories';
      }
    });
  }

  String? _imageUrl(CategoryItem cat) {
    if (cat.imageUrl != null && cat.imageUrl!.isNotEmpty) return cat.imageUrl;
    if (cat.iconUrl != null && cat.iconUrl!.isNotEmpty) return cat.iconUrl;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    SizeConfig().init(context);
    double appbarPadding = getAppBarPadding();
    final theme = Theme.of(context);
    return SizedBox(
      width: double.infinity,
      height: double.infinity,
      child: Column(
        children: [
          getDefaultHeader(context, "Categories", () {}, (value) {},
              withFilter: false, isShowBack: false, isShowSearch: false),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(_error!, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                              const SizedBox(height: 16),
                              FilledButton(onPressed: _load, child: const Text('Retry')),
                            ],
                          ),
                        ),
                      )
                    : _categories.isEmpty
                        ? getEmptyWidget(
                            "empty_card.svg",
                            "No categories",
                            "Categories will appear here.",
                            "Browse products",
                            () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => const ProductListScreen(),
                                ),
                              );
                            },
                            context: context,
                          )
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: GridView.builder(
                              padding: EdgeInsets.all(appbarPadding),
                              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.85,
                              ),
                              itemCount: _categories.length,
                              itemBuilder: (context, index) {
                                final cat = _categories[index];
                                return InkWell(
                                  onTap: () {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (context) => ProductListScreen(categoryId: cat.id),
                                      ),
                                    );
                                  },
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: theme.cardTheme.color,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: theme.dividerColor),
                                      boxShadow: theme.brightness == Brightness.dark ? null : [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.06),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                                            child: _imageUrl(cat) != null
                                                ? CachedNetworkImage(
                                                    imageUrl: _imageUrl(cat)!,
                                                    width: double.infinity,
                                                    height: double.infinity,
                                                    fit: BoxFit.cover,
                                                    placeholder: (_, __) => Container(
                                                      color: theme.cardTheme.color,
                                                      child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                                    ),
                                                    errorWidget: (_, __, ___) => Container(
                                                      color: theme.colorScheme.primary.withValues(alpha: 0.2),
                                                      child: Icon(Icons.category, color: theme.colorScheme.primary, size: 40),
                                                    ),
                                                  )
                                                : Container(
                                                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                                                    child: Icon(Icons.category, color: theme.colorScheme.primary, size: 40),
                                                  ),
                                          ),
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
                                          child: Text(
                                            cat.name,
                                            style: theme.textTheme.titleSmall?.copyWith(
                                              fontWeight: FontWeight.w600,
                                              color: theme.colorScheme.onSurface,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

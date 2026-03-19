import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';
import 'package:saydin/features/favorites/presentation/cubit/favorites_cubit.dart';
import 'package:saydin/features/what_if/domain/entities/asset.dart';
import 'package:saydin/l10n/app_localizations.dart';

class AssetSelector extends StatelessWidget {
  final List<Asset> assets;
  final String? selectedSymbol;
  final ValueChanged<String> onChanged;

  /// Listeden gizlenecek semboller (ör. portföyde zaten eklenmiş varlıklar).
  final Set<String> excludeSymbols;

  const AssetSelector({
    super.key,
    required this.assets,
    required this.selectedSymbol,
    required this.onChanged,
    this.excludeSymbols = const {},
  });

  String? _selectedName() {
    if (selectedSymbol == null) return null;
    try {
      return assets.firstWhere((a) => a.symbol == selectedSymbol).displayName;
    } catch (_) {
      return selectedSymbol;
    }
  }

  Future<void> _openSheet(BuildContext context) async {
    final visibleAssets = excludeSymbols.isEmpty
        ? assets
        : assets.where((a) => !excludeSymbols.contains(a.symbol)).toList();
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => BlocProvider.value(
        value: context.read<FavoritesCubit>(),
        child: _AssetSearchSheet(
          assets: visibleAssets,
          selectedSymbol: selectedSymbol,
        ),
      ),
    );
    if (selected != null) onChanged(selected);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final selectedName = _selectedName();

    return InkWell(
      onTap: () => _openSheet(context),
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        isEmpty: selectedName == null,
        decoration: InputDecoration(
          labelText: l10n.selectAsset,
          border: const OutlineInputBorder(),
          prefixIcon: const Icon(Icons.show_chart),
          suffixIcon: const Icon(Icons.search),
        ),
        child: selectedName == null
            ? const SizedBox.shrink()
            : Text(
                selectedName,
                style: Theme.of(context).textTheme.bodyLarge,
                overflow: TextOverflow.ellipsis,
              ),
      ),
    );
  }
}

class _AssetSearchSheet extends StatefulWidget {
  final List<Asset> assets;
  final String? selectedSymbol;

  const _AssetSearchSheet({required this.assets, this.selectedSymbol});

  @override
  State<_AssetSearchSheet> createState() => _AssetSearchSheetState();
}

class _AssetSearchSheetState extends State<_AssetSearchSheet> {
  static const _categoryOrder = [
    'currency',
    'precious_metal',
    'crypto',
    'stock',
  ];

  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _categoryLabel(String category, AppLocalizations l10n) =>
      switch (category) {
        'favorites' => l10n.categoryFavorites,
        'currency' => l10n.categoryCurrency,
        'precious_metal' => l10n.categoryPreciousMetal,
        'crypto' => l10n.categoryCrypto,
        'stock' => l10n.categoryStock,
        _ => category,
      };

  List<Asset> get _filtered {
    if (_query.isEmpty) return widget.assets;
    final q = _query.toLowerCase();
    return widget.assets
        .where(
          (a) =>
              a.displayName.toLowerCase().contains(q) ||
              a.symbol.toLowerCase().contains(q),
        )
        .toList();
  }

  List<Object> _groupedItems(Set<String> favorites) {
    final filtered = _filtered;
    if (_query.isNotEmpty) return filtered;

    final items = <Object>[];

    // Favoriler bölümü (en üstte)
    final favoriteAssets = favorites.isNotEmpty
        ? filtered.where((a) => favorites.contains(a.symbol)).toList()
        : <Asset>[];
    if (favoriteAssets.isNotEmpty) {
      items.add('favorites');
      items.addAll(favoriteAssets);
    }

    // Kategori gruplama — favorileri hariç tut
    final nonFavorites = favorites.isNotEmpty
        ? filtered.where((a) => !favorites.contains(a.symbol)).toList()
        : filtered;
    final grouped = <String, List<Asset>>{};
    for (final a in nonFavorites) {
      grouped.putIfAbsent(a.category, () => []).add(a);
    }

    for (final cat in _categoryOrder) {
      final list = grouped[cat];
      if (list == null || list.isEmpty) continue;
      items.add(cat);
      items.addAll(list);
    }
    for (final cat in grouped.keys) {
      if (_categoryOrder.contains(cat)) continue;
      items.add(cat);
      items.addAll(grouped[cat]!);
    }
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);

    return BlocBuilder<FavoritesCubit, Set<String>>(
      builder: (context, favorites) {
        final items = _groupedItems(favorites);

        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.75,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) => Column(
            children: [
              // Tutaç
              Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Arama kutusu
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: TextField(
                  controller: _searchController,
                  autofocus: false,
                  decoration: InputDecoration(
                    hintText: l10n.searchAsset,
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    isDense: true,
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _query = '');
                            },
                          )
                        : null,
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
              // Liste
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final item = items[i];

                    // Kategori başlığı
                    if (item is String) {
                      return Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                        child: Text(
                          _categoryLabel(item, l10n).toUpperCase(),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      );
                    }

                    // Asset satırı
                    final asset = item as Asset;
                    final isSelected = asset.symbol == widget.selectedSymbol;
                    final isFav = favorites.contains(asset.symbol);
                    final cubit = context.read<FavoritesCubit>();

                    return ListTile(
                      title: Text(asset.displayName),
                      subtitle: Text(
                        asset.symbol,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      leading: IconButton(
                        icon: Icon(
                          isFav ? Icons.star : Icons.star_border,
                          color: isFav
                              ? Colors.amber
                              : theme.colorScheme.outlineVariant,
                        ),
                        onPressed: () {
                          if (!isFav && cubit.isFull) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  l10n.favoritesMaxReached(
                                    FavoritesCubit.maxFavorites,
                                  ),
                                ),
                              ),
                            );
                            return;
                          }
                          cubit.toggle(asset.symbol);
                        },
                        visualDensity: VisualDensity.compact,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      trailing: isSelected
                          ? Icon(Icons.check, color: theme.colorScheme.primary)
                          : null,
                      selected: isSelected,
                      onTap: () => Navigator.of(context).pop(asset.symbol),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

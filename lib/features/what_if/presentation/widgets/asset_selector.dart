import 'package:flutter/material.dart';
import 'package:saydin/core/l10n/l10n_extensions.dart';
import 'package:saydin/features/what_if/domain/entities/asset.dart';

class AssetSelector extends StatelessWidget {
  final List<Asset> assets;
  final String? selectedSymbol;
  final ValueChanged<String> onChanged;

  const AssetSelector({
    super.key,
    required this.assets,
    required this.selectedSymbol,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<String>(
      key: ValueKey(selectedSymbol),
      initialValue: selectedSymbol,
      decoration: InputDecoration(
        labelText: context.l10n.selectAsset,
        border: const OutlineInputBorder(),
        prefixIcon: const Icon(Icons.show_chart),
      ),
      items: assets
          .map(
            (a) =>
                DropdownMenuItem(value: a.symbol, child: Text(a.displayName)),
          )
          .toList(),
      onChanged: (v) => v != null ? onChanged(v) : null,
    );
  }
}

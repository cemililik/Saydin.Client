import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:saydin/features/what_if/domain/entities/asset.dart';
import 'package:saydin/features/what_if/presentation/bloc/what_if_bloc.dart';
import 'package:saydin/features/what_if/presentation/bloc/what_if_event.dart';
import 'package:saydin/features/what_if/presentation/bloc/what_if_state.dart';
import 'package:saydin/features/what_if/presentation/widgets/amount_input.dart';
import 'package:saydin/features/what_if/presentation/widgets/asset_selector.dart';
import 'package:saydin/features/what_if/presentation/widgets/date_input.dart';
import 'package:saydin/features/what_if/presentation/widgets/result_card.dart';

class WhatIfPage extends StatefulWidget {
  const WhatIfPage({super.key});

  @override
  State<WhatIfPage> createState() => _WhatIfPageState();
}

class _WhatIfPageState extends State<WhatIfPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();

  String? _selectedSymbol;
  DateTime? _buyDate;
  DateTime? _sellDate;
  String _amountType = 'try';

  @override
  void initState() {
    super.initState();
    context.read<WhatIfBloc>().add(const WhatIfAssetsRequested());
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _onCalculate() {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedSymbol == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Varlık seçiniz')),
      );
      return;
    }
    if (_buyDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alış tarihi giriniz')),
      );
      return;
    }

    final amount = num.tryParse(_amountController.text.replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geçerli bir tutar giriniz')),
      );
      return;
    }

    context.read<WhatIfBloc>().add(WhatIfCalculateRequested(
          assetSymbol: _selectedSymbol!,
          buyDate: _buyDate!,
          sellDate: _sellDate,
          amount: amount,
          amountType: _amountType,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ya Alsaydım?'),
        centerTitle: true,
      ),
      body: BlocConsumer<WhatIfBloc, WhatIfState>(
        listener: (context, state) {
          if (state is WhatIfFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red.shade700,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is WhatIfAssetsLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final assets = switch (state) {
            WhatIfAssetsLoaded(:final assets) => assets,
            WhatIfCalculating(:final assets) => assets,
            WhatIfSuccess(:final assets) => assets,
            WhatIfFailure(:final assets) => assets,
            _ => <Asset>[],
          };

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AssetSelector(
                    assets: assets,
                    selectedSymbol: _selectedSymbol,
                    onChanged: (v) => setState(() => _selectedSymbol = v),
                  ),
                  const SizedBox(height: 16),
                  DateInput(
                    label: 'Alış Tarihi',
                    value: _buyDate,
                    lastDate: DateTime.now(),
                    onChanged: (v) => setState(() => _buyDate = v),
                  ),
                  const SizedBox(height: 16),
                  DateInput(
                    label: 'Satış Tarihi (opsiyonel)',
                    value: _sellDate,
                    firstDate: _buyDate,
                    lastDate: DateTime.now(),
                    required: false,
                    onChanged: (v) => setState(() => _sellDate = v),
                  ),
                  const SizedBox(height: 16),
                  AmountInput(
                    controller: _amountController,
                    amountType: _amountType,
                    onAmountTypeChanged: (v) =>
                        setState(() => _amountType = v),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed:
                        state is WhatIfCalculating ? null : _onCalculate,
                    icon: state is WhatIfCalculating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.calculate),
                    label: Text(
                      state is WhatIfCalculating
                          ? 'Hesaplanıyor...'
                          : 'Hesapla',
                    ),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                  if (state is WhatIfSuccess) ...[
                    const SizedBox(height: 24),
                    ResultCard(result: state.result),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

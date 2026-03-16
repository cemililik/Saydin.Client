import 'package:equatable/equatable.dart';

abstract class WhatIfEvent extends Equatable {
  const WhatIfEvent();
  @override
  List<Object?> get props => [];
}

class WhatIfAssetsRequested extends WhatIfEvent {
  const WhatIfAssetsRequested();
}

class WhatIfCalculateRequested extends WhatIfEvent {
  final String assetSymbol;
  final DateTime buyDate;
  final DateTime? sellDate;
  final num amount;
  final String amountType;

  const WhatIfCalculateRequested({
    required this.assetSymbol,
    required this.buyDate,
    this.sellDate,
    required this.amount,
    required this.amountType,
  });

  @override
  List<Object?> get props => [
    assetSymbol,
    buyDate,
    sellDate,
    amount,
    amountType,
  ];
}

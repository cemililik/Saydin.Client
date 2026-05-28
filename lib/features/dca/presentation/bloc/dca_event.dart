import 'package:equatable/equatable.dart';

abstract class DcaEvent extends Equatable {
  const DcaEvent();

  @override
  List<Object?> get props => [];
}

class DcaAssetsRequested extends DcaEvent {
  const DcaAssetsRequested();
}

class DcaSymbolChanged extends DcaEvent {
  final String? symbol;
  const DcaSymbolChanged(this.symbol);

  @override
  List<Object?> get props => [symbol];
}

class DcaStartDateChanged extends DcaEvent {
  final DateTime date;
  const DcaStartDateChanged(this.date);

  @override
  List<Object?> get props => [date];
}

class DcaEndDateChanged extends DcaEvent {
  final DateTime? date;
  const DcaEndDateChanged(this.date);

  @override
  List<Object?> get props => [date];
}

class DcaPeriodChanged extends DcaEvent {
  final String period;
  const DcaPeriodChanged(this.period);

  @override
  List<Object?> get props => [period];
}

class DcaInflationToggled extends DcaEvent {
  const DcaInflationToggled();
}

class DcaCalculateRequested extends DcaEvent {
  final String assetSymbol;
  final DateTime startDate;
  final DateTime? endDate;
  final num periodicAmount;
  final String period;
  final String amountType;
  final bool includeInflation;

  const DcaCalculateRequested({
    required this.assetSymbol,
    required this.startDate,
    this.endDate,
    required this.periodicAmount,
    required this.period,
    this.amountType = 'try',
    this.includeInflation = false,
  });

  @override
  List<Object?> get props => [
    assetSymbol,
    startDate,
    endDate,
    periodicAmount,
    period,
    amountType,
    includeInflation,
  ];
}

class DcaReplayRequested extends DcaEvent {
  final String assetSymbol;
  final DateTime startDate;
  final DateTime? endDate;
  final num periodicAmount;
  final String period;
  final String amountType;
  final bool includeInflation;

  const DcaReplayRequested({
    required this.assetSymbol,
    required this.startDate,
    this.endDate,
    required this.periodicAmount,
    required this.period,
    this.amountType = 'try',
    this.includeInflation = false,
  });

  @override
  List<Object?> get props => [
    assetSymbol,
    startDate,
    endDate,
    periodicAmount,
    period,
    amountType,
    includeInflation,
  ];
}

class DcaLanguageChanged extends DcaEvent {
  const DcaLanguageChanged();
}

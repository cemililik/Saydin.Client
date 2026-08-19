import 'package:decimal/decimal.dart';

/// Finansal request sınırındaki ortak tutar/birim invariant'ları.
///
/// Kullanıcı girdisi bu doğrulamadan sonra domain/repository katmanlarında
/// yalnız [Decimal] olarak taşınır. Böylece binary floating-point dönüşümü
/// oluşmaz ve bütün finansal akışlar aynı limit politikasını uygular.
class FinancialAmountValidator {
  const FinancialAmountValidator._();

  static final Decimal maximum = Decimal.fromInt(1000000000);

  static int maximumScaleFor(String amountType) => switch (amountType) {
    'try' => 2,
    'grams' => 4,
    'units' => 8,
    _ => -1,
  };

  static bool isValid({
    required Decimal value,
    required String amountType,
    Iterable<String>? allowedAmountTypes,
  }) {
    final maximumScale = maximumScaleFor(amountType);
    if (maximumScale < 0 || value <= Decimal.zero || value > maximum) {
      return false;
    }
    if (allowedAmountTypes != null &&
        !allowedAmountTypes.contains(amountType)) {
      return false;
    }
    return decimalScale(value) <= maximumScale;
  }

  static int decimalScale(Decimal value) {
    final text = value.toString();
    final separator = text.indexOf('.');
    return separator < 0 ? 0 : text.length - separator - 1;
  }
}

import 'package:decimal/decimal.dart';

/// Finansal yanıtlardaki kâr/zarar yönünü tek bir parasal kaynaktan türetir.
///
/// Backend'in opsiyonel `isProfit` alanı yalnız tutarlılık kanıtıdır. Görsel
/// renk/etiket kararı her zaman exact [Decimal] `profitLossTry` işaretinden
/// gelir; çelişkili veya yanlış tipte payload fail-closed reddedilir.
class ProfitDirectionValidator {
  const ProfitDirectionValidator._();

  static bool derive({
    required Object? rawIsProfit,
    required Decimal profitLossTry,
    required String context,
  }) {
    final isNeutral = profitLossTry == Decimal.zero;
    final derived = profitLossTry > Decimal.zero;
    if (rawIsProfit != null && rawIsProfit is! bool) {
      throw FormatException('$context: isProfit bool değil ($rawIsProfit)');
    }
    // Eski boolean API sıfır değişimi temsil edemez. Sıfırda backend'in
    // true/false seçimini kontrat ihlali saymayız; presentation üçlü sonucu
    // exact Decimal tutardan üretir. Binary compatibility değeri false'tur.
    if (!isNeutral && rawIsProfit is bool && rawIsProfit != derived) {
      throw FormatException('$context: isProfit, profitLossTry ile tutarsız');
    }
    return derived;
  }
}

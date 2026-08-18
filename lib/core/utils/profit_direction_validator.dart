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
    final derived = profitLossTry >= Decimal.zero;
    if (rawIsProfit != null && rawIsProfit is! bool) {
      throw FormatException('$context: isProfit bool değil ($rawIsProfit)');
    }
    if (rawIsProfit is bool && rawIsProfit != derived) {
      throw FormatException('$context: isProfit, profitLossTry ile tutarsız');
    }
    return derived;
  }
}

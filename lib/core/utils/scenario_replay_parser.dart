import 'package:decimal/decimal.dart';
import 'package:saydin/core/utils/financial_amount_validator.dart';
import 'package:saydin/core/utils/money_parser.dart';
import 'package:saydin/features/portfolio/domain/entities/portfolio_item.dart';
import 'package:saydin/features/portfolio/domain/portfolio_constants.dart';

/// Kaydedilmiş senaryolardaki versionless JSON'i yeni Decimal request
/// sınırına güvenle taşıyan app-orchestration parser'ı.
class ScenarioReplayParser {
  const ScenarioReplayParser._();

  /// Yeni kayıtlarda `extraData.schemaVersion` olarak yazılan sözleşme.
  /// Version alanı olmayan tarihsel kayıtlar v1 kabul edilip güvenli
  /// default/validator'lardan geçirilir; bilinmeyen gelecek sürüm çalıştırılmaz.
  static const int currentSchemaVersion = 2;

  static bool hasSupportedSchema(Map<String, dynamic>? extraData) {
    final raw = extraData?['schemaVersion'];
    if (raw == null) return true; // legacy v1 migration
    return raw is int && raw >= 1 && raw <= currentSchemaVersion;
  }

  static bool _usesStrictCurrentSchema(Map<String, dynamic>? extraData) =>
      extraData?['schemaVersion'] == currentSchemaVersion;

  /// Current-schema What-If payloadında `mode` yalnız `null` (normal) veya
  /// `reverse` olabilir. Legacy kayıtların eksik/tanınmayan alanları geçmiş
  /// davranışla normal moda migrate edilir; explicit v2 bozukluğu çevrilmez.
  static bool hasValidWhatIfMode(Map<String, dynamic>? extraData) {
    if (!_usesStrictCurrentSchema(extraData) ||
        !extraData!.containsKey('mode')) {
      return true;
    }
    final raw = extraData['mode'];
    return raw == null || raw == 'reverse';
  }

  static List<String> comparisonSymbols(Object? value) {
    if (value is! String) return const [];
    final symbols = value
        .split(',')
        .map((symbol) => symbol.trim())
        .where((symbol) => symbol.isNotEmpty)
        .toList(growable: false);
    final uniqueSymbols = symbols.toSet();
    return symbols.length >= 2 &&
            symbols.length <= 5 &&
            uniqueSymbols.length == symbols.length
        ? symbols
        : const [];
  }

  /// Legacy eksik/bozuk period aylığa migrate edilir. Current-schema'da açıkça
  /// yazılmış bilinmeyen değer ise başka bir finansal komuta dönüştürülmez.
  static String? dcaPeriod(Map<String, dynamic>? extraData) {
    final raw = extraData?['period'];
    if (raw is String && (raw == 'weekly' || raw == 'monthly')) return raw;
    if (_usesStrictCurrentSchema(extraData) &&
        extraData!.containsKey('period')) {
      return null;
    }
    return 'monthly';
  }

  static Decimal? dcaPeriodicAmount(
    Map<String, dynamic>? extraData,
    Decimal fallback, {
    required String amountType,
  }) {
    final parsed = MoneyParser.tryDecimal(extraData?['periodicAmount']);
    if (parsed == null ||
        !FinancialAmountValidator.isValid(
          value: parsed,
          amountType: amountType,
        )) {
      if (_usesStrictCurrentSchema(extraData) &&
          extraData!.containsKey('periodicAmount')) {
        return null;
      }
      return fallback;
    }
    // v2 iki aynı kaynağı taşır; top-level `amount` liste/dedup girdisidir.
    // Birbirinden farklı iki geçerli tutardan birini sessizce seçmek finansal
    // semantiği değiştirir, bu yüzden current-schema payload reddedilir.
    if (_usesStrictCurrentSchema(extraData) && parsed != fallback) return null;
    return parsed;
  }

  static List<PortfolioItem> portfolioItems(
    Object? rawItems, {
    required String Function() nextId,
  }) {
    if (rawItems is! List<dynamic> ||
        rawItems.isEmpty ||
        rawItems.length > PortfolioConstants.maxItems) {
      return const [];
    }
    final result = <PortfolioItem>[];
    final symbols = <String>{};
    for (final raw in rawItems) {
      if (raw is! Map<Object?, Object?>) return const [];
      final symbol = raw['assetSymbol'];
      final displayName = raw['assetDisplayName'];
      final amount = MoneyParser.tryDecimal(raw['amount']);
      final amountType = raw['amountType'];
      if (symbol is! String ||
          displayName is! String ||
          amount == null ||
          amountType is! String ||
          !FinancialAmountValidator.isValid(
            value: amount,
            amountType: amountType,
          ) ||
          !symbols.add(symbol)) {
        return const [];
      }
      result.add(
        PortfolioItem(
          id: nextId(),
          assetSymbol: symbol,
          assetDisplayName: displayName,
          amount: amount,
          amountType: amountType,
        ),
      );
    }
    return result;
  }
}

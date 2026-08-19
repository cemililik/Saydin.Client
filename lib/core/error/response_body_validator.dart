import 'app_error.dart';

/// Başarılı HTTP yanıtlarının zorunlu gövde sözleşmesini tekilleştirir.
class ResponseBodyValidator {
  const ResponseBodyValidator._();

  /// Başarılı response içindeki display-only oran/yüzde alanını doğrular.
  ///
  /// JSON decoder `NaN`/`Infinity` üretmese bile test adapter'ları, özel
  /// decoder'lar veya hatalı bir transport katmanı bir [double] ile bunları
  /// taşıyabilir. Bu değerler formatter ve layout katmanına ulaşırsa hem
  /// anlamsız finansal çıktı hem de render hatası üretir. Keyfi bir üst sınır
  /// uygulanmaz; sıfır ve temsil edilebilen en büyük finite değer geçerlidir.
  static double requireFiniteDouble(Object? value, String field) {
    if (value is! num) {
      throw FormatException('2xx response: "$field" sayı değil ($value)');
    }
    final parsed = value.toDouble();
    if (!parsed.isFinite) {
      throw FormatException('2xx response: "$field" finite değil ($value)');
    }
    return parsed;
  }

  /// Nullable oran/yüzde alanı için [requireFiniteDouble] karşılığı.
  ///
  /// Yalnız gerçek `null` yokluk anlamına gelir; yanlış tip veya non-finite
  /// değer sessizce `null`a indirgenmez çünkü ikisi de response kontrat
  /// ihlalidir.
  static double? optionalFiniteDouble(Object? value, String field) =>
      value == null ? null : requireFiniteDouble(value, field);

  static Map<String, dynamic> requireMap(Object? value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map<Object?, Object?>) {
      try {
        return Map<String, dynamic>.from(value);
      } catch (error) {
        throw MalformedResponseError(cause: error);
      }
    }
    throw const MalformedResponseError();
  }

  /// Başarılı yanıtın gövdesinin top-level JSON listesi olmasını zorunlu
  /// kılar. `[]` geçerli bir liste sonucudur; `null` veya map ise taşıma/
  /// backend sözleşmesi bozulmuştur ve sessizce "veri yok" sayılamaz.
  static List<dynamic> requireList(Object? value) {
    if (value is List<dynamic>) return value;
    throw const MalformedResponseError();
  }

  static List<dynamic> requireListField(
    Map<String, dynamic> body,
    String field,
  ) {
    final value = body[field];
    if (value is List<dynamic>) return value;
    throw MalformedResponseError(
      cause: FormatException('2xx response: "$field" liste değil'),
    );
  }

  static T parse<T>(T Function() parser) {
    try {
      return parser();
    } on MalformedResponseError {
      rethrow;
    } on FormatException catch (error) {
      throw MalformedResponseError(cause: error);
    } on TypeError catch (error) {
      throw MalformedResponseError(cause: error);
    }
  }
}

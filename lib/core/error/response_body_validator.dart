import 'app_error.dart';

/// Başarılı HTTP yanıtlarının zorunlu gövde sözleşmesini tekilleştirir.
class ResponseBodyValidator {
  const ResponseBodyValidator._();

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

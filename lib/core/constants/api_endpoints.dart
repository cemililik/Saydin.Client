/// Backend REST endpoint sabitleri.
///
/// **Namespace sözleşmesi (F-08-16):** Hipotetik/"ya alsaydım" türevi tüm
/// hesaplamalar `/v1/what-if/*` altında toplanır — `calculate`, `compare`,
/// `reverse` ve `dca` dahil. DCA istemcide ayrı bir *feature* (`features/dca`)
/// olsa da backend'de bir what-if senaryo türü olduğu için endpoint'i
/// `/v1/what-if/dca`'dır. İstemci mimarisi (feature klasörü) ile API
/// yapısı (namespace) kasıtlı olarak ayrışır; bu tutarsızlık değildir.
/// Backend bir gün `/v1/dca`'ya taşırsa burası tek noktada güncellenir.
class ApiEndpoints {
  ApiEndpoints._();

  static const whatIfCalculate = '/v1/what-if/calculate';
  static const whatIfCompare = '/v1/what-if/compare';
  static const whatIfReverse = '/v1/what-if/reverse';
  static const assets = '/v1/assets';
  static const scenarios = '/v1/scenarios';
  static const account = '/v1/account';

  /// Bkz. sınıf docstring'i — DCA backend'de what-if namespace'i altında.
  static const dcaCalculate = '/v1/what-if/dca';
  static const appConfig = '/v1/config';
}

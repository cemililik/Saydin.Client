/// Türkçe diline duyarlı metin yardımcıları.
///
/// Dart'ın `String.toUpperCase`/`toLowerCase` çağrıları locale-insensitive
/// (Unicode default case mapping). Türkçe'de iki tarafta dört harf çiftine
/// dikkat etmek gerekir:
///   - `i` (U+0069) → `İ` (U+0130) [Türkçe doğru; default `I` U+0049]
///   - `ı` (U+0131) → `I` (U+0049) [Türkçe doğru; default `I` U+0049]
///
/// `'sil'.toUpperCase()` Dart'ta `'SIL'` döner ama Türkçe doğru karşılık
/// `'SİL'`. Bu farkı atlamak hesap silme onay kelimesi gibi kritik
/// karşılaştırmalarda fonksiyonel kırılma yaratır (kullanıcı `sil` yazsa
/// bile `SİL` ile eşleşmez).
library;

/// Türkçe büyütme: `i → İ`, `ı → I`, sonra Dart'ın default upper case'i.
String toUpperCaseTr(String input) {
  return input.replaceAll('i', 'İ').replaceAll('ı', 'I').toUpperCase();
}

/// Türkçe küçültme: `İ → i`, `I → ı`, sonra Dart'ın default lower case'i.
String toLowerCaseTr(String input) {
  return input.replaceAll('İ', 'i').replaceAll('I', 'ı').toLowerCase();
}

/// İki metnin Türkçe-aware case-insensitive eşitlik kontrolü.
/// Trim + Türkçe büyütme ile normalize ettikten sonra karşılaştırır.
///
/// Örnek: `eqIgnoreCaseTr('sil', 'SİL')` → `true`.
bool eqIgnoreCaseTr(String a, String b) {
  return toUpperCaseTr(a.trim()) == toUpperCaseTr(b.trim());
}

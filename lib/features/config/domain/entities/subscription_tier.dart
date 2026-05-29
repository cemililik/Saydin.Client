/// Kullanıcının abonelik planı.
///
/// Backend `tier` alanı (`"free"` / `"premium"`) magic-string yerine
/// tip-güvenli enum ile temsil edilir. `switch` exhaustiveness'i yeni plan
/// eklenince derleme-zamanı yakalar; `== 'premium'` gibi sessiz yazım
/// hatalarını eler. Wire (string) ↔ enum dönüşümü **data katmanında**
/// (`AppConfigModel`) yapılır — domain bu enum'u saf tip olarak tutar.
enum SubscriptionTier { free, premium }

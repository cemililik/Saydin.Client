# Finansal domain sistematik review

**Tarih:** 2026-08-18
**Kapsam:** `what_if`, `comparison`, `dca`, `portfolio`; bunların testleri; doğrudan kullanılan para, sayı, tarih, format, hata ve paylaşım yardımcıları; `CLAUDE.md` ve `docs/architecture.md`.
**Review türü:** Salt-okunur, statik ve sözleşme odaklı. Uygulama kodu değiştirilmemiştir.

## Yönetici özeti

Bu inceleme 95 birincil dosya ve 15.910 satırlık kapsamı dosya dosya taradı; buna ek olarak iki ARB dosyası, ilgili konfigürasyon/DI noktaları ve çağrı zincirleri kontrol edildi. Sonuç: **24 gerçek bulgu** — **0 P0, 7 P1, 14 P2, 3 P3**.

En önemli riskler şunlar:

1. Portföyün kısmi başarısızlığı kullanıcıya söylenmeden eksik toplam “portföy toplamı” diye gösteriliyor, kaydediliyor ve paylaşılabiliyor.
2. Dil değişikliği yalnızca metinleri yenilemek yerine finansal hesaplamaları tekrar çalıştırıyor; portföyde 20 isteğe kadar kota tüketebiliyor ve mevcut sonucu sessizce silebiliyor.
3. Portföy hesaplamasında uçuş halindeki istek ile sonradan değişen form state'i birbirine karışabiliyor; eski cevap yeni tarihlerle etiketlenebiliyor.
4. What-If ve DCA'da form değiştirildikten sonra eski sonuç ekranda ve aksiyonlarda geçerli kalıyor.
5. Tarih seçici iptali DCA başlangıç alanında deterministik null-check crash'i üretiyor.
6. Comparison tarih kesişimi yok/eskimiş olduğunda aralık genişleyebiliyor veya `showDatePicker` assertion'ı oluşabiliyor.
7. DCA'nın iki bağımsız nullable enflasyon alanından biri eksikse sonuç kartı crash oluyor.

**Yayın duruşu:** P1 bulguları kapanmadan finansal akışlar “birinci sınıf ve güvenilir” kabul edilmemeli. Özellikle FIN-01, FIN-03 ve FIN-04 kullanıcıya yanlış finansal bağlam sunabildiği için sıradan UI kusuru değildir.

## Yöntem ve doğrulama sınırları

- `CLAUDE.md` (548 satır) ve `docs/architecture.md` (750 satır) tamamen okundu.
- Presentation → domain ← data sınırları, repository/use-case/model eşlemeleri, BLoC state makineleri, tekrar oynatma, dil değişimi, grafik/paylaşım akışları ve testler çapraz izlendi.
- Domain'de Flutter/Dio/IO; presentation'da Dio/HTTP; `print`; hardcoded kullanıcı metni; `num`/`double` finansal değer; `AppColors` kullanımı; `failedItems`; BLoC transformer ve test kapsama taramaları yapıldı.
- TR/EN ARB dosyaları `jq` ile parse edildi; anahtar kümeleri eşit çıktı.
- Planlanan `flutter analyze --fatal-infos` + hedefli `flutter test` komutu ortamda `flutter: command not found` ile ilk adımda durdu. `dart` ve FVM de mevcut değildi. Dolayısıyla aşağıdaki bulgular yüksek güvenli statik kanıta dayanıyor; runtime/regresyon test sonuçları ayrıca CI'da alınmalı.
- BLoC'un varsayılan event işleme semantiği için resmi dokümantasyondaki “events are processed concurrently by default” sözleşmesi esas alındı: [Bloc migration guide](https://bloclibrary.dev/migration/).

### Severity tanımı

| Seviye | Anlam |
|---|---|
| P0 | Veri kaybı/güvenlik/finansal felaket; acil blokaj |
| P1 | Yanlış finansal sonuç veya yüksek etkili crash/race; yayın bloklayıcı |
| P2 | Önemli doğruluk, erişilebilirlik, sözleşme, performans veya kalite açığı |
| P3 | Düşük etkili dayanıklılık, bakım ve doküman borcu |

## Bulgular

### FIN-01 — [P1] Portföy kısmi başarısızlığı eksik toplamı tam sonuç gibi sunuyor

- **Kategori:** Finansal doğruluk, hata semantiği, UX, repository sözleşmesi
- **Kanıt:** `lib/features/portfolio/data/repositories/portfolio_repository_impl.dart:39-73`; `lib/features/portfolio/domain/usecases/calculate_portfolio.dart:37-80`; `lib/features/portfolio/domain/usecases/calculate_portfolio.dart:127-138`; `lib/features/portfolio/domain/entities/portfolio_result.dart:28-43`; `lib/features/portfolio/presentation/pages/portfolio_page.dart:120-153`; `lib/features/portfolio/presentation/pages/portfolio_page.dart:433-467`; `lib/features/portfolio/presentation/widgets/portfolio_result_card.dart:98-278`; `docs/architecture.md:693-696`.
- **Etki/kanıt:** Her kalem hatası `calculation: null`a indirgeniyor; use case toplamı ve yüzdeleri yalnız başarılı kalemlerle hesaplıyor. Entity ve mimari dokümanı `failedItems`'ın UI'da gösterileceğini söylüyor, fakat presentation katmanında `failedItems`/`hasPartialFailure` hiç okunmuyor. Sonuç kartı eksik toplamı koşulsuz gösteriyor; kaydetme akışı ise hesaplanamayanlar dahil tüm `state.items` listesini `extraData`ya yazarken `amount` alanına yalnız başarılı alt kümenin toplamını yazıyor.
- **Tetikleme:** İki kalemli portföyde bir varlık 503, 429, fiyat-bulunamadı veya ağ hatası alsın. Kullanıcı uyarı görmeden yalnız diğer kalemin toplamını “portföy toplamı” sanır; bu tutarı kaydedebilir/paylaşabilir.
- **Öneri:** `PortfolioItemOutcome` içinde typed `AppError` taşı; başarı ekranında açık “N kalem dahil edilmedi” bileşeni, başarısız kalem listesi ve yeniden dene aksiyonu göster. Kaydet/paylaş ya tamamen başarılı sonuca izin vermeli ya da partial niteliğini ve yalnız hesaplanan kalemleri tutarlı biçimde serialize etmeli. `PortfolioResult` için `complete/partial` status'u açık bir domain invariant olsun.
- **Gerekli test:** Bir kalemi başarılı, bir kalemi typed hata olan widget+BLoC testi; kart, kaydetme payload'ı ve share içeriği partial durumunu doğrulamalı.

### FIN-02 — [P1] Dil değişikliği finansal hesapları tekrar çağırıyor, kota tüketiyor ve sonucu silebiliyor

- **Kategori:** State machine, kota, performans, hata UX'i
- **Kanıt:** `lib/app.dart:247-260`; `lib/app.dart:285-295`; `lib/features/what_if/presentation/bloc/what_if_bloc.dart:227-255`; `lib/features/what_if/presentation/bloc/what_if_bloc.dart:335-402`; `lib/features/comparison/presentation/bloc/comparison_bloc.dart:264-333`; `lib/features/portfolio/presentation/bloc/portfolio_bloc.dart:277-342`; `lib/features/dca/presentation/bloc/dca_bloc.dart:200-241`; `lib/features/portfolio/presentation/pages/portfolio_page.dart:355-377`; `lib/features/config/domain/entities/app_config.dart:26-30`.
- **Etki/kanıt:** Tek bir ayar değişikliği dört BLoC'a event yollar. Önceki sonuç varsa her BLoC yeniden hesaplar; portföy bunu kalem başına paralel çağrıya dönüştürür. Ürün kendi UI'ında her kalemin kota tükettiğini söylüyor ve free varsayılan limit 20. Hesaplama hataları `catch` içinde kullanıcıya bildirilmeden editing/assets-loaded state'ine dönüyor ve önceki sonuç kayboluyor. Normal What-If hesabı ayrıca event tutarını `formInput.amount`a hiç yazmadığı için (`:227-255`) dil handler'ındaki `amount != null` guard'ı (`:347-353`) çoğu manuel sonuçta başarısız olur ve sonuç doğrudan silinir.
- **Tetikleme:** 20 kalemli portföy sonucu açıkken TR→EN geçişi; 20 ek hesap isteği. Bir tanesi bile başarısızsa mevcut sonuç sessizce editing state'ine düşebilir. Normal What-If sonucu ise dil değişiminde tekrar hesaplanmadan kaybolur.
- **Öneri:** Dil değişikliğini yalnız asset `displayName` kataloğunu ve formatter locale'ini yenileyen yerel bir projection yap. Finansal sonucu tekrar çağırma. Asset kataloğunu locale anahtarlı tek shared cache/single-flight olarak tut. Zorunlu re-fetch hata verirse mevcut sonucu koru ve non-blocking uyarı göster. What-If form tutarını da hesap event'iyle immutable request snapshot'ına yaz.
- **Gerekli test:** Dil değişiminde calculate use case'lerin `never` çağrıldığını, sonucun korunduğunu ve asset adlarının yeni katalogdan eşlendiğini doğrulayan dört BLoC testi.

### FIN-03 — [P1] Portföy hesaplama cevabı farklı bir form snapshot'ıyla etiketlenebiliyor

- **Kategori:** BLoC concurrency, race condition, finansal doğruluk
- **Kanıt:** `lib/features/portfolio/presentation/bloc/portfolio_bloc.dart:19-35`; `lib/features/portfolio/presentation/bloc/portfolio_bloc.dart:94-121`; `lib/features/portfolio/presentation/bloc/portfolio_bloc.dart:189-220`; `lib/features/portfolio/presentation/bloc/portfolio_bloc.dart:240-252`; `lib/features/portfolio/presentation/pages/portfolio_page.dart:262-309`.
- **Etki/kanıt:** Handler hesaplamayı başlatırken bir snapshot emit ediyor, fakat `await` sonrasında `PortfolioSuccess` alanlarını yakalanmış request'ten değil o andaki mutable `state`ten okuyor. Tarih ve enflasyon kontrolleri calculating sırasında etkin kalıyor; bu event'ler state'i `PortfolioEditing`e çeviriyor. Bloc event handler'ları varsayılan olarak concurrent çalıştığı için ilk istek eski parametrelerle hesaplanıp yeni tarih/enflasyon değerleriyle etiketlenebilir. Editing state ayrıca ikinci bir calculate'ı açar; geç tamamlanan eski istek yeni sonucu ezebilir.
- **Tetikleme:** Hesapla'ya bas; cevap gelmeden alış tarihini veya enflasyon toggle'ını değiştir; yeniden hesapla. Ağ sırası ters dönerse UI'daki tarih ile toplam aynı request'e ait değildir.
- **Öneri:** Hesap başında tüm girdileri immutable `PortfolioRequestSnapshot` içine al. Monotonik request id kullanıp stale cevapları düşür veya `restartable()` transformer uygula. Hesap boyunca tüm girişleri kilitlemek ek savunma olabilir ama tek başına stale response çözümü değildir. `buyDate!` invariant'ını page'e değil BLoC/use-case doğrulamasına taşı.
- **Gerekli test:** İki `Completer` ile cevapları ters sırada tamamlayan BLoC testi; ilk cevabın emit edilmediğini ve success alanlarının request snapshot'ıyla birebir olduğunu doğrula.

### FIN-04 — [P1] What-If ve DCA form değişikliğinde eski sonuç geçerli kalıyor

- **Kategori:** State machine, UX doğruluğu, senaryo bütünlüğü
- **Kanıt:** `lib/features/what_if/presentation/bloc/what_if_state.dart:130-149`; `lib/features/what_if/presentation/bloc/what_if_bloc.dart:170-183`; `lib/features/what_if/presentation/pages/what_if_page.dart:184-235`; `lib/features/what_if/presentation/pages/what_if_page.dart:287-320`; `lib/features/dca/presentation/bloc/dca_state.dart:104-121`; `lib/features/dca/presentation/bloc/dca_bloc.dart:75-109`; `lib/features/dca/presentation/pages/dca_page.dart:196-210`; `lib/features/dca/presentation/pages/dca_page.dart:341-418`.
- **Etki/kanıt:** İki `Success.copyWith` de sonucu koruyor; form mutasyon handler'ları Success state'ini Success olarak yeniden emit ediyor. Böylece kullanıcı varlık/tarih/periyot/tutar türü/enflasyonu değiştirse eski kart ve save/share aksiyonları kalıyor. What-If kaydetme özellikle sonuçtan sembol/tarih, güncel controller'dan tutar ve güncel formdan amountType/enflasyon alarak tek senaryoda iki farklı snapshot'ı karıştırıyor. DCA kaydı sonuç değerlerini kullanırken güncel `includeInflation` flag'ini extraData'ya yazar.
- **Tetikleme:** BTC için hesapla; sonra USD seç veya tutarı/tarihi değiştir; tekrar hesaplamadan Kaydet/Paylaş. Görsel sonuç eski, form ve serialize edilen metadata yeni olabilir.
- **Öneri:** Her form mutasyonunda `Editing/Dirty` state'ine geçip sonucu temizle veya sonucu ayrı tutsa bile `isDirty` ile kartı ve aksiyonları devre dışı bırak. Sonuç/request snapshot'ını tek entity olarak taşı; save/share yalnız o snapshot'tan üretilsin. Amount controller değişimini de BLoC'a debounce'lu event olarak aktar.
- **Gerekli test:** Her form alanı için Success→Editing geçişi ve save/share disabled widget testi.

### FIN-05 — [P1] Tarih seçiciyi iptal etmek DCA başlangıç alanında uygulamayı düşürüyor

- **Kategori:** Crash, null safety, ortak widget sözleşmesi
- **Kanıt:** `lib/features/what_if/presentation/widgets/date_input.dart:89-104`; `lib/features/dca/presentation/pages/dca_page.dart:233-240`.
- **Etki/kanıt:** `showDatePicker` Cancel/back halinde `null` döndürür. `DateInput` bunu ayrım yapmadan `onChanged(null)` ile iletir; DCA başlangıç callback'i `v!` dereference eder. Bu normal kullanıcı aksiyonunda deterministik null-check exception'dır.
- **Tetikleme:** DCA başlangıç tarihi alanını aç ve Cancel'a veya sistem geri tuşuna bas.
- **Öneri:** Picker iptalini değişiklik değil no-op say: `if (picked != null) onChanged(picked)`. Opsiyonel alanı temizleme yalnız suffix clear üzerinden açık aksiyon kalsın. DCA callback'indeki `!` kaldırılmalı ve required invariant BLoC'ta da korunmalı.
- **Gerekli test:** Tarih dialog'unu açıp Cancel yapan widget testi; callback'in çağrılmadığını ve exception olmadığını doğrula.

### FIN-06 — [P1] Comparison tarih kesişimi durumu kayboluyor; yanlış aralık ve picker assertion'ı mümkün

- **Kategori:** Tarih sınırları, crash, finansal doğruluk
- **Kanıt:** `lib/core/utils/date_range_utils.dart:39-53`; `lib/core/utils/date_range_utils.dart:80-103`; `lib/features/comparison/presentation/bloc/comparison_bloc.dart:92-107`; `lib/features/comparison/presentation/pages/comparison_page.dart:247-288`; `lib/features/what_if/presentation/widgets/date_input.dart:68-73`; `lib/features/what_if/presentation/widgets/date_input.dart:89-103`.
- **Etki/kanıt:** Helper örtüşme yokluğunu `(null, null)` ile kodluyor ve caller'ın input'u disable/mesaj göstermesini açıkça şart koşuyor. Page ise null sınırları `DateInput`a geçiriyor; widget bunları 2010/bugün varsayılanlarına çevirerek aslında geçersiz karşılaştırmayı geniş bir aralık gibi gösteriyor. Sembol değişiminde mevcut tarihler clamp/reset edilmiyor. Yeni ortak `lastDate`, eski `buyDate`ten önceyse satış picker'ı `firstDate > lastDate` ile `showDatePicker` assertion'ına gider.
- **Tetikleme:** Ortak fiyat geçmişi olmayan iki varlık seç; veya 2024 alış tarihi seçiliyken yalnız 2022'ye kadar verisi olan bir varlığı karşılaştırmaya ekle ve satış tarihini aç.
- **Öneri:** Nullable ikili yerine `ValidRange` / `NoOverlap` sealed sonucu kullan. `NoOverlap`ta tarih alanları ve hesap butonu disable edilmeli, lokalize neden gösterilmeli. Sembol değişiminde buy/sell atomik clamp/reset edilmeli. `DateInput` her durumda `first <= last` guard'ı sağlamalı.
- **Gerekli test:** Örtüşmesiz varlıklar, eski seçimin yeni kesişim dışında kalması ve `firstDate > lastDate` widget testleri.

### FIN-07 — [P1] DCA enflasyon alanlarının ayrık null olması sonuç kartını düşürüyor

- **Kategori:** API model mapping, crash, nullable contract
- **Kanıt:** `lib/features/dca/data/models/dca_response_model.dart:124-130`; `lib/features/dca/presentation/widgets/dca_result_card.dart:210-229`; `lib/features/what_if/presentation/widgets/result_card.dart:263-287`; `test/features/what_if/presentation/widgets/result_card_test.dart:47-65`.
- **Etki/kanıt:** Model `cumulativeInflationPercent` ve `realProfitLossPercent` alanlarını bağımsız nullable parse ediyor. UI bölümü yalnız `realProfitLossPercent != null` ile açıp `cumulativeInflationPercent!` kullanıyor. What-If kartında aynı kontrat doğru biçimde bağımsız null-check ile ele alınmış ve buna özel regresyon testi var; DCA eşleniği yok.
- **Tetikleme:** Backend 2xx yanıtta `realProfitLossPercent` gönderip `cumulativeInflationPercent` alanını null/eksik bıraksın.
- **Öneri:** Ya iki alanı model sınırında birlikte-zorunlu bir `InflationResult` value object'ine dönüştür, ya da UI'da her alanı bağımsız göster. Force unwrap kaldırılmalı.
- **Gerekli test:** What-If'taki divergent-null test matrisinin DCA kartına aynen eklenmesi.

### FIN-08 — [P2] Kullanıcı finansal girdileri domain ve API'ye `num` olarak taşınıyor

- **Kategori:** Decimal hassasiyeti, clean architecture, API kontratı
- **Kanıt:** `CLAUDE.md:156-171`; `CLAUDE.md:495-501`; `docs/architecture.md:544-565`; `lib/core/utils/locale_number_parser.dart:12-38`; `lib/features/what_if/domain/repositories/what_if_repository.dart:5-21`; `lib/features/comparison/domain/repositories/comparison_repository.dart:3-10`; `lib/features/dca/domain/repositories/dca_repository.dart:3-11`; `lib/features/portfolio/domain/entities/portfolio_item.dart:3-17`; `lib/features/what_if/data/repositories/what_if_repository_impl.dart:41-59`; `lib/features/comparison/data/repositories/comparison_repository_impl.dart:23-40`; `lib/features/dca/data/repositories/dca_repository_impl.dart:20-39`.
- **Etki/kanıt:** Proje standardı para ve birim değerlerinde `num/double`ı açıkça yasaklıyor. Buna rağmen locale parser `NumberFormat.tryParse` ile `num` döndürüyor; tüm finansal request sözleşmeleri ve `PortfolioItem.amount` `num`, JSON payload da doğrudan binary sayı gönderiyor. Sonuç modelleri Decimal olsa da hassasiyet request oluşturulmadan önce kaybedilebilir. Ayrıca What-If/Comparison/DCA girişlerinde portfolio'daki 1 milyar/scale sınırının eşleniği yok.
- **Tetikleme:** Çok ondalıklı birim miktarı, yüksek tutar veya binary'de tam temsil edilemeyen bir değer (`0,1`) girip API request'ini tekrar kaydet/oynat.
- **Öneri:** Locale metnini normalize edip doğrudan `Decimal.parse` et; presentation event, form state, use case ve repository sözleşmelerini Decimal yap. Backend kontratı izin veriyorsa `MoneyParser.toJsonString` ile canonical string gönder. Para/birim için açık max, max scale ve amount-type uyumluluğunu ortak validator'da tanımla.
- **Gerekli test:** TR/EN çok ondalıklı input → Decimal → request JSON round-trip ve limit/scale property testleri.

### FIN-09 — [P2] DCA opsiyonel bitiş tarihi temizlenemiyor

- **Kategori:** State modeli, nullable copyWith
- **Kanıt:** `lib/features/dca/presentation/bloc/dca_state.dart:25-41`; `lib/features/dca/presentation/bloc/dca_bloc.dart:86-88`; `lib/features/what_if/presentation/widgets/date_input.dart:82-86`.
- **Etki/kanıt:** Clear butonu `null` yollar, fakat `DcaFormInput.copyWith` içindeki `endDate ?? this.endDate` eski tarihi geri koyar. UI kullanıcıya temizleme aksiyonu sunar ancak state değişmez; replay de stale değeri null ile silemez.
- **Tetikleme:** DCA bitiş tarihi seç, suffix clear ikonuna bas.
- **Öneri:** What-If/Comparison'daki gibi sentinel tabanlı nullable `copyWith` kullan ve clear davranışını state/widget testiyle sabitle.

### FIN-10 — [P2] Ay bazlı geçmiş limiti ay sonlarında ileri taşıyor

- **Kategori:** Tarih matematiği, plan sınırı
- **Kanıt:** `lib/core/utils/date_range_utils.dart:20-24`; `lib/core/utils/date_range_utils.dart:87-92`; `lib/features/portfolio/presentation/pages/portfolio_page.dart:238-243`.
- **Etki/kanıt:** `DateTime(year, month - N, day)` Dart'ın taşma normalizasyonunu kullanır. Örneğin 31 Mart'tan bir ay çıkarmak Şubat'ın sonu yerine Mart başına taşabilir; gerçek izin verilen pencere birkaç gün daralır/yanlışlaşır. Aynı hata üç yerde tekrarlanıyor.
- **Tetikleme:** `lastDate` ayın 29–31'i ve hedef ay daha kısa olduğunda geçmiş limitini aç.
- **Öneri:** Hedef yıl/ayı hesapla, günü hedef ayın son gününe clamp eden tek `subtractCalendarMonthsClamped` helper'ı kullan. Date-only normalize et.
- **Gerekli test:** 31 Mart−1 ay, artık yılda 29 Şubat, yıl geçişi ve N=0/negatif savunma testleri. Şu an `test/core/utils/date_range_utils_test.dart` yok.

### FIN-11 — [P2] Tarih sırası ve sembol-değişimi invariant'ları akışlar arasında tutarsız

- **Kategori:** Validation, tarih sınırları
- **Kanıt:** `lib/features/what_if/presentation/pages/what_if_page.dart:56-112`; `lib/features/comparison/presentation/pages/comparison_page.dart:54-80`; `lib/features/portfolio/presentation/pages/portfolio_page.dart:180-195`; `lib/features/dca/presentation/pages/dca_page.dart:94-103`; `lib/features/comparison/presentation/bloc/comparison_bloc.dart:92-107`; `lib/features/dca/presentation/bloc/dca_bloc.dart:75-88`; `lib/features/dca/presentation/pages/dca_page.dart:196-210`.
- **Etki/kanıt:** DCA `end < start` durumunu açıkça reddediyor; What-If, Comparison ve Portfolio aynı invariant'ı kontrol etmiyor. Picker satış seçimini alışa göre sınırlandırsa da kullanıcı önce satış seçip sonra alışı ileri taşıyabilir. Comparison ve DCA sembol değişiminde mevcut tarihleri yeni asset aralığına clamp/reset etmiyor; What-If bunu yapıyor.
- **Tetikleme:** Önce satış/bitiş seç, sonra alış/başlangıcı daha ileri tarihe çek; veya dar geçmişli bir varlığa geç.
- **Öneri:** `FinancialDateRangeValidator`ı domain/use-case sınırında ortaklaştır; UI yalnız hızlı geri bildirim versin. Sembol değişiminde tarihleri atomik normalize et ve kullanıcıya date-adjusted mesajı göster.

### FIN-12 — [P2] Portföy tarih seçimi kalemlerin veri aralıklarını hesaba katmıyor

- **Kategori:** Finansal veri bulunabilirliği, tarih UX'i
- **Kanıt:** `lib/features/portfolio/presentation/pages/portfolio_page.dart:238-266`; `lib/features/portfolio/presentation/pages/portfolio_page.dart:291-299`; `lib/features/portfolio/data/repositories/portfolio_repository_impl.dart:39-70`.
- **Etki/kanıt:** Portföy aralığı yalnız “bugün − plan ayı” ile hesaplanıyor. Seçili varlıkların `firstDate/lastDate` kesişimi uygulanmadığı için UI, bazı kalemler için veri olmadığı bilinen tarihi seçilebilir gösteriyor; bu hatalar sonra per-item null'a dönüp FIN-01'deki sessiz eksik toplamı doğuruyor.
- **Tetikleme:** Yeni listelenmiş bir varlık ile uzun geçmişli varlığı aynı portföye ekleyip yeni varlığın başlangıcından önce alış tarihi seç.
- **Öneri:** Portfolio için de çoklu-varlık tarih kesişimi üret; kalem ekleme/çıkarma sonrası tarihleri atomik clamp/reset et. Kesişim yoksa hesaplamayı disable edip hangi varlıkların engel olduğunu göster.

### FIN-13 — [P2] Bozuk 2xx yanıt semantiği repository'ler arasında çelişkili

- **Kategori:** Error semantics, API sözleşmesi, observability
- **Kanıt:** `docs/architecture.md:319-330`; `lib/features/what_if/data/repositories/what_if_repository_impl.dart:25-34`; `test/features/what_if/data/repositories/what_if_repository_impl_test.dart:109-113`; `lib/features/comparison/data/repositories/comparison_repository_impl.dart:43-47`; `test/features/comparison/data/repositories/comparison_repository_impl_test.dart:80-88`.
- **Etki/kanıt:** Mimari 2xx + boş/eksik gövdeyi `MalformedResponseError` olarak tanımlar. What-If asset endpoint'i null/missing listeyi meşru boş listeye çeviriyor; Comparison hesap endpoint'i ise `ServerError(statusCode: 200)` üretiyor. Testler doğru sözleşmeyi korumak yerine iki tutarsız davranışı kodluyor. İzleme ve kullanıcı mesajları gerçek kontrat ihlalini ayırt edemiyor.
- **Tetikleme:** Proxy/backend 200 ve null body veya `assets` anahtarı eksik payload dönsün.
- **Öneri:** Ortak response-body validator ile tüm 2xx sözleşme ihlallerini `MalformedResponseError`a eşle. Meşru boş liste ile eksik alanı ayır. Mevcut test beklentilerini yeni kanonik semantiğe çevir.

### FIN-14 — [P2] Portföy hata tiplerini ve per-item nedeni kaybediyor

- **Kategori:** Repository/use-case kontratı, hata raporlama
- **Kanıt:** `lib/features/portfolio/domain/entities/portfolio_calculation.dart:46-60`; `lib/features/portfolio/data/repositories/portfolio_repository_impl.dart:54-70`; `lib/features/portfolio/domain/usecases/calculate_portfolio.dart:43-46`; `lib/features/portfolio/domain/usecases/calculate_portfolio.dart:142-149`; `lib/features/portfolio/presentation/bloc/portfolio_bloc.dart:222-235`.
- **Etki/kanıt:** `PortfolioItemOutcome` başarısızlık nedenini taşıyamıyor. NoInternet, DailyLimit, FeatureDisabled ve PriceNotFound aynı `calculation:null` oluyor. Tümü başarısızsa use case hardcoded Türkçe `Exception` atıyor; BLoC bunu `UnknownError` yapıp beklenen iş hatasını Sentry'ye gönderiyor. Partial durumda UI hangi kalemin neden ve ne zaman tekrar denenebileceğini bilemez.
- **Tetikleme:** Tüm kalemlerde günlük limit veya bağlantı hatası; kullanıcı generic bilinmeyen hata görür ve telemetri gürültüsü oluşur.
- **Öneri:** Outcome'u `Success(calculation)` / `Failure(AppError)` sealed tipine çevir. All-failed için hata öncelik politikası tanımla (örn. ortak DailyLimit doğrudan yüzeye çıkar); mixed durumda per-item lokalize neden ve retry policy taşı.

### FIN-15 — [P2] Eksik `isProfit` alanı sessizce “zarar”a çevriliyor

- **Kategori:** API model mapping, finansal semantik
- **Kanıt:** `lib/features/what_if/data/models/reverse_what_if_response_model.dart:70-75`; `lib/features/dca/data/models/dca_response_model.dart:107-112`; `lib/features/dca/presentation/widgets/dca_result_card.dart:98-100`; `lib/features/what_if/presentation/widgets/reverse_result_card.dart:141-142`.
- **Etki/kanıt:** Reverse ve DCA modelleri required finansal yön alanı eksik/yanlış tipteyse `false` varsayıyor. Pozitif `profitLossTry` ve yüzde ile kırmızı “zarar” ikonu/metni aynı kartta birlikte görünebilir; kontrat bozulması yakalanmaz. Normal What-If parsing'i daha sıkıdır.
- **Tetikleme:** Backend deploy'unda `isProfit` alanı eksik veya string gelsin.
- **Öneri:** Bool'u required parse et ve bozuk payload'ı `FormatException`/`MalformedResponseError`a dönüştür. Daha güçlü seçenek: `isProfit`i `profitLossTry >= 0`dan domain'de türet ve API alanı varsa tutarlılık doğrulaması yap.

### FIN-16 — [P2] Dark-mode için tanımlanan finansal renk helper'ları ekranlarda kullanılmıyor

- **Kategori:** Tema, erişilebilirlik, görsel kontrat
- **Kanıt:** `lib/core/constants/app_colors.dart:9-19`; `docs/architecture.md:599-612`; `lib/features/what_if/presentation/widgets/result_card.dart:147-148`; `lib/features/what_if/presentation/widgets/result_chart.dart:80-82`; `lib/features/comparison/presentation/widgets/comparison_result_card.dart:60-72`; `lib/features/dca/presentation/widgets/dca_result_card.dart:98-100`; `lib/features/dca/presentation/widgets/dca_chart.dart:22-24`; `lib/features/portfolio/presentation/widgets/portfolio_result_card.dart:81-85`; `lib/features/portfolio/presentation/widgets/portfolio_result_card.dart:230-232`.
- **Etki/kanıt:** Mimari dark tema için açık tonları ve `profitColor(brightness)`/`lossColor(brightness)` helper'larını şart koşuyor. Ekrandaki sonuçlar ve grafikler doğrudan light sabitlerini kullanıyor; helper'ların feature presentation'da çağrısı yok. Bu, dark surface üzerinde hedeflenen kontrastı ve tasarım tutarlılığını bozuyor. Beyaz arka planlı sabit share-card renkleri bu bulguya dahil değildir.
- **Tetikleme:** Sistem temasını dark yapıp dört finansal sonuç kartını/grafiğini aç.
- **Öneri:** `ThemeExtension` veya tek semantic color accessor üzerinden brightness-aware renk kullan. Light/dark ve high-text-scale golden/contrast testleri ekle; ikon+metin sinyali korunmalı.

### FIN-17 — [P2] Finansal grafiklerin screen-reader ve klavye/switch alternatifi yok

- **Kategori:** Erişilebilirlik, chart UX
- **Kanıt:** `lib/features/what_if/presentation/widgets/result_chart.dart:40-63`; `lib/features/what_if/presentation/widgets/result_chart.dart:118-203`; `lib/features/dca/presentation/widgets/dca_chart.dart:55-140`.
- **Etki/kanıt:** What-If range analizi yalnız uzun basış+sürükleme ile kullanılabiliyor; fl_chart canvas'ı için Semantics özeti veya alternatif veri görünümü yok. DCA grafiğinde cost/value ayrımı legend ve renk/stille görsel; tooltip değerleri metinsel seri etiketi taşımıyor. Screen reader/switch-control kullanıcısı tarih-fiyat noktalarını veya aralık değişimini alamaz.
- **Tetikleme:** TalkBack/VoiceOver açıkken grafiğe odaklan veya pointer olmadan range analizi yapmaya çalış.
- **Öneri:** Grafiğe lokalize summary Semantics ekle; erişilebilir “veri tablosunu göster” alternatifi ve range başlangıç/bitiş kontrolleri sun. Tooltip metninde seri adını yaz; yalnız renk/gesture'a bilgi bağlama.
- **Gerekli test:** SemanticsTester ile başlık, başlangıç/son değer, trend ve aksiyonların okunabilir olduğunu doğrula.

### FIN-18 — [P2] Kaydedilmiş senaryo replay'i güncel domain invariant'larını atlıyor

- **Kategori:** Validation, migration, güvenli deserialize
- **Kanıt:** `lib/app.dart:145-238`; `lib/features/portfolio/presentation/bloc/portfolio_bloc.dart:259-274`; `lib/features/dca/presentation/widgets/period_selector.dart:14-25`; `lib/core/widgets/inflation_toggle.dart:18-31`; `lib/features/portfolio/domain/portfolio_constants.dart:7-14`.
- **Etki/kanıt:** Comparison sembolleri virgülden parçalanıp 2–5/ad geçerliliği kontrol edilmeden hesaplanıyor. Portfolio item'larında yalnız runtime tipleri kontrol ediliyor; pozitiflik, max tutar, amountType, duplicate, varlık kataloğu ve 20-item sınırı uygulanmıyor; BLoC replay listesine doğrudan güveniyor. DCA `period` serbest string; geçersiz seçim `SegmentedButton.selected` sözleşmesini bozar. Feature flag enflasyonu kapalıyken toggle görsel olarak false olsa bile replay state'i true taşıyıp backend'e gönderebilir.
- **Tetikleme:** Eski/bozuk/server tarafından değiştirilmiş senaryoda `period: daily`, 21 item, negatif amount veya kapalı inflation flag'i.
- **Öneri:** Scenario payload'ını version'lı DTO→typed command mapper'da parse et. Tüm normal form invariant'larını replay'de de aynı domain validator ile uygula; enum kullan, migration/default politikası ve kullanıcıya “senaryo güncellendi/oynatılamadı” sonucu ver.

### FIN-19 — [P2] Aynı asset kataloğu ilk açılışta ve dil değişiminde dört kez çekiliyor

- **Kategori:** Performans, ağ verimliliği, hata yüzeyi
- **Kanıt:** `lib/app.dart:285-295`; `lib/features/what_if/presentation/pages/what_if_page.dart:43-47`; `lib/features/comparison/presentation/pages/comparison_page.dart:41-45`; `lib/features/portfolio/presentation/pages/portfolio_page.dart:37-41`; `lib/features/dca/presentation/pages/dca_page.dart:39-43`; `lib/core/di/injection.dart:141-148`; `lib/app.dart:254-260`.
- **Etki/kanıt:** `IndexedStack` dört sayfayı birlikte oluşturuyor ve her `initState` aynı `GetAssets`i çağırıyor. Repository lazy singleton olsa da katalog cache/single-flight yok. Başlangıçta dört aynı GET; dil değişiminde dört daha oluşuyor. Bu gecikme, radyo/pil kullanımı, backend yükü ve dört bağımsız hata state'i yaratıyor.
- **Tetikleme:** Uygulamayı soğuk başlat veya dili değiştir; ağ kaydında aynı endpoint için dört paralel çağrı görülür.
- **Öneri:** Locale anahtarlı shared `AssetCatalogRepository/Bloc` ve in-flight deduplication ekle. IndexedStack çocukları aynı state'i okusun; explicit refresh yalnız bir çağrı yapsın.

### FIN-20 — [P2] Maksimum portföy paylaşım kartı küçük ekranlarda taşma/okunamazlık riski taşıyor

- **Kategori:** Share rendering, responsive layout
- **Kanıt:** `lib/features/portfolio/domain/portfolio_constants.dart:7-14`; `lib/features/portfolio/presentation/widgets/portfolio_share_card_widget.dart:119-153`; `lib/core/widgets/share_preview_sheet.dart:58-123`.
- **Etki/kanıt:** Portföy 20 kaleme izin veriyor ve share kartı tüm kalemleri sınırsız `Text` satırlarıyla yayıyor. Preview sheet scroll olmayan `Column`; genişliği `FittedBox` ile küçültüyor ama yüksekliği constraint etmiyor. Küçük/landscape ekran, uzun lokalize varlık adı veya büyük text scale'de overflow ya da aşırı küçük okunamaz önizleme oluşabilir.
- **Tetikleme:** 20 uzun adlı varlık, 320–360dp genişlik, landscape veya yüksek erişilebilirlik font ölçeğiyle paylaşım önizlemesini aç.
- **Öneri:** Share özetinde ilk N kalem + “+N daha” kullan; adları `Expanded`, `maxLines`, ellipsis ile sınırla. Sheet'i yüksekliğe constrained scrollable yap; capture widget'ının sabit ve test edilmiş boyutu ayrı kalsın.
- **Gerekli test:** 20 item, uzun TR/EN isim, küçük viewport ve textScale golden/overflow testleri.

### FIN-21 — [P2] En riskli state-machine ve widget dalları test edilmiyor

- **Kategori:** Test kapsamı, regresyon riski
- **Kanıt:** `test/features/what_if/presentation/bloc/what_if_bloc_test.dart:40-216`; `test/features/comparison/presentation/bloc/comparison_bloc_test.dart:25-53`; `test/features/portfolio/presentation/bloc/portfolio_bloc_test.dart:44-62`; `test/features/dca/presentation/bloc/dca_bloc_test.dart:54-99`; `test/features/what_if/presentation/widgets/result_card_test.dart:47-65`. Ayrıca `test/core/utils/date_range_utils_test.dart` mevcut değildir.
- **Etki/kanıt:** Comparison BLoC testleri yalnız null guard'ları, Portfolio yalnız max item, DCA boş asset/dil null guard'ını kapsıyor. Out-of-order cevap, dil sırasında sonuç koruma, partial-failure UI, DateInput Cancel, DCA clear, comparison no-overlap, replay validation, dark mode, Semantics ve maksimum share render testleri yok. Mevcut What-If divergent-null testi DCA'daki aynı crash'i yakalayacak şekilde genellenmemiş.
- **Tetikleme:** Bu rapordaki race/null/layout bug'larının çoğu normal unit suite'e rağmen merge olabilir.
- **Öneri:** Önce P1'lerin her biri için kırmızı regresyon testi ekle. Async BLoC testlerinde controllable `Completer`; widgetlarda SemanticsTester ve fake clock; share sonuçlarında küçük cihaz golden'ları kullan. CI'da analyze + tüm testler zorunlu gate olmalı.

### FIN-22 — [P3] Açık uçlu sonuçların tarih/süre etiketi saat ilerledikçe değişiyor

- **Kategori:** Zaman determinismi, paylaşım doğruluğu
- **Kanıt:** `lib/core/utils/duration_label.dart:14-17`; `lib/core/utils/duration_label.dart:32-35`; `lib/features/what_if/presentation/widgets/share_card_widget.dart:38-40`; `lib/features/what_if/presentation/widgets/reverse_share_card_widget.dart:29-31`; `lib/features/comparison/presentation/widgets/comparison_share_card_widget.dart:31-33`; `lib/features/portfolio/presentation/widgets/portfolio_share_card_widget.dart:33-35`.
- **Etki/kanıt:** `sellDate == null` olduğunda render anındaki `DateTime.now()` kullanılıyor. Sonuç state'i gece yarısını geçerse veya günlerce açık kalırsa gösterilen bitiş tarihi/süre değişir ama finansal değerler eski response snapshot'ına aittir.
- **Tetikleme:** Açık uçlu sonuç al, uygulamayı arka planda bir gün tut, sonra kartı paylaş.
- **Öneri:** Response/request snapshot'ında `effectiveSellDate` veya `calculatedAt` sakla ve tüm render'larda onu kullan. Clock dependency'sini testlerde enjekte et.

### FIN-23 — [P3] 1080px paylaşım görselinin native kaynağı dispose edilmiyor

- **Kategori:** Kaynak yönetimi, performans
- **Kanıt:** `lib/core/utils/share_card_renderer.dart:60-75`; `lib/core/utils/share_card_renderer.dart:77-93`.
- **Etki/kanıt:** `RenderRepaintBoundary.toImage` ile üretilen `ui.Image` PNG'ye çevriliyor fakat `dispose()` edilmiyor. Geçici dosya iyi biçimde silinse de art arda paylaşımlarda yüksek çözünürlüklü native image belleği GC/finalizer'a kadar tutulabilir.
- **Tetikleme:** Aynı oturumda çok sayıda finansal kartı art arda önizleyip paylaş.
- **Öneri:** `toByteData` işlemini `try/finally` içine al ve `image.dispose()` çağır; encoding/file/share hata yollarını da kapsa. Tekrarlı share memory smoke testi ekle.

### FIN-24 — [P3] Mimari dokümanı uygulama ve kendi doküman standardıyla çelişiyor

- **Kategori:** Dokümantasyon, sözleşme drift'i
- **Kanıt:** `CLAUDE.md:523-525`; `CLAUDE.md:540-548`; `docs/architecture.md:97-143`; `docs/architecture.md:147-155`; `docs/architecture.md:524-542`; `docs/architecture.md:693-696`; `lib/features/what_if/presentation/bloc/what_if_bloc.dart:227-255`; `lib/features/portfolio/presentation/widgets/portfolio_result_card.dart:98-278`.
- **Etki/kanıt:** CLAUDE diyagramlarda ASCII'yi yasaklarken state makinesi ASCII code block. Doküman `amount`ın form state'inde taşındığını anlatıyor fakat normal What-If calculate bunu yazmıyor. Portföy partial-success'in gösterildiğini söylüyor fakat UI göstermiyor. Sonuç gösterimi bölümü fixed `tr_TR` örnekleri ve doğrudan renkler verirken uygulama artık aktif locale/AppFormat ve dark-mode helper standardına sahip.
- **Tetikleme:** Yeni geliştirici dokümanı referans alarak state veya sonuç UI'ı eklesin; mevcut hatalı pattern'i çoğaltabilir.
- **Öneri:** State diyagramlarını Mermaid'e dönüştür; documented invariant'ları executable testlerle eşleştir; locale/theme/partial davranışını gerçek hedef sözleşmeye göre güncelle. Doküman değişiklikleri ilgili kod düzeltmesiyle aynı PR'da olmalı.

## Temiz çıkan ve korunması gereken noktalar

- **Clean Architecture sınırları:** Finansal domain klasörlerinde Flutter, Dio, HTTP veya `dart:io` import'u yok; presentation katmanında Dio/HTTP client yok. Portfolio domain'i `WhatIfResult`a bağlı değil; mapping data katmanında izole.
- **Sonuç parası:** What-If, reverse, DCA ve portfolio sonuç entity/model alanlarında para ve birimler `Decimal`; JSON parse'ı `MoneyParser.requireDecimal` üzerinden. `test/features/portfolio/domain/usecases/calculate_portfolio_test.dart:74-96` exact `0.1 + 0.2 == 0.3` aggregasyonunu kapsıyor.
- **Typed hata omurgası:** Standart repository çağrıları `DioException`ı `AppError`a map ediyor; BLoC state'leri string yerine typed error taşıyor ve lokalizasyon UI sınırında yapılıyor. FIN-13/14 bu iyi omurgadaki iki lokal sapmadır.
- **Comparison stale-request savunması:** Normal calculate akışında request sequence ve form mutasyon invalidation uygulanmış (`lib/features/comparison/presentation/bloc/comparison_bloc.dart:14-19`, `:39-41`, `:171-210`). Bu pattern diğer finansal BLoC'lara taşınmaya uygundur.
- **What-If sembol değişimi:** Amount type ve asset tarihleri clamp ediliyor; `dateAdjusted` ile kullanıcıya bildirim altyapısı var (`lib/features/what_if/presentation/bloc/what_if_bloc.dart:85-126`).
- **DCA ters tarih kontrolü:** `endDate < startDate` UI'da açıkça reddediliyor (`lib/features/dca/presentation/pages/dca_page.dart:94-103`).
- **Paylaşım gizliliği:** Renderer typed exception üretir, paylaşım sonrası temp PNG'yi `finally` ile siler ve stale/LRU cleanup uygular (`lib/core/utils/share_card_renderer.dart:43-150`). FIN-23 yalnız native image yaşam süresiyle ilgilidir.
- **L10n:** TR/EN ARB JSON dosyaları geçerli ve anahtar kümeleri eşit. Finansal feature presentation taramasında bariz hardcoded kullanıcı metni bulunmadı.
- **Erişilebilir kar/zarar:** Sonuç özetlerinin çoğu rengi ikon/metinle destekliyor; örneğin portfolio item dökümü `trending_up/down` kullanıyor (`lib/features/portfolio/presentation/widgets/portfolio_result_card.dart:257-273`).
- **DI yaşam süreleri:** Repository/use-case'ler lazy singleton, BLoC'lar factory olarak kayıtlı (`lib/core/di/injection.dart:139-177`).
- **Test kütüphanesi:** İncelenen finansal testlerde Mocktail/bloc_test standardı korunuyor; Mockito bağımlılığı saptanmadı.
- **Grafik flat-series kontrolü:** Kullanılan fl_chart 0.70.2'nin chart transform kodu `deltaY == 0` durumunu işler; yalnız sabit seriden crash iddiası bu nedenle bulgu yapılmadı.

## Önerilen iyileştirme sırası

1. **Yanlış sonuç sınırı:** FIN-01, FIN-03, FIN-04 için request snapshot + result completeness/dirty modeli kur.
2. **Crash paketi:** FIN-05, FIN-06, FIN-07'yi kırmızı widget testleriyle kapat.
3. **Dil ve ağ mimarisi:** FIN-02 ve FIN-19'u ortak asset catalog/cache ile birlikte çöz.
4. **Finansal sözleşme:** FIN-08, FIN-11, FIN-12, FIN-13, FIN-14, FIN-15 ve FIN-18 için ortak typed validator/DTO/error politikası oluştur.
5. **Deneyim kalitesi:** FIN-16, FIN-17 ve FIN-20 için dark-mode, Semantics ve maksimum içerik QA matrisi çalıştır.
6. **Kalite kapısı:** FIN-21 testlerini ekle; Flutter bulunan CI'da `flutter analyze --fatal-infos` ve tüm `flutter test` suite'ini zorunlu hale getir.
7. **Bakım:** FIN-22–24'ü sonuç snapshot'ı, resource disposal ve doküman senkronizasyonuyla tamamla.

## Kabul kriterleri

- Her hesaplanan/kaydedilen/paylaşılan sonuç, kendisini üreten immutable request snapshot'ına bağlanmalı.
- Partial sonuç kullanıcı onayı ve açık kapsam bilgisi olmadan “toplam” diye sunulmamalı.
- Dil/tema değişikliği finansal hesap veya kota tüketmemeli.
- Tüm finansal input/request değerleri Decimal veya kayıpsız canonical string olmalı.
- Tarih invariant'ları page'e güvenmeden domain/BLoC sınırında doğrulanmalı.
- Beklenen API/domain hataları `UnknownError`a düşmemeli; bozuk 2xx tek semantiğe sahip olmalı.
- Screen reader, dark theme, büyük metin, küçük ekran ve maksimum veri hacmi temel test matrisinde bulunmalı.
- P1 regresyonlarının tamamı deterministik otomatik testle korunmalı.

# Saydın marka kaynakları

Bu dizindeki raster master'lar, 18 Ağustos 2026 tarihli onaylı
`Saydin-Production-Asset-Pack` içindeki **01 / Zaman İzi** kimliğinden birebir
kopyalanmıştır. Native icon/splash master'larına ek olarak yalnız aşağıda
`Runtime` olarak işaretlenen optimize lockup/sembol dosyaları Flutter asset
bundle'ına alınır.

| Dosya | Kaynak SHA-256 |
|---|---|
| `saydin-app-icon-ios-1024.png` | `90bf66438dcd12ecb4bce3693153591723956ed66b02b6ec985e0277ea09fb1b` |
| `saydin-play-store-icon-512.png` | `d95a7b6c4e8118df3da9f21607f4dd9ed55e25600993d6f85d396574ea146219` |
| `saydin-symbol-on-light-1024.png` | `21065f1770a75cba1eb9f75673eb3f5c75ccc8a016b280f7dfbed76eb88ae374` |
| `saydin-symbol-on-dark-1024.png` | `aff8fb51cc371c97d8688f4537247339d41533e694279538f4115159eec5e0ac` |
| `saydin-logo-horizontal-light-h512.png` (Runtime) | `3261604ef7b8c387f54a499f1247c1bdb2459e8c95912b44b3950dd85738686d` |
| `saydin-logo-horizontal-dark-h512.png` (Runtime) | `e59984e1070189c79f09aa9d2829223bcda81878513ed3c05f3b81e10aba90fb` |
| `saydin-symbol-fullcolor-256.png` (Runtime) | `f2efcb46dd1b36801e0a0dd677045872918384e17228d39cb91cb45550beeb9d` |

Renkler: navy `#0B1D34`, teal `#2CB1B8`, off-white `#F5F6F7`.
Platform slotları değiştirilirken `tool/tests/test_brand_assets.py` birlikte
çalıştırılmalı ve gerçek launcher maskesi/cold-start görüntüsü RC kanıtına
eklenmelidir.

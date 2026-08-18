# Review kapsam manifestosu

**Tarih:** 2026-08-18
**İncelenen commit:** `441eda4b5209f7814345eede1cb64438174ca6f2`
**Kanonik envanter:** `git ls-files` çıktısı, **303 tracked dosya**
**Sıralı yol listesi SHA-256:** `d4215ba391e261bedbb1fc5d7f0b7368dd68e91708eefddea9a57f8328967211`

## Amaç ve okuma biçimi

Bu manifestonun amacı “hiçbir şey atlanmadı” iddiasını denetlenebilir hale
getirmektir. Her tracked dosyaya bir **birincil review sahibi** atanmıştır.
İkincil lens sütunu, aynı dosyanın başka bir disiplin tarafından da
çapraz incelendiği alanları gösterir. Birincil sahip sayıları birbirini
dışlar ve toplamları tam olarak 303'tür; raporların kendi kapsam sayıları ise
bilinçli çapraz inceleme nedeniyle daha yüksektir.

| Birincil lens | Dosya |
|---|---:|
| Kalite/tooling ([04](04-quality-engineering-agent-tooling-review.md)) | 38 |
| Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | 114 |
| Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | 74 |
| Finansal domain ([01](01-financial-domain-review.md)) | 77 |
| **Toplam** | **303** |

Kapsam, yalnız kaynak kodunu değil; testleri, bütün tracked platform
konfigürasyonlarını, workflow/agent skill'lerini, dokümanları, lockfile'ları,
ikon/launch asset'lerini ve Gradle wrapper JAR'ını içerir. Binary dosyalarda
“satır review” uygulanamaz: görseller görsel olarak ve boyut/manifest ilişkisiyle,
wrapper JAR ise arşiv bütünlüğü ve sabitlenen dağıtım checksum zinciriyle
incelendi. `.git/**`, generated build/cache çıktıları ve kişisel editor
dosyaları tracked proje girdisi olmadıkları için baseline'a dahil değildir.
GitHub branch/environment/release durumu ise repository dışı fakat teslimat
sözleşmesinin parçası olduğu için [02](02-security-platform-delivery-review.md)
ve [04](04-quality-engineering-agent-tooling-review.md) raporlarında ayrıca
salt-okunur doğrulanmıştır.

## Dosya bazlı kayıt

| Tracked dosya | Birincil lens | İkincil lens | İnceleme biçimi |
|---|---|---|---|
| `.claude/agents/saydin-reviewer.md` | Kalite/tooling ([04](04-quality-engineering-agent-tooling-review.md)) | — | Statik + sözleşme |
| `.claude/skills/bloc-page/SKILL.md` | Kalite/tooling ([04](04-quality-engineering-agent-tooling-review.md)) | — | Statik + sözleşme |
| `.claude/skills/develop-task/SKILL.md` | Kalite/tooling ([04](04-quality-engineering-agent-tooling-review.md)) | — | Statik + sözleşme |
| `.claude/skills/device-deploy/SKILL.md` | Kalite/tooling ([04](04-quality-engineering-agent-tooling-review.md)) | — | Statik + sözleşme |
| `.claude/skills/feature-scaffold/SKILL.md` | Kalite/tooling ([04](04-quality-engineering-agent-tooling-review.md)) | — | Statik + sözleşme |
| `.claude/skills/grill-me/SKILL.md` | Kalite/tooling ([04](04-quality-engineering-agent-tooling-review.md)) | — | Statik + sözleşme |
| `.claude/skills/l10n-add/SKILL.md` | Kalite/tooling ([04](04-quality-engineering-agent-tooling-review.md)) | — | Statik + sözleşme |
| `.claude/skills/master-review/SKILL.md` | Kalite/tooling ([04](04-quality-engineering-agent-tooling-review.md)) | — | Statik + sözleşme |
| `.claude/skills/release/SKILL.md` | Kalite/tooling ([04](04-quality-engineering-agent-tooling-review.md)) | — | Statik + sözleşme |
| `.claude/skills/yasak-check/SKILL.md` | Kalite/tooling ([04](04-quality-engineering-agent-tooling-review.md)) | — | Statik + sözleşme |
| `.coderabbit.yaml` | Kalite/tooling ([04](04-quality-engineering-agent-tooling-review.md)) | — | Statik + sözleşme |
| `.githooks/pre-commit` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Satır bazlı + statik tarama |
| `.github/CODEOWNERS` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Kalite/release | Satır bazlı + statik tarama |
| `.github/dependabot.yml` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Kalite/release | Statik + sözleşme |
| `.github/pull_request_template.md` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Kalite/release | Statik + sözleşme |
| `.github/workflows/ci.yml` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Kalite/release | Statik + sözleşme |
| `.github/workflows/release.yml` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Kalite/release | Statik + sözleşme |
| `.gitignore` | Kalite/tooling ([04](04-quality-engineering-agent-tooling-review.md)) | — | Satır bazlı + statik tarama |
| `.metadata` | Kalite/tooling ([04](04-quality-engineering-agent-tooling-review.md)) | — | Satır bazlı + statik tarama |
| `.sourcery.yaml` | Kalite/tooling ([04](04-quality-engineering-agent-tooling-review.md)) | — | Statik + sözleşme |
| `CLAUDE.md` | Kalite/tooling ([04](04-quality-engineering-agent-tooling-review.md)) | Kalite/docs | Statik + sözleşme |
| `README.md` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | Kalite/docs | Statik + sözleşme |
| `analysis_options.yaml` | Kalite/tooling ([04](04-quality-engineering-agent-tooling-review.md)) | — | Statik + sözleşme |
| `android/.gitignore` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Satır bazlı + statik tarama |
| `android/app/build.gradle.kts` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Statik + sözleşme |
| `android/app/proguard-rules.pro` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Satır bazlı + statik tarama |
| `android/app/src/debug/AndroidManifest.xml` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Ürün/asset | Statik + sözleşme |
| `android/app/src/debug/res/xml/network_security_config.xml` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Ürün/asset | Statik + sözleşme |
| `android/app/src/main/AndroidManifest.xml` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Ürün/asset | Statik + sözleşme |
| `android/app/src/main/kotlin/com/saydin/saydin/MainActivity.kt` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Satır bazlı + statik tarama |
| `android/app/src/main/res/drawable-v21/launch_background.xml` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Ürün/asset | Statik + sözleşme |
| `android/app/src/main/res/drawable/launch_background.xml` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Ürün/asset | Statik + sözleşme |
| `android/app/src/main/res/mipmap-hdpi/ic_launcher.png` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Ürün/asset | Görsel + boyut/metadata |
| `android/app/src/main/res/mipmap-mdpi/ic_launcher.png` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Ürün/asset | Görsel + boyut/metadata |
| `android/app/src/main/res/mipmap-xhdpi/ic_launcher.png` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Ürün/asset | Görsel + boyut/metadata |
| `android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Ürün/asset | Görsel + boyut/metadata |
| `android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Ürün/asset | Görsel + boyut/metadata |
| `android/app/src/main/res/values-night/styles.xml` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Ürün/asset | Statik + sözleşme |
| `android/app/src/main/res/values/styles.xml` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Ürün/asset | Statik + sözleşme |
| `android/app/src/main/res/xml/backup_rules.xml` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Ürün/asset | Statik + sözleşme |
| `android/app/src/main/res/xml/data_extraction_rules.xml` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Ürün/asset | Statik + sözleşme |
| `android/app/src/main/res/xml/network_security_config.xml` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Ürün/asset | Statik + sözleşme |
| `android/app/src/profile/AndroidManifest.xml` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Ürün/asset | Statik + sözleşme |
| `android/build.gradle.kts` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Statik + sözleşme |
| `android/gradle.properties` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Statik + sözleşme |
| `android/gradle/wrapper/gradle-wrapper.jar` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Bütünlük + metadata |
| `android/gradle/wrapper/gradle-wrapper.properties` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Bağımlılık/bütünlük |
| `android/gradlew` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Statik + sözleşme |
| `android/gradlew.bat` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Satır bazlı + statik tarama |
| `android/key.properties.example` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Satır bazlı + statik tarama |
| `android/settings.gradle.kts` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Statik + sözleşme |
| `docs/android-toolchain-migration-plan.md` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | Kalite/docs | Statik + sözleşme |
| `docs/architecture.md` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | Kalite/docs | Statik + sözleşme |
| `docs/development-guide.md` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | Kalite/docs | Statik + sözleşme |
| `ios/.gitignore` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Satır bazlı + statik tarama |
| `ios/ExportOptions.plist` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Ürün/asset | Statik + sözleşme |
| `ios/Flutter/AppFrameworkInfo.plist` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Ürün/asset | Statik + sözleşme |
| `ios/Flutter/Debug.xcconfig` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Statik + sözleşme |
| `ios/Flutter/Release.xcconfig` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Statik + sözleşme |
| `ios/Podfile` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Statik + sözleşme |
| `ios/Podfile.lock` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Bağımlılık/bütünlük |
| `ios/Runner.xcodeproj/project.pbxproj` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Statik + sözleşme |
| `ios/Runner.xcodeproj/project.xcworkspace/contents.xcworkspacedata` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Satır bazlı + statik tarama |
| `ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Ürün/asset | Statik + sözleşme |
| `ios/Runner.xcodeproj/project.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Satır bazlı + statik tarama |
| `ios/Runner.xcodeproj/xcshareddata/xcschemes/Runner.xcscheme` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Statik + sözleşme |
| `ios/Runner.xcworkspace/contents.xcworkspacedata` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Satır bazlı + statik tarama |
| `ios/Runner.xcworkspace/xcshareddata/IDEWorkspaceChecks.plist` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Ürün/asset | Statik + sözleşme |
| `ios/Runner.xcworkspace/xcshareddata/WorkspaceSettings.xcsettings` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Satır bazlı + statik tarama |
| `ios/Runner/AppDelegate.swift` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Satır bazlı + statik tarama |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Contents.json` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Ürün/asset | Statik + sözleşme |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Ürün/asset | Görsel + boyut/metadata |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@1x.png` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Ürün/asset | Görsel + boyut/metadata |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@2x.png` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Ürün/asset | Görsel + boyut/metadata |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Ürün/asset | Görsel + boyut/metadata |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@1x.png` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Ürün/asset | Görsel + boyut/metadata |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@2x.png` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Ürün/asset | Görsel + boyut/metadata |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-29x29@3x.png` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Ürün/asset | Görsel + boyut/metadata |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@1x.png` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Ürün/asset | Görsel + boyut/metadata |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@2x.png` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Ürün/asset | Görsel + boyut/metadata |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-40x40@3x.png` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Ürün/asset | Görsel + boyut/metadata |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@2x.png` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Ürün/asset | Görsel + boyut/metadata |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Ürün/asset | Görsel + boyut/metadata |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@1x.png` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Ürün/asset | Görsel + boyut/metadata |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-76x76@2x.png` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Ürün/asset | Görsel + boyut/metadata |
| `ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-83.5x83.5@2x.png` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Ürün/asset | Görsel + boyut/metadata |
| `ios/Runner/Assets.xcassets/LaunchImage.imageset/Contents.json` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Ürün/asset | Statik + sözleşme |
| `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage.png` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Ürün/asset | Görsel + boyut/metadata |
| `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@2x.png` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Ürün/asset | Görsel + boyut/metadata |
| `ios/Runner/Assets.xcassets/LaunchImage.imageset/LaunchImage@3x.png` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Ürün/asset | Görsel + boyut/metadata |
| `ios/Runner/Assets.xcassets/LaunchImage.imageset/README.md` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Statik + sözleşme |
| `ios/Runner/Base.lproj/LaunchScreen.storyboard` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Satır bazlı + statik tarama |
| `ios/Runner/Base.lproj/Main.storyboard` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Satır bazlı + statik tarama |
| `ios/Runner/Info.plist` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Ürün/asset | Statik + sözleşme |
| `ios/Runner/Runner-Bridging-Header.h` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Satır bazlı + statik tarama |
| `ios/Runner/SceneDelegate.swift` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Satır bazlı + statik tarama |
| `ios/Runner/en.lproj/InfoPlist.strings` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Ürün/asset | Statik + sözleşme |
| `ios/Runner/tr.lproj/InfoPlist.strings` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Ürün/asset | Statik + sözleşme |
| `ios/RunnerTests/RunnerTests.swift` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Satır bazlı + statik tarama |
| `l10n.yaml` | Kalite/tooling ([04](04-quality-engineering-agent-tooling-review.md)) | — | Statik + sözleşme |
| `lib/app.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | — | Satır bazlı + statik tarama |
| `lib/core/constants/api_endpoints.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | — | Satır bazlı + statik tarama |
| `lib/core/constants/app_branding.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | — | Satır bazlı + statik tarama |
| `lib/core/constants/app_colors.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | — | Satır bazlı + statik tarama |
| `lib/core/constants/date_constants.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | — | Satır bazlı + statik tarama |
| `lib/core/di/injection.dart` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Satır bazlı + statik tarama |
| `lib/core/error/app_error.dart` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Satır bazlı + statik tarama |
| `lib/core/error/app_error_messages.dart` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Satır bazlı + statik tarama |
| `lib/core/error/dio_error_mapper.dart` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Satır bazlı + statik tarama |
| `lib/core/error/error_reporter.dart` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Satır bazlı + statik tarama |
| `lib/core/l10n/l10n_extensions.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | — | Satır bazlı + statik tarama |
| `lib/core/lifecycle/app_lifecycle_events.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | — | Satır bazlı + statik tarama |
| `lib/core/network/api_base_url_validator.dart` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Satır bazlı + statik tarama |
| `lib/core/network/api_client.dart` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Satır bazlı + statik tarama |
| `lib/core/network/certificate_pinning.dart` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Satır bazlı + statik tarama |
| `lib/core/network/device_id_interceptor.dart` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Satır bazlı + statik tarama |
| `lib/core/network/device_info_interceptor.dart` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Satır bazlı + statik tarama |
| `lib/core/network/language_interceptor.dart` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Satır bazlı + statik tarama |
| `lib/core/network/locale_provider.dart` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Satır bazlı + statik tarama |
| `lib/core/network/retry_interceptor.dart` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Satır bazlı + statik tarama |
| `lib/core/observability/sentry_device_context.dart` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Satır bazlı + statik tarama |
| `lib/core/observability/sentry_pii_scrubber.dart` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Satır bazlı + statik tarama |
| `lib/core/platform/platform_info.dart` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Satır bazlı + statik tarama |
| `lib/core/storage/secure_storage_factory.dart` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Satır bazlı + statik tarama |
| `lib/core/theme/app_theme.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | Kalite/test | Satır bazlı + statik tarama |
| `lib/core/theme/theme_mode_mapper.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | Kalite/test | Satır bazlı + statik tarama |
| `lib/core/utils/app_formatters.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | — | Satır bazlı + statik tarama |
| `lib/core/utils/date_range_utils.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | — | Satır bazlı + statik tarama |
| `lib/core/utils/date_utils.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | — | Satır bazlı + statik tarama |
| `lib/core/utils/duration_label.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | — | Satır bazlı + statik tarama |
| `lib/core/utils/locale_number_parser.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | — | Satır bazlı + statik tarama |
| `lib/core/utils/money_parser.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | — | Satır bazlı + statik tarama |
| `lib/core/utils/percentage_formatter.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | — | Satır bazlı + statik tarama |
| `lib/core/utils/share_card_renderer.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | — | Satır bazlı + statik tarama |
| `lib/core/utils/turkish_text.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | — | Satır bazlı + statik tarama |
| `lib/core/widgets/count_up_text.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | Kalite/test | Satır bazlı + statik tarama |
| `lib/core/widgets/inflation_toggle.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | Kalite/test | Satır bazlı + statik tarama |
| `lib/core/widgets/settings_icon_button.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | Kalite/test | Satır bazlı + statik tarama |
| `lib/core/widgets/share_preview_sheet.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | Kalite/test | Satır bazlı + statik tarama |
| `lib/core/widgets/skeleton_card.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | Kalite/test | Satır bazlı + statik tarama |
| `lib/features/account/data/repositories/account_data_repository_impl.dart` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/account/domain/repositories/account_data_repository.dart` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/account/presentation/cubit/account_deletion_cubit.dart` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/account/presentation/cubit/account_deletion_state.dart` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/account/presentation/pages/delete_account_page.dart` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/account/presentation/widgets/delete_account_tile.dart` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/comparison/data/models/compare_result_model.dart` | Finansal domain ([01](01-financial-domain-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/comparison/data/repositories/comparison_repository_impl.dart` | Finansal domain ([01](01-financial-domain-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/comparison/domain/entities/compare_result.dart` | Finansal domain ([01](01-financial-domain-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/comparison/domain/repositories/comparison_repository.dart` | Finansal domain ([01](01-financial-domain-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/comparison/domain/usecases/compare_what_if.dart` | Finansal domain ([01](01-financial-domain-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/comparison/presentation/bloc/comparison_bloc.dart` | Finansal domain ([01](01-financial-domain-review.md)) | Ürün/UX | Satır bazlı + statik tarama |
| `lib/features/comparison/presentation/bloc/comparison_event.dart` | Finansal domain ([01](01-financial-domain-review.md)) | Ürün/UX | Satır bazlı + statik tarama |
| `lib/features/comparison/presentation/bloc/comparison_state.dart` | Finansal domain ([01](01-financial-domain-review.md)) | Ürün/UX | Satır bazlı + statik tarama |
| `lib/features/comparison/presentation/pages/comparison_page.dart` | Finansal domain ([01](01-financial-domain-review.md)) | Ürün/UX | Satır bazlı + statik tarama |
| `lib/features/comparison/presentation/widgets/comparison_result_card.dart` | Finansal domain ([01](01-financial-domain-review.md)) | Ürün/UX | Satır bazlı + statik tarama |
| `lib/features/comparison/presentation/widgets/comparison_share_card_widget.dart` | Finansal domain ([01](01-financial-domain-review.md)) | Ürün/UX | Satır bazlı + statik tarama |
| `lib/features/config/data/models/app_config_model.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/config/data/repositories/app_config_repository_impl.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/config/domain/entities/app_config.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/config/domain/entities/subscription_tier.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/config/domain/repositories/app_config_repository.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/config/presentation/cubit/app_config_cubit.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/config/presentation/extensions/config_extensions.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/dca/data/models/dca_response_model.dart` | Finansal domain ([01](01-financial-domain-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/dca/data/repositories/dca_repository_impl.dart` | Finansal domain ([01](01-financial-domain-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/dca/domain/entities/dca_result.dart` | Finansal domain ([01](01-financial-domain-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/dca/domain/repositories/dca_repository.dart` | Finansal domain ([01](01-financial-domain-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/dca/domain/usecases/calculate_dca.dart` | Finansal domain ([01](01-financial-domain-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/dca/presentation/bloc/dca_bloc.dart` | Finansal domain ([01](01-financial-domain-review.md)) | Ürün/UX | Satır bazlı + statik tarama |
| `lib/features/dca/presentation/bloc/dca_event.dart` | Finansal domain ([01](01-financial-domain-review.md)) | Ürün/UX | Satır bazlı + statik tarama |
| `lib/features/dca/presentation/bloc/dca_state.dart` | Finansal domain ([01](01-financial-domain-review.md)) | Ürün/UX | Satır bazlı + statik tarama |
| `lib/features/dca/presentation/pages/dca_page.dart` | Finansal domain ([01](01-financial-domain-review.md)) | Ürün/UX | Satır bazlı + statik tarama |
| `lib/features/dca/presentation/widgets/dca_chart.dart` | Finansal domain ([01](01-financial-domain-review.md)) | Ürün/UX | Satır bazlı + statik tarama |
| `lib/features/dca/presentation/widgets/dca_result_card.dart` | Finansal domain ([01](01-financial-domain-review.md)) | Ürün/UX | Satır bazlı + statik tarama |
| `lib/features/dca/presentation/widgets/dca_share_card_preview_sheet.dart` | Finansal domain ([01](01-financial-domain-review.md)) | Ürün/UX | Satır bazlı + statik tarama |
| `lib/features/dca/presentation/widgets/dca_share_card_widget.dart` | Finansal domain ([01](01-financial-domain-review.md)) | Ürün/UX | Satır bazlı + statik tarama |
| `lib/features/dca/presentation/widgets/period_selector.dart` | Finansal domain ([01](01-financial-domain-review.md)) | Ürün/UX | Satır bazlı + statik tarama |
| `lib/features/favorites/data/repositories/favorites_repository_impl.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/favorites/domain/repositories/favorites_repository.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/favorites/presentation/cubit/favorites_cubit.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/legal/data/repositories/legal_repository_impl.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | Güvenlik/privacy | Satır bazlı + statik tarama |
| `lib/features/legal/data/sources/kvkk_disclosure_en.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | Güvenlik/privacy | Satır bazlı + statik tarama |
| `lib/features/legal/data/sources/kvkk_disclosure_tr.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | Güvenlik/privacy | Satır bazlı + statik tarama |
| `lib/features/legal/data/sources/privacy_policy_en.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | Güvenlik/privacy | Satır bazlı + statik tarama |
| `lib/features/legal/data/sources/privacy_policy_tr.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | Güvenlik/privacy | Satır bazlı + statik tarama |
| `lib/features/legal/domain/entities/legal_document.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | Güvenlik/privacy | Satır bazlı + statik tarama |
| `lib/features/legal/domain/repositories/legal_repository.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | Güvenlik/privacy | Satır bazlı + statik tarama |
| `lib/features/legal/presentation/pages/legal_document_page.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | Güvenlik/privacy | Satır bazlı + statik tarama |
| `lib/features/legal/presentation/widgets/legal_tile.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | Güvenlik/privacy | Satır bazlı + statik tarama |
| `lib/features/onboarding/data/repositories/onboarding_repository_impl.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/onboarding/domain/repositories/onboarding_repository.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/onboarding/presentation/cubit/onboarding_cubit.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/onboarding/presentation/pages/onboarding_page.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/portfolio/data/repositories/portfolio_repository_impl.dart` | Finansal domain ([01](01-financial-domain-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/portfolio/domain/entities/portfolio_calculation.dart` | Finansal domain ([01](01-financial-domain-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/portfolio/domain/entities/portfolio_item.dart` | Finansal domain ([01](01-financial-domain-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/portfolio/domain/entities/portfolio_result.dart` | Finansal domain ([01](01-financial-domain-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/portfolio/domain/portfolio_constants.dart` | Finansal domain ([01](01-financial-domain-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/portfolio/domain/repositories/portfolio_repository.dart` | Finansal domain ([01](01-financial-domain-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/portfolio/domain/usecases/calculate_portfolio.dart` | Finansal domain ([01](01-financial-domain-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/portfolio/presentation/bloc/portfolio_bloc.dart` | Finansal domain ([01](01-financial-domain-review.md)) | Ürün/UX | Satır bazlı + statik tarama |
| `lib/features/portfolio/presentation/bloc/portfolio_event.dart` | Finansal domain ([01](01-financial-domain-review.md)) | Ürün/UX | Satır bazlı + statik tarama |
| `lib/features/portfolio/presentation/bloc/portfolio_state.dart` | Finansal domain ([01](01-financial-domain-review.md)) | Ürün/UX | Satır bazlı + statik tarama |
| `lib/features/portfolio/presentation/pages/portfolio_page.dart` | Finansal domain ([01](01-financial-domain-review.md)) | Ürün/UX | Satır bazlı + statik tarama |
| `lib/features/portfolio/presentation/widgets/portfolio_add_item_sheet.dart` | Finansal domain ([01](01-financial-domain-review.md)) | Ürün/UX | Satır bazlı + statik tarama |
| `lib/features/portfolio/presentation/widgets/portfolio_result_card.dart` | Finansal domain ([01](01-financial-domain-review.md)) | Ürün/UX | Satır bazlı + statik tarama |
| `lib/features/portfolio/presentation/widgets/portfolio_share_card_widget.dart` | Finansal domain ([01](01-financial-domain-review.md)) | Ürün/UX | Satır bazlı + statik tarama |
| `lib/features/scenarios/data/models/saved_scenario_model.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/scenarios/data/repositories/scenarios_repository_impl.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/scenarios/domain/entities/saved_scenario.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/scenarios/domain/repositories/scenarios_repository.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/scenarios/domain/usecases/delete_scenario.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/scenarios/domain/usecases/get_scenarios.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/scenarios/domain/usecases/save_scenario.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/scenarios/presentation/bloc/scenarios_bloc.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/scenarios/presentation/bloc/scenarios_event.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/scenarios/presentation/bloc/scenarios_state.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/scenarios/presentation/pages/scenarios_page.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/scenarios/presentation/widgets/scenario_card.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/settings/data/repositories/settings_repository_impl.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/settings/domain/entities/app_settings.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/settings/domain/repositories/settings_repository.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/settings/presentation/cubit/settings_cubit.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/settings/presentation/pages/settings_page.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/settings/presentation/widgets/language_selector_tile.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/settings/presentation/widgets/theme_selector_tile.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/what_if/data/models/asset_model.dart` | Finansal domain ([01](01-financial-domain-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/what_if/data/models/reverse_what_if_response_model.dart` | Finansal domain ([01](01-financial-domain-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/what_if/data/models/what_if_response_model.dart` | Finansal domain ([01](01-financial-domain-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/what_if/data/repositories/what_if_repository_impl.dart` | Finansal domain ([01](01-financial-domain-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/what_if/domain/entities/asset.dart` | Finansal domain ([01](01-financial-domain-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/what_if/domain/entities/reverse_what_if_result.dart` | Finansal domain ([01](01-financial-domain-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/what_if/domain/entities/what_if_result.dart` | Finansal domain ([01](01-financial-domain-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/what_if/domain/repositories/what_if_repository.dart` | Finansal domain ([01](01-financial-domain-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/what_if/domain/usecases/calculate_reverse_what_if.dart` | Finansal domain ([01](01-financial-domain-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/what_if/domain/usecases/calculate_what_if.dart` | Finansal domain ([01](01-financial-domain-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/what_if/domain/usecases/get_assets.dart` | Finansal domain ([01](01-financial-domain-review.md)) | — | Satır bazlı + statik tarama |
| `lib/features/what_if/presentation/bloc/what_if_bloc.dart` | Finansal domain ([01](01-financial-domain-review.md)) | Ürün/UX | Satır bazlı + statik tarama |
| `lib/features/what_if/presentation/bloc/what_if_event.dart` | Finansal domain ([01](01-financial-domain-review.md)) | Ürün/UX | Satır bazlı + statik tarama |
| `lib/features/what_if/presentation/bloc/what_if_state.dart` | Finansal domain ([01](01-financial-domain-review.md)) | Ürün/UX | Satır bazlı + statik tarama |
| `lib/features/what_if/presentation/pages/what_if_page.dart` | Finansal domain ([01](01-financial-domain-review.md)) | Ürün/UX | Satır bazlı + statik tarama |
| `lib/features/what_if/presentation/widgets/amount_input.dart` | Finansal domain ([01](01-financial-domain-review.md)) | Ürün/UX | Satır bazlı + statik tarama |
| `lib/features/what_if/presentation/widgets/asset_selector.dart` | Finansal domain ([01](01-financial-domain-review.md)) | Ürün/UX | Satır bazlı + statik tarama |
| `lib/features/what_if/presentation/widgets/date_input.dart` | Finansal domain ([01](01-financial-domain-review.md)) | Ürün/UX | Satır bazlı + statik tarama |
| `lib/features/what_if/presentation/widgets/result_card.dart` | Finansal domain ([01](01-financial-domain-review.md)) | Ürün/UX | Satır bazlı + statik tarama |
| `lib/features/what_if/presentation/widgets/result_chart.dart` | Finansal domain ([01](01-financial-domain-review.md)) | Ürün/UX | Satır bazlı + statik tarama |
| `lib/features/what_if/presentation/widgets/reverse_result_card.dart` | Finansal domain ([01](01-financial-domain-review.md)) | Ürün/UX | Satır bazlı + statik tarama |
| `lib/features/what_if/presentation/widgets/reverse_share_card_widget.dart` | Finansal domain ([01](01-financial-domain-review.md)) | Ürün/UX | Satır bazlı + statik tarama |
| `lib/features/what_if/presentation/widgets/share_card_preview_sheet.dart` | Finansal domain ([01](01-financial-domain-review.md)) | Ürün/UX | Satır bazlı + statik tarama |
| `lib/features/what_if/presentation/widgets/share_card_widget.dart` | Finansal domain ([01](01-financial-domain-review.md)) | Ürün/UX | Satır bazlı + statik tarama |
| `lib/l10n/app_en.arb` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | Kalite/test | Satır bazlı + statik tarama |
| `lib/l10n/app_localizations.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | Kalite/test | Satır bazlı + statik tarama |
| `lib/l10n/app_localizations_en.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | Kalite/test | Satır bazlı + statik tarama |
| `lib/l10n/app_localizations_tr.dart` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | Kalite/test | Satır bazlı + statik tarama |
| `lib/l10n/app_tr.arb` | Ürün/UX/docs ([03](03-product-ux-accessibility-docs-review.md)) | Kalite/test | Satır bazlı + statik tarama |
| `lib/main.dart` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | — | Satır bazlı + statik tarama |
| `pubspec.lock` | Kalite/tooling ([04](04-quality-engineering-agent-tooling-review.md)) | — | Bağımlılık/bütünlük |
| `pubspec.yaml` | Kalite/tooling ([04](04-quality-engineering-agent-tooling-review.md)) | — | Statik + sözleşme |
| `test/core/error/app_error_messages_test.dart` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Kalite/test | Satır bazlı + statik tarama |
| `test/core/error/app_error_test.dart` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Kalite/test | Satır bazlı + statik tarama |
| `test/core/error/dio_error_mapper_test.dart` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Kalite/test | Satır bazlı + statik tarama |
| `test/core/lifecycle/app_lifecycle_events_test.dart` | Kalite/tooling ([04](04-quality-engineering-agent-tooling-review.md)) | — | Satır bazlı + statik tarama |
| `test/core/network/api_base_url_validator_test.dart` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Kalite/test | Satır bazlı + statik tarama |
| `test/core/network/certificate_pinning_test.dart` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Kalite/test | Satır bazlı + statik tarama |
| `test/core/network/device_id_interceptor_test.dart` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Kalite/test | Satır bazlı + statik tarama |
| `test/core/network/device_info_interceptor_test.dart` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Kalite/test | Satır bazlı + statik tarama |
| `test/core/network/retry_interceptor_test.dart` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Kalite/test | Satır bazlı + statik tarama |
| `test/core/observability/sentry_pii_scrubber_test.dart` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Kalite/test | Satır bazlı + statik tarama |
| `test/core/utils/app_formatters_test.dart` | Kalite/tooling ([04](04-quality-engineering-agent-tooling-review.md)) | — | Satır bazlı + statik tarama |
| `test/core/utils/date_utils_test.dart` | Kalite/tooling ([04](04-quality-engineering-agent-tooling-review.md)) | — | Satır bazlı + statik tarama |
| `test/core/utils/duration_label_test.dart` | Kalite/tooling ([04](04-quality-engineering-agent-tooling-review.md)) | — | Satır bazlı + statik tarama |
| `test/core/utils/locale_number_parser_test.dart` | Kalite/tooling ([04](04-quality-engineering-agent-tooling-review.md)) | — | Satır bazlı + statik tarama |
| `test/core/utils/money_parser_test.dart` | Kalite/tooling ([04](04-quality-engineering-agent-tooling-review.md)) | — | Satır bazlı + statik tarama |
| `test/core/utils/percentage_formatter_test.dart` | Kalite/tooling ([04](04-quality-engineering-agent-tooling-review.md)) | — | Satır bazlı + statik tarama |
| `test/core/utils/turkish_text_test.dart` | Kalite/tooling ([04](04-quality-engineering-agent-tooling-review.md)) | — | Satır bazlı + statik tarama |
| `test/features/account/data/repositories/account_data_repository_impl_test.dart` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Kalite/test | Satır bazlı + statik tarama |
| `test/features/account/presentation/cubit/account_deletion_cubit_test.dart` | Güvenlik/platform ([02](02-security-platform-delivery-review.md)) | Kalite/test | Satır bazlı + statik tarama |
| `test/features/comparison/data/repositories/comparison_repository_impl_test.dart` | Finansal domain ([01](01-financial-domain-review.md)) | Kalite/test | Satır bazlı + statik tarama |
| `test/features/comparison/presentation/bloc/comparison_bloc_test.dart` | Finansal domain ([01](01-financial-domain-review.md)) | Kalite/test | Satır bazlı + statik tarama |
| `test/features/config/data/models/app_config_model_test.dart` | Kalite/tooling ([04](04-quality-engineering-agent-tooling-review.md)) | — | Satır bazlı + statik tarama |
| `test/features/dca/data/repositories/dca_repository_impl_test.dart` | Finansal domain ([01](01-financial-domain-review.md)) | Kalite/test | Satır bazlı + statik tarama |
| `test/features/dca/presentation/bloc/dca_bloc_test.dart` | Finansal domain ([01](01-financial-domain-review.md)) | Kalite/test | Satır bazlı + statik tarama |
| `test/features/favorites/presentation/cubit/favorites_cubit_test.dart` | Kalite/tooling ([04](04-quality-engineering-agent-tooling-review.md)) | — | Satır bazlı + statik tarama |
| `test/features/legal/data/repositories/legal_repository_impl_test.dart` | Kalite/tooling ([04](04-quality-engineering-agent-tooling-review.md)) | — | Satır bazlı + statik tarama |
| `test/features/onboarding/data/repositories/onboarding_repository_impl_test.dart` | Kalite/tooling ([04](04-quality-engineering-agent-tooling-review.md)) | — | Satır bazlı + statik tarama |
| `test/features/onboarding/presentation/cubit/onboarding_cubit_test.dart` | Kalite/tooling ([04](04-quality-engineering-agent-tooling-review.md)) | — | Satır bazlı + statik tarama |
| `test/features/portfolio/data/repositories/portfolio_repository_impl_test.dart` | Finansal domain ([01](01-financial-domain-review.md)) | Kalite/test | Satır bazlı + statik tarama |
| `test/features/portfolio/domain/usecases/calculate_portfolio_test.dart` | Finansal domain ([01](01-financial-domain-review.md)) | Kalite/test | Satır bazlı + statik tarama |
| `test/features/portfolio/presentation/bloc/portfolio_bloc_test.dart` | Finansal domain ([01](01-financial-domain-review.md)) | Kalite/test | Satır bazlı + statik tarama |
| `test/features/scenarios/data/models/saved_scenario_model_test.dart` | Kalite/tooling ([04](04-quality-engineering-agent-tooling-review.md)) | — | Satır bazlı + statik tarama |
| `test/features/scenarios/data/repositories/scenarios_repository_impl_test.dart` | Kalite/tooling ([04](04-quality-engineering-agent-tooling-review.md)) | — | Satır bazlı + statik tarama |
| `test/features/scenarios/presentation/bloc/scenarios_bloc_test.dart` | Kalite/tooling ([04](04-quality-engineering-agent-tooling-review.md)) | — | Satır bazlı + statik tarama |
| `test/features/settings/data/repositories/settings_repository_impl_test.dart` | Kalite/tooling ([04](04-quality-engineering-agent-tooling-review.md)) | — | Satır bazlı + statik tarama |
| `test/features/settings/presentation/cubit/settings_cubit_test.dart` | Kalite/tooling ([04](04-quality-engineering-agent-tooling-review.md)) | — | Satır bazlı + statik tarama |
| `test/features/what_if/data/models/asset_model_test.dart` | Finansal domain ([01](01-financial-domain-review.md)) | Kalite/test | Satır bazlı + statik tarama |
| `test/features/what_if/data/models/what_if_response_model_test.dart` | Finansal domain ([01](01-financial-domain-review.md)) | Kalite/test | Satır bazlı + statik tarama |
| `test/features/what_if/data/repositories/what_if_repository_impl_test.dart` | Finansal domain ([01](01-financial-domain-review.md)) | Kalite/test | Satır bazlı + statik tarama |
| `test/features/what_if/presentation/bloc/what_if_bloc_test.dart` | Finansal domain ([01](01-financial-domain-review.md)) | Kalite/test | Satır bazlı + statik tarama |
| `test/features/what_if/presentation/bloc/what_if_form_input_test.dart` | Finansal domain ([01](01-financial-domain-review.md)) | Kalite/test | Satır bazlı + statik tarama |
| `test/features/what_if/presentation/widgets/amount_input_test.dart` | Finansal domain ([01](01-financial-domain-review.md)) | Kalite/test | Satır bazlı + statik tarama |
| `test/features/what_if/presentation/widgets/result_card_test.dart` | Finansal domain ([01](01-financial-domain-review.md)) | Kalite/test | Satır bazlı + statik tarama |
| `test/l10n/app_localizations_plural_test.dart` | Kalite/tooling ([04](04-quality-engineering-agent-tooling-review.md)) | — | Satır bazlı + statik tarama |

## Review çıktıları

Bu inceleme sırasında üretilen aşağıdaki dosyalar baseline commit'in parçası
değildir; dolayısıyla yukarıdaki 303 satırda yer almaz:

- [00 — Ana proje review](00-master-project-review.md)
- [01 — Finansal domain](01-financial-domain-review.md)
- [02 — Güvenlik, platform ve teslimat](02-security-platform-delivery-review.md)
- [03 — Ürün, UX, erişilebilirlik ve dokümantasyon](03-product-ux-accessibility-docs-review.md)
- [04 — Quality engineering ve agent tooling](04-quality-engineering-agent-tooling-review.md)
- [05 — Bu kapsam manifestosu](05-review-coverage-manifest.md)

## Yeniden üretim kontrolü

Aynı commit'te envanteri doğrulamak için:

```bash
test "$(git rev-parse HEAD)" = "441eda4b5209f7814345eede1cb64438174ca6f2"
test "$(git ls-files | wc -l | tr -d ' ')" = "303"
test "$(git ls-files | LC_ALL=C sort | shasum -a 256 | awk '{print $1}')" = \
  "d4215ba391e261bedbb1fc5d7f0b7368dd68e91708eefddea9a57f8328967211"
```

HEAD değişirse bu manifesto önce yeni `git ls-files` envanteriyle
yenilenmelidir; aksi halde yeni dosyalar review kapsamı dışında kalmış sayılır.

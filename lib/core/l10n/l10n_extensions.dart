import 'package:flutter/widgets.dart';
import 'package:saydin/l10n/app_localizations.dart';
import 'package:saydin/l10n/app_localizations_en.dart';
import 'package:saydin/l10n/app_localizations_tr.dart';

extension L10nContext on BuildContext {
  /// Gerekçesiz `!` yerine: debug'da açıklayıcı assert (delegate eksikse
  /// nerede patladığı belli olsun), release'de crash yerine locale-aware
  /// fallback ile devam (EN locale → İngilizce, aksi halde Türkçe varsayılan).
  AppLocalizations get l10n {
    final l10n = AppLocalizations.of(this);
    assert(
      l10n != null,
      'AppLocalizations bulunamadı — MaterialApp.localizationsDelegates eksik '
      'mi, yoksa BuildContext yanlış ağaçta mı?',
    );
    if (l10n != null) return l10n;
    // Delegate yoksa (imkânsız-fallback path): aktif locale'e göre dil seç;
    // ağaçta Localizations yoksa platform diline düş, o da yoksa TR.
    final lang =
        Localizations.maybeLocaleOf(this)?.languageCode ??
        WidgetsBinding.instance.platformDispatcher.locale.languageCode;
    return lang == 'en' ? AppLocalizationsEn() : AppLocalizationsTr();
  }
}

import 'package:flutter/widgets.dart';
import 'package:saydin/l10n/app_localizations.dart';
import 'package:saydin/l10n/app_localizations_tr.dart';

extension L10nContext on BuildContext {
  /// Gerekçesiz `!` yerine: debug'da açıklayıcı assert (delegate eksikse
  /// nerede patladığı belli olsun), release'de crash yerine Türkçe
  /// (varsayılan dil) fallback ile devam.
  AppLocalizations get l10n {
    final l10n = AppLocalizations.of(this);
    assert(
      l10n != null,
      'AppLocalizations bulunamadı — MaterialApp.localizationsDelegates eksik '
      'mi, yoksa BuildContext yanlış ağaçta mı?',
    );
    return l10n ?? AppLocalizationsTr();
  }
}

import 'package:equatable/equatable.dart';

enum AppThemeMode { light, dark, system }

class AppSettings extends Equatable {
  final AppThemeMode themeMode;

  const AppSettings({this.themeMode = AppThemeMode.system});

  AppSettings copyWith({AppThemeMode? themeMode}) {
    return AppSettings(themeMode: themeMode ?? this.themeMode);
  }

  @override
  List<Object?> get props => [themeMode];
}

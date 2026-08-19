// GENERATED FILE - DO NOT EDIT.
// Regenerate with: python3 tool/quality/generate_coverage_imports.py
//
// Importing every production library makes never-executed libraries visible to
// the Dart VM coverage collector. Generated localization implementations are
// excluded by the coverage policy and therefore intentionally omitted.
// ignore_for_file: unused_import

import 'package:flutter_test/flutter_test.dart';
import 'package:saydin/app.dart' as source_1;
import 'package:saydin/core/constants/api_endpoints.dart' as source_2;
import 'package:saydin/core/constants/app_branding.dart' as source_3;
import 'package:saydin/core/constants/app_colors.dart' as source_4;
import 'package:saydin/core/constants/brand_colors.dart' as source_5;
import 'package:saydin/core/constants/date_constants.dart' as source_6;
import 'package:saydin/core/di/injection.dart' as source_7;
import 'package:saydin/core/error/app_error.dart' as source_8;
import 'package:saydin/core/error/app_error_messages.dart' as source_9;
import 'package:saydin/core/error/dio_error_mapper.dart' as source_10;
import 'package:saydin/core/error/error_reporter.dart' as source_11;
import 'package:saydin/core/error/response_body_validator.dart' as source_12;
import 'package:saydin/core/l10n/l10n_extensions.dart' as source_13;
import 'package:saydin/core/lifecycle/app_lifecycle_events.dart' as source_14;
import 'package:saydin/core/network/api_base_url_validator.dart' as source_15;
import 'package:saydin/core/network/api_client.dart' as source_16;
import 'package:saydin/core/network/certificate_pinning.dart' as source_17;
import 'package:saydin/core/network/device_id_interceptor.dart' as source_18;
import 'package:saydin/core/network/device_info_interceptor.dart' as source_19;
import 'package:saydin/core/network/language_interceptor.dart' as source_20;
import 'package:saydin/core/network/locale_provider.dart' as source_21;
import 'package:saydin/core/network/retry_interceptor.dart' as source_22;
import 'package:saydin/core/observability/sentry_device_context.dart'
    as source_23;
import 'package:saydin/core/observability/sentry_pii_scrubber.dart'
    as source_24;
import 'package:saydin/core/platform/platform_info.dart' as source_25;
import 'package:saydin/core/share/share_card_contract.dart' as source_26;
import 'package:saydin/core/share/share_financial_evidence.dart' as source_27;
import 'package:saydin/core/storage/secure_storage_factory.dart' as source_28;
import 'package:saydin/core/storage/share_card_cache.dart' as source_29;
import 'package:saydin/core/theme/app_theme.dart' as source_30;
import 'package:saydin/core/theme/financial_colors.dart' as source_31;
import 'package:saydin/core/theme/financial_outcome_style.dart' as source_32;
import 'package:saydin/core/theme/theme_mode_mapper.dart' as source_33;
import 'package:saydin/core/utils/app_formatters.dart' as source_34;
import 'package:saydin/core/utils/date_range_utils.dart' as source_35;
import 'package:saydin/core/utils/date_utils.dart' as source_36;
import 'package:saydin/core/utils/duration_label.dart' as source_37;
import 'package:saydin/core/utils/financial_amount_validator.dart' as source_38;
import 'package:saydin/core/utils/financial_outcome.dart' as source_39;
import 'package:saydin/core/utils/locale_number_parser.dart' as source_40;
import 'package:saydin/core/utils/money_parser.dart' as source_41;
import 'package:saydin/core/utils/percentage_formatter.dart' as source_42;
import 'package:saydin/core/utils/profit_direction_validator.dart' as source_43;
import 'package:saydin/core/utils/scenario_replay_parser.dart' as source_44;
import 'package:saydin/core/utils/share_card_renderer.dart' as source_45;
import 'package:saydin/core/utils/turkish_text.dart' as source_46;
import 'package:saydin/core/widgets/count_up_text.dart' as source_47;
import 'package:saydin/core/widgets/inflation_toggle.dart' as source_48;
import 'package:saydin/core/widgets/settings_icon_button.dart' as source_49;
import 'package:saydin/core/widgets/share_card_surface.dart' as source_50;
import 'package:saydin/core/widgets/share_preview_sheet.dart' as source_51;
import 'package:saydin/core/widgets/skeleton_card.dart' as source_52;
import 'package:saydin/features/account/data/repositories/account_data_repository_impl.dart'
    as source_53;
import 'package:saydin/features/account/domain/repositories/account_data_repository.dart'
    as source_54;
import 'package:saydin/features/account/presentation/cubit/account_deletion_cubit.dart'
    as source_55;
import 'package:saydin/features/account/presentation/cubit/account_deletion_state.dart'
    as source_56;
import 'package:saydin/features/account/presentation/pages/delete_account_page.dart'
    as source_57;
import 'package:saydin/features/account/presentation/widgets/delete_account_tile.dart'
    as source_58;
import 'package:saydin/features/comparison/data/models/compare_result_model.dart'
    as source_59;
import 'package:saydin/features/comparison/data/repositories/comparison_repository_impl.dart'
    as source_60;
import 'package:saydin/features/comparison/domain/entities/compare_result.dart'
    as source_61;
import 'package:saydin/features/comparison/domain/entities/comparison_share_projection.dart'
    as source_62;
import 'package:saydin/features/comparison/domain/repositories/comparison_repository.dart'
    as source_63;
import 'package:saydin/features/comparison/domain/usecases/compare_what_if.dart'
    as source_64;
import 'package:saydin/features/comparison/domain/usecases/project_comparison_share.dart'
    as source_65;
import 'package:saydin/features/comparison/presentation/bloc/comparison_bloc.dart'
    as source_66;
import 'package:saydin/features/comparison/presentation/bloc/comparison_event.dart'
    as source_67;
import 'package:saydin/features/comparison/presentation/bloc/comparison_state.dart'
    as source_68;
import 'package:saydin/features/comparison/presentation/pages/comparison_page.dart'
    as source_69;
import 'package:saydin/features/comparison/presentation/widgets/comparison_result_card.dart'
    as source_70;
import 'package:saydin/features/comparison/presentation/widgets/comparison_share_card_widget.dart'
    as source_71;
import 'package:saydin/features/config/data/models/app_config_model.dart'
    as source_72;
import 'package:saydin/features/config/data/repositories/app_config_repository_impl.dart'
    as source_73;
import 'package:saydin/features/config/domain/entities/app_config.dart'
    as source_74;
import 'package:saydin/features/config/domain/entities/subscription_tier.dart'
    as source_75;
import 'package:saydin/features/config/domain/policies/share_policy.dart'
    as source_76;
import 'package:saydin/features/config/domain/repositories/app_config_repository.dart'
    as source_77;
import 'package:saydin/features/config/presentation/cubit/app_config_cubit.dart'
    as source_78;
import 'package:saydin/features/config/presentation/extensions/config_extensions.dart'
    as source_79;
import 'package:saydin/features/config/presentation/widgets/config_readiness_gate.dart'
    as source_80;
import 'package:saydin/features/config/presentation/widgets/share_result_button.dart'
    as source_81;
import 'package:saydin/features/dca/data/models/dca_response_model.dart'
    as source_82;
import 'package:saydin/features/dca/data/repositories/dca_repository_impl.dart'
    as source_83;
import 'package:saydin/features/dca/domain/entities/dca_result.dart'
    as source_84;
import 'package:saydin/features/dca/domain/entities/dca_share_projection.dart'
    as source_85;
import 'package:saydin/features/dca/domain/repositories/dca_repository.dart'
    as source_86;
import 'package:saydin/features/dca/domain/usecases/calculate_dca.dart'
    as source_87;
import 'package:saydin/features/dca/domain/usecases/project_dca_share.dart'
    as source_88;
import 'package:saydin/features/dca/presentation/bloc/dca_bloc.dart'
    as source_89;
import 'package:saydin/features/dca/presentation/bloc/dca_event.dart'
    as source_90;
import 'package:saydin/features/dca/presentation/bloc/dca_state.dart'
    as source_91;
import 'package:saydin/features/dca/presentation/pages/dca_page.dart'
    as source_92;
import 'package:saydin/features/dca/presentation/widgets/dca_chart.dart'
    as source_93;
import 'package:saydin/features/dca/presentation/widgets/dca_result_card.dart'
    as source_94;
import 'package:saydin/features/dca/presentation/widgets/dca_share_card_preview_sheet.dart'
    as source_95;
import 'package:saydin/features/dca/presentation/widgets/dca_share_card_widget.dart'
    as source_96;
import 'package:saydin/features/dca/presentation/widgets/period_selector.dart'
    as source_97;
import 'package:saydin/features/favorites/data/repositories/favorites_repository_impl.dart'
    as source_98;
import 'package:saydin/features/favorites/domain/repositories/favorites_repository.dart'
    as source_99;
import 'package:saydin/features/favorites/presentation/cubit/favorites_cubit.dart'
    as source_100;
import 'package:saydin/features/legal/data/repositories/legal_repository_impl.dart'
    as source_101;
import 'package:saydin/features/legal/data/sources/kvkk_disclosure_en.dart'
    as source_102;
import 'package:saydin/features/legal/data/sources/kvkk_disclosure_tr.dart'
    as source_103;
import 'package:saydin/features/legal/data/sources/privacy_policy_en.dart'
    as source_104;
import 'package:saydin/features/legal/data/sources/privacy_policy_tr.dart'
    as source_105;
import 'package:saydin/features/legal/domain/entities/legal_document.dart'
    as source_106;
import 'package:saydin/features/legal/domain/repositories/legal_repository.dart'
    as source_107;
import 'package:saydin/features/legal/presentation/pages/legal_document_page.dart'
    as source_108;
import 'package:saydin/features/legal/presentation/widgets/legal_tile.dart'
    as source_109;
import 'package:saydin/features/onboarding/data/repositories/onboarding_repository_impl.dart'
    as source_110;
import 'package:saydin/features/onboarding/domain/repositories/onboarding_repository.dart'
    as source_111;
import 'package:saydin/features/onboarding/presentation/cubit/onboarding_cubit.dart'
    as source_112;
import 'package:saydin/features/onboarding/presentation/pages/onboarding_page.dart'
    as source_113;
import 'package:saydin/features/portfolio/data/repositories/portfolio_repository_impl.dart'
    as source_114;
import 'package:saydin/features/portfolio/domain/entities/portfolio_calculation.dart'
    as source_115;
import 'package:saydin/features/portfolio/domain/entities/portfolio_item.dart'
    as source_116;
import 'package:saydin/features/portfolio/domain/entities/portfolio_result.dart'
    as source_117;
import 'package:saydin/features/portfolio/domain/entities/portfolio_share_projection.dart'
    as source_118;
import 'package:saydin/features/portfolio/domain/portfolio_constants.dart'
    as source_119;
import 'package:saydin/features/portfolio/domain/repositories/portfolio_repository.dart'
    as source_120;
import 'package:saydin/features/portfolio/domain/usecases/calculate_portfolio.dart'
    as source_121;
import 'package:saydin/features/portfolio/domain/usecases/project_portfolio_share.dart'
    as source_122;
import 'package:saydin/features/portfolio/presentation/bloc/portfolio_bloc.dart'
    as source_123;
import 'package:saydin/features/portfolio/presentation/bloc/portfolio_event.dart'
    as source_124;
import 'package:saydin/features/portfolio/presentation/bloc/portfolio_state.dart'
    as source_125;
import 'package:saydin/features/portfolio/presentation/pages/portfolio_page.dart'
    as source_126;
import 'package:saydin/features/portfolio/presentation/widgets/portfolio_add_item_sheet.dart'
    as source_127;
import 'package:saydin/features/portfolio/presentation/widgets/portfolio_result_card.dart'
    as source_128;
import 'package:saydin/features/portfolio/presentation/widgets/portfolio_share_card_widget.dart'
    as source_129;
import 'package:saydin/features/scenarios/data/models/saved_scenario_model.dart'
    as source_130;
import 'package:saydin/features/scenarios/data/repositories/scenarios_repository_impl.dart'
    as source_131;
import 'package:saydin/features/scenarios/domain/entities/saved_scenario.dart'
    as source_132;
import 'package:saydin/features/scenarios/domain/repositories/scenarios_repository.dart'
    as source_133;
import 'package:saydin/features/scenarios/domain/scenario_input_fingerprint.dart'
    as source_134;
import 'package:saydin/features/scenarios/domain/usecases/delete_scenario.dart'
    as source_135;
import 'package:saydin/features/scenarios/domain/usecases/get_scenarios.dart'
    as source_136;
import 'package:saydin/features/scenarios/domain/usecases/save_scenario.dart'
    as source_137;
import 'package:saydin/features/scenarios/presentation/bloc/scenarios_bloc.dart'
    as source_138;
import 'package:saydin/features/scenarios/presentation/bloc/scenarios_event.dart'
    as source_139;
import 'package:saydin/features/scenarios/presentation/bloc/scenarios_state.dart'
    as source_140;
import 'package:saydin/features/scenarios/presentation/pages/scenarios_page.dart'
    as source_141;
import 'package:saydin/features/scenarios/presentation/widgets/scenario_card.dart'
    as source_142;
import 'package:saydin/features/settings/data/repositories/settings_repository_impl.dart'
    as source_143;
import 'package:saydin/features/settings/domain/entities/app_settings.dart'
    as source_144;
import 'package:saydin/features/settings/domain/repositories/settings_repository.dart'
    as source_145;
import 'package:saydin/features/settings/domain/usecases/reset_local_preferences.dart'
    as source_146;
import 'package:saydin/features/settings/presentation/cubit/settings_cubit.dart'
    as source_147;
import 'package:saydin/features/settings/presentation/pages/settings_page.dart'
    as source_148;
import 'package:saydin/features/settings/presentation/widgets/language_selector_tile.dart'
    as source_149;
import 'package:saydin/features/settings/presentation/widgets/reset_preferences_tile.dart'
    as source_150;
import 'package:saydin/features/settings/presentation/widgets/theme_selector_tile.dart'
    as source_151;
import 'package:saydin/features/what_if/data/models/asset_model.dart'
    as source_152;
import 'package:saydin/features/what_if/data/models/reverse_what_if_response_model.dart'
    as source_153;
import 'package:saydin/features/what_if/data/models/what_if_response_model.dart'
    as source_154;
import 'package:saydin/features/what_if/data/repositories/what_if_repository_impl.dart'
    as source_155;
import 'package:saydin/features/what_if/domain/entities/asset.dart'
    as source_156;
import 'package:saydin/features/what_if/domain/entities/reverse_what_if_result.dart'
    as source_157;
import 'package:saydin/features/what_if/domain/entities/what_if_result.dart'
    as source_158;
import 'package:saydin/features/what_if/domain/entities/what_if_share_projection.dart'
    as source_159;
import 'package:saydin/features/what_if/domain/repositories/what_if_repository.dart'
    as source_160;
import 'package:saydin/features/what_if/domain/usecases/calculate_reverse_what_if.dart'
    as source_161;
import 'package:saydin/features/what_if/domain/usecases/calculate_what_if.dart'
    as source_162;
import 'package:saydin/features/what_if/domain/usecases/get_assets.dart'
    as source_163;
import 'package:saydin/features/what_if/domain/usecases/project_what_if_share.dart'
    as source_164;
import 'package:saydin/features/what_if/presentation/bloc/what_if_bloc.dart'
    as source_165;
import 'package:saydin/features/what_if/presentation/bloc/what_if_event.dart'
    as source_166;
import 'package:saydin/features/what_if/presentation/bloc/what_if_state.dart'
    as source_167;
import 'package:saydin/features/what_if/presentation/pages/what_if_page.dart'
    as source_168;
import 'package:saydin/features/what_if/presentation/widgets/amount_input.dart'
    as source_169;
import 'package:saydin/features/what_if/presentation/widgets/asset_selector.dart'
    as source_170;
import 'package:saydin/features/what_if/presentation/widgets/date_input.dart'
    as source_171;
import 'package:saydin/features/what_if/presentation/widgets/result_card.dart'
    as source_172;
import 'package:saydin/features/what_if/presentation/widgets/result_chart.dart'
    as source_173;
import 'package:saydin/features/what_if/presentation/widgets/reverse_result_card.dart'
    as source_174;
import 'package:saydin/features/what_if/presentation/widgets/reverse_share_card_widget.dart'
    as source_175;
import 'package:saydin/features/what_if/presentation/widgets/share_card_preview_sheet.dart'
    as source_176;
import 'package:saydin/features/what_if/presentation/widgets/share_card_widget.dart'
    as source_177;
import 'package:saydin/main.dart' as source_178;

void main() {
  test('coverage manifest imports every production library', () {
    expect(true, isTrue);
  });
}

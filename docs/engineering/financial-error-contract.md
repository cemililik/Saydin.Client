# Financial amount and error contract

**Contract version:** 1

This document is the canonical, runtime-neutral contract for repository-local
agents, scaffolds and review automation. Application code remains the ultimate
executable source of truth; examples below point to the production APIs that a
generated feature must use.

## Financial values

- Monetary domain fields and request parameters use `Decimal`. `double`,
  `num` and binary floating-point parsing are not acceptable substitutes for an
  amount, price, cost, fee, total or monetary value.
- JSON input is parsed with `MoneyParser.requireDecimal`; outbound JSON uses
  `MoneyParser.toJsonString`. The canonical wire representation is a decimal
  string.
- Conversion to `double` is allowed only at a display-only API boundary that
  requires it (for example a chart coordinate). The `Decimal` value remains the
  source of truth.
- Percentages and chart coordinates are not money and may use `double` when
  their precision requirements allow it.
- Formatting uses the active application locale. No scaffold may hardcode
  `tr_TR`, a currency symbol or a locale-independent decimal parser.

## Error flow

- Domain repository and use-case methods return `Future<T>` and throw a typed
  `AppError` for expected failures. This repository does not define `Result`,
  `FailureOrSuccess`, `Either` or a second error container.
- The data layer maps transport failures to `AppError`. Presentation catches
  `AppError`; unexpected objects are wrapped in `UnknownError(cause: error)`.
- User-facing text is obtained with
  `error.localizedMessage(context.l10n)`. Error objects never contain localized
  display strings.
- BLoCs depend on use cases, never on `Dio`, `ApiClient` or another transport.

## Dependency injection boundary

- `sl()` is allowed in composition roots such as a `BlocProvider.create`
  callback.
- Descendant widgets consume the provided instance through `context.read`,
  `BlocBuilder` or `BlocConsumer`; they do not resolve dependencies directly.

## Verification

`python3 tool/quality/validate_repo_contracts.py` rejects stale scaffold
vocabulary, monetary `num` guidance, hardcoded deploy coordinates and a missing
master-review plan. CI runs this validator and its negative fixtures.

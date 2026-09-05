---
name: freezed
description: Conventions for freezed / json_serializable data classes in apps/app. Use whenever creating or editing a class annotated with @freezed or @Freezed, an enum that goes over the wire, a JsonConverter, or build.yaml codegen options.
---

# freezed in apps/app

Codegen defaults live in `apps/app/build.yaml` (snake_case fields and union
values, `explicit_to_json`). Never repeat them per class; a per-class
annotation carries only what genuinely differs, e.g.
`@Freezed(unionKey: 'answer_type')`.

## Shape of a class

- **Anything with `fromJson` → abstract class, factory syntax.** Freezed 4
  cannot pair a primary constructor with generated `toJson` (maintainer:
  primary-constructor classes need hand-written `@JsonSerializable`), so
  wire types use the factory form with Dart 3.13 constructor shorthand —
  never repeat the class name (`unnecessary_type_name_in_constructor`):

      @freezed
      abstract class AskQuestion with _$AskQuestion {
        const factory({
          required String questionId,
          required AnswerType answerType,
        }) = _AskQuestion;
        factory fromJson(Map<String, dynamic> json) => _$AskQuestionFromJson(json);
      }

- **Unions → sealed class**, same shorthand per variant:

      @Freezed(unionKey: 'answer_type')
      sealed class Answer with _$Answer {
        const factory color(@HexColorConverter() List<Color> value) = ColorAnswer;
        const factory textList(List<String> value) = TextListAnswer;
        factory fromJson(Map<String, dynamic> json) => _$AnswerFromJson(json);
      }

- **Plain state without JSON → primary constructor** (`use_primary_constructors`
  is enabled): `class const Foo({required final String a}) with _$Foo;`.
  Declaring parameters need `final`.

- **Behavior lives in an extension** in the same file (`extension AnswerX on
  Answer`), never inside the class. No private `const Foo._()` constructor:
  editing an extension does not touch generated code, so no regeneration.

## Primary constructors (non-freezed classes too)

`use_primary_constructors` is on: `class const HexColorConverter() implements
JsonConverter<Color, String> { ... }`, widgets as
`class const Foo({super.key}) extends StatelessWidget`, and constructor-less
enums as `enum Foo() { ... }`. Never add an empty `this;` body part;
`public_member_api_docs` is disabled precisely so none is needed.

## Wire types

- Enums: `@JsonEnum(fieldRename: FieldRename.snake)` on the enum. No
  hand-written wire-name fields or `fromWire` parsers — `toJson`/`fromJson`
  are the only serialization path, and tests pin against them.
- Typed values that are strings on the wire (colors, dates): a
  `JsonConverter` class annotated on the constructor parameter. A converter
  on a `List<T>` parameter applies per element.

## Generated code

- Regenerate: `dart run build_runner build` (the
  `--delete-conflicting-outputs` flag no longer exists in build_runner 2.16).
- `*.freezed.dart` / `*.g.dart` are committed, excluded from analysis and
  coverage, and CI fails on drift (`build_runner build --only-check`).

## Tests

- Round-trip every variant through `toJson` and `fromJson` against a literal
  wire-shape map; keep one sample per variant and assert the samples cover
  every enum value.
- Unknown union keys throw `CheckedFromJsonException`; unknown enum values
  throw `ArgumentError`. Assert both — never let bad input fall through.

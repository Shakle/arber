part of 'translation_cubit.dart';

@immutable
abstract class TranslationState {}

class TranslationInitial extends TranslationState {}

class TranslationGenerating extends TranslationState {}

class TranslationError extends TranslationState {
  final String errorMessage;

  TranslationError({required this.errorMessage});
}

class TranslationDone extends TranslationState {
  final ArbData arbData;

  TranslationDone({required this.arbData});
}

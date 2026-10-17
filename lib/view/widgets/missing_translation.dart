import 'package:arber/data/models/arb_data.dart';
import 'package:arber/data/models/missing_translation.dart';
import 'package:arber/logic/blocs/path/path_cubit.dart';
import 'package:arber/logic/blocs/translation/translation_cubit.dart';
import 'package:arber/theme/borders.dart';
import 'package:arber/theme/colors.dart';
import 'package:arber/view/widgets/background_field.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MissingTranslationWindow extends StatelessWidget {
  const MissingTranslationWindow({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<PathCubit, PathState>(
      builder: (context, state) {
        return AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: state is PathConnected ? 1 : 0,
          child: translationsLayout(),
        );
      },
    );
  }

  Widget translationsLayout() {
    return Builder(
      builder: (context) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700, maxHeight: 400),
            child: Stack(
              children: [
                BackgroundField(
                  borderRadius: allRoundBorderRadius,
                  padding: const EdgeInsets.only(top: 40),
                  child: SizedBox(
                    width: double.infinity,
                    height: double.infinity,
                    child: translationsList(),
                  ),
                ),
                Align(
                  alignment: const Alignment(1, -1),
                  child: Material(
                    type: MaterialType.transparency,
                    child: SizedBox(
                      width: 60,
                      height: 60,
                      child: refreshButton(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget translationsList() {
    return BlocBuilder<TranslationCubit, TranslationState>(
      builder: (context, state) {
        if (state is TranslationGenerating) {
          return checkingText();
        }

        if (state is TranslationDone) {
          final data = state.arbData;
          if (state.arbData.missingKeys.isNotEmpty ||
              state.arbData.missingTranslations.isNotEmpty) {
            return Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 10),
              child: ListView.builder(
                padding: const EdgeInsets.only(left: 40, right: 40, bottom: 30),
                itemCount:
                    (data.missingKeys.isEmpty
                        ? 0
                        : data.missingKeys.length + 3) +
                    (data.missingTranslations.isEmpty
                        ? 0
                        : data.missingTranslations.length + 2),
                itemBuilder: (context, index) => _resultRow(data, index),
              ),
            );
          } else {
            return allFineText();
          }
        }

        if (state is TranslationError) {
          return Container(
            padding: const EdgeInsets.only(top: 10),
            alignment: Alignment.center,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: errorTranslationsText(state.errorMessage),
            ),
          );
        }

        return translationsAreNotChecked();
      },
    );
  }

  Widget _resultRow(ArbData data, int index) {
    final keyCount = data.missingKeys.length;
    if (keyCount > 0) {
      if (index == 0) return missingTranslationKeysTitle();
      if (index == 1) return const SizedBox(height: 20);
      if (index < keyCount + 2) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: SelectableText(
            data.missingKeys[index - 2],
            style: const TextStyle(color: Colors.black87),
          ),
        );
      }
      if (index == keyCount + 2) return const SizedBox(height: 15);
      index -= keyCount + 3;
    }

    if (index == 0) return missingTranslationsTitle();
    if (index == 1) return const SizedBox(height: 20);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: missingTranslation(data.missingTranslations[index - 2]),
    );
  }

  Widget missingTranslation(MissingTranslation missingTranslation) {
    return RichText(
      text: TextSpan(
        style: const TextStyle(color: Colors.black87),
        children: <TextSpan>[
          TextSpan(
            text: missingTranslation.key,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const TextSpan(text: ' - '),
          ...List.generate(missingTranslation.missingTranslations.length, (
            index,
          ) {
            if (missingTranslation.missingTranslations[index] ==
                missingTranslation.missingTranslations.last) {
              return TextSpan(
                text: '${missingTranslation.missingTranslations[index]}.',
                style: const TextStyle(color: Colors.black54),
              );
            } else {
              return TextSpan(
                text: '${missingTranslation.missingTranslations[index]}, ',
                style: const TextStyle(color: Colors.black54),
              );
            }
          }),
        ],
      ),
    );
  }

  Widget errorTranslationsText(String text) {
    return SelectableText(text, textAlign: TextAlign.center);
  }

  Widget missingTranslationKeysTitle() {
    return const Text(
      'Missing keys in Excel:',
      textAlign: TextAlign.center,
      style: TextStyle(fontWeight: FontWeight.w600),
    );
  }

  Widget missingTranslationsTitle() {
    return const Text(
      'Missing translations in Excel:',
      textAlign: TextAlign.center,
      style: TextStyle(fontWeight: FontWeight.w600),
    );
  }

  Widget translationsAreNotChecked() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          'Missing translations have not been checked yet',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget checkingText() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Text('Checking translations..', textAlign: TextAlign.center),
      ),
    );
  }

  Widget allFineText() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          'Everything is translated, all fine',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget refreshButton(BuildContext context) {
    return BlocBuilder<TranslationCubit, TranslationState>(
      builder: (context, state) {
        if (state is TranslationGenerating) {
          return loader();
        }

        return Align(
          child: IconButton(
            onPressed: () {
              context.read<TranslationCubit>().checkArbExcelDifference();
            },
            icon: const Tooltip(
              message: 'Check missing translations',
              child: Icon(Icons.refresh_rounded, color: smoothBlue, size: 28),
            ),
          ),
        );
      },
    );
  }

  Widget loader() {
    return const Center(
      child: SizedBox(
        height: 17,
        width: 17,
        child: CircularProgressIndicator(strokeWidth: 3, color: smoothBlue),
      ),
    );
  }
}

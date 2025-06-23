import 'package:arber/data/models/missing_translation.dart';
import 'package:arber/logic/blocs/path/path_cubit.dart';
import 'package:arber/logic/blocs/translation/translation_cubit.dart';
import 'package:arber/theme/borders.dart';
import 'package:arber/theme/colors.dart';
import 'package:arber/view/widgets/background_field.dart';
import 'package:flutter/material.dart';
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
            child: translationsLayout()
        );
      },
    );
  }

  Widget translationsLayout() {
    return Builder(
        builder: (context) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: 700,
                maxHeight: 400,
              ),
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
        }
    );
  }

  Widget translationsList() {
    return BlocBuilder<TranslationCubit, TranslationState>(
      builder: (context, state) {
        if (state is TranslationGenerating) {
          return checkingText();
        }

        if (state is TranslationDone) {
          if (state.arbData.missingKeys.isNotEmpty
              || state.arbData.missingTranslations.isNotEmpty) {
            return Padding(
              padding: const EdgeInsets.only(top: 20, bottom: 10),
              child: ListView(
                padding: const EdgeInsets.only(
                  left: 40,
                  right: 40,
                  bottom: 30,
                ),
                children: [
                  ...keysMissingWidgets(state),
                  ...translationsMissingWidgets(state),
                ],
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

  List<Widget> keysMissingWidgets(TranslationDone state) {
    return [
      if (state.arbData.missingKeys.isNotEmpty)
        missingTranslationKeysTitle(),
      if (state.arbData.missingKeys.isNotEmpty)
        const SizedBox(height: 20),
      if (state.arbData.missingKeys.isNotEmpty)
        ...List.generate(state.arbData.missingKeys.length,
                (index) =>
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: SelectableText(
                    state.arbData.missingKeys[index],
                    style: const TextStyle(color: Colors.black87),
                  ),
                )),
      if (state.arbData.missingKeys.isNotEmpty)
        const SizedBox(height: 15),
    ];
  }

  List<Widget> translationsMissingWidgets(TranslationDone state) {
    return [
      if (state.arbData.missingTranslations.isNotEmpty)
        missingTranslationsTitle(),
      if (state.arbData.missingTranslations.isNotEmpty)
        const SizedBox(height: 20),
      if (state.arbData.missingTranslations.isNotEmpty)
        ...List.generate(state.arbData.missingTranslations.length,
                (index) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: missingTranslation(
                state.arbData.missingTranslations[index],
              ),
            )),
    ];
  }

  Widget missingTranslation(MissingTranslation missingTranslation) {
    return RichText(
      text: TextSpan(
          style: const TextStyle(color: Colors.black87),
          children: <TextSpan>[
            TextSpan(text: missingTranslation.key,
                style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const TextSpan(
              text: ' - ',
            ),
            ...List.generate(missingTranslation.missingTranslations.length,
                  (index) {
              if (missingTranslation.missingTranslations[index]
                  == missingTranslation.missingTranslations.last) {
                return TextSpan(
                  text: '${missingTranslation.missingTranslations[index]}.',
                  style: const TextStyle(color: Colors.black54),
                );
              } else {
                return TextSpan(
                  text: '${missingTranslation.missingTranslations[index]}, ',
                  style: const TextStyle(color: Colors.black54),
                );
              }},
            ),
          ],
      ),
    );
  }

  Widget errorTranslationsText(String text) {
    return SelectableText(
      text,
      textAlign: TextAlign.center,
    );
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
        child: Text(
          'Checking translations..',
          textAlign: TextAlign.center,
        ),
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

        return IconButton(
          onPressed: () {
            context.read<TranslationCubit>()
                .checkArbExcelDifference();
          },
          splashRadius: 25,
          icon: const Tooltip(
            message: 'Check missing translations',
            child: Icon(
              Icons.refresh_rounded,
              color: smoothBlue,
              size: 28,
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
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: smoothBlue,
        ),
      ),
    );
  }
}

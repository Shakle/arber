import 'package:arber/logic/blocs/path/path_cubit.dart';
import 'package:arber/logic/blocs/translation/translation_cubit.dart';
import 'package:arber/theme/borders.dart';
import 'package:arber/theme/colors.dart';
import 'package:arber/view/widgets/background_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class MissingTranslationWindow extends StatelessWidget {
  const MissingTranslationWindow({Key? key}) : super(key: key);

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
                    padding: const EdgeInsets.symmetric(
                      vertical: 40,
                    ),
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
          if (state.arbData.missingKeys.isNotEmpty) {
            return Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Column(
                children: [
                  missingTranslationsTitle(),
                  const SizedBox(height: 15),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      children: List.generate(state.arbData.missingKeys.length,
                            (index) =>
                            SelectableText(
                              state.arbData.missingKeys[index],
                            ),
                      ),
                    ),
                  ),
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

  Widget errorTranslationsText(String text) {
    return SelectableText(
      text,
      textAlign: TextAlign.center,
    );
  }

  Widget missingTranslationsTitle() {
    return const Text(
      'Missing translations in Excel file:',
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
          'No missing translations, all fine',
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
          color: smoothBlue,
        ),
      ),
    );
  }
}

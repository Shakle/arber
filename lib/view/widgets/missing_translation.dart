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
      builder: (context, pathState) {
        return BlocBuilder<TranslationCubit, TranslationState>(
          builder: (context, translationState) {
            final paths = context.read<PathCubit>();
            // PathState can lag behind text changes while paths are being saved.
            final visible =
                pathState is PathConnected &&
                paths.excelFilePathController.text.isNotEmpty &&
                paths.l10nDirPathController.text.isNotEmpty;
            return _FadingTranslationCard(
              visible: visible,
              state: translationState,
              builder: (state) => _TranslationReport(state: state),
            );
          },
        );
      },
    );
  }
}

class _TranslationReport extends StatefulWidget {
  const _TranslationReport({required this.state});

  final TranslationState state;

  @override
  State<_TranslationReport> createState() => _TranslationReportState();
}

class _TranslationReportState extends State<_TranslationReport> {
  bool _showArb = false;

  @override
  Widget build(BuildContext context) => translationsLayout(widget.state);

  Widget translationsLayout(TranslationState state) {
    return Builder(
      builder: (context) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 700, maxHeight: 400),
            child: BackgroundField(
              borderRadius: allRoundBorderRadius,
              clipBehavior: Clip.antiAlias,
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _header(context, state),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0.025, 0),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: KeyedSubtree(
                        key: ValueKey(_showArb),
                        child: translationsList(state),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _header(BuildContext context, TranslationState state) {
    var title = _showArb ? 'Missing keys in ARB' : 'Translation check';
    if (state is TranslationGenerating) {
      title = _showArb ? 'Comparing ARB…' : 'Checking translations…';
    } else if (!_showArb &&
        state is TranslationDone &&
        state.arbData.missingTranslations.isNotEmpty) {
      title = 'Missing translations in Excel';
    }
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: IconButton(
              tooltip: _showArb
                  ? 'Show missing translations'
                  : 'Show ARB comparison',
              onPressed: () => setState(() => _showArb = !_showArb),
              constraints: const BoxConstraints.tightFor(width: 36, height: 36),
              padding: const EdgeInsets.all(8),
              icon: Icon(
                _showArb
                    ? Icons.compare_arrows_rounded
                    : Icons.translate_rounded,
                size: 20,
                color: smoothBlue,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(width: 36, height: 36, child: refreshButton(context, state)),
        ],
      ),
    );
  }

  Widget translationsList(TranslationState state) {
    final showArb = _showArb;
    if (showArb &&
        context.read<PathCubit>().arbFilePathController.text.trim().isEmpty) {
      return _statusText(
        'No reference ARB selected',
        'Select an ARB to compare keys with Excel',
      );
    }
    if (state is TranslationGenerating) {
      return const SizedBox.shrink();
    }

    if (state is TranslationDone) {
      final data = state.arbData;
      if (showArb && !data.arbCompared) {
        return _statusText(
          'Not compared yet',
          'Refresh to compare ARB with Excel',
        );
      }
      final itemCount = showArb
          ? data.missingKeys.length +
                data.missingArbKeys.length +
                (data.missingKeys.isEmpty ? 0 : 1) +
                (data.missingKeys.isNotEmpty && data.missingArbKeys.isNotEmpty
                    ? 1
                    : 0)
          : data.missingTranslations.length;
      if (itemCount > 0) {
        return Stack(
          children: [
            ListView.builder(
              key: ValueKey(showArb),
              padding: const EdgeInsets.fromLTRB(32, 12, 32, 0),
              itemCount: itemCount,
              itemBuilder: (context, index) => showArb
                  ? _comparisonRow(data, index)
                  : missingTranslation(data.missingTranslations[index]),
            ),
            _scrollFade(top: true),
            _scrollFade(top: false),
          ],
        );
      } else {
        return showArb
            ? _statusText('Keys match', 'ARB and Excel contain the same keys')
            : allFineText();
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
  }

  Widget _scrollFade({required bool top}) {
    return Positioned(
      top: top ? 0 : null,
      bottom: top ? null : 0,
      left: 32,
      right: 32,
      height: 16,
      child: IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: top ? Alignment.topCenter : Alignment.bottomCenter,
              end: top ? Alignment.bottomCenter : Alignment.topCenter,
              colors: const [Colors.white, Color(0x00FFFFFF)],
            ),
          ),
        ),
      ),
    );
  }

  Widget _comparisonRow(ArbData data, int index) {
    if (data.missingKeys.isEmpty) return _keyRow(data.missingArbKeys[index]);
    if (data.missingKeys.isNotEmpty) {
      if (index == 0) return _sectionTitle('Missing keys in Excel');
      if (index <= data.missingKeys.length) {
        return _keyRow(data.missingKeys[index - 1]);
      }
      index -= data.missingKeys.length + 1;
    }
    if (index == 0) return _sectionTitle('Missing keys in ARB');
    return _keyRow(data.missingArbKeys[index - 1]);
  }

  Widget _keyRow(String key) {
    return _reportRow(key);
  }

  Widget missingTranslation(MissingTranslation missingTranslation) {
    return _reportRow(
      missingTranslation.key,
      locales: missingTranslation.missingTranslations,
    );
  }

  Widget _reportRow(String key, {List<String>? locales}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 7),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Color(0x10000000), width: 0.5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectableText(
            key,
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          if (locales != null && locales.isNotEmpty) ...[
            const SizedBox(height: 3),
            SelectableText(
              locales.join(' · '),
              style: const TextStyle(
                fontSize: 11,
                height: 1.4,
                color: Colors.black45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget errorTranslationsText(String text) {
    return SelectableText(text, textAlign: TextAlign.center);
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: Colors.black54,
        ),
      ),
    );
  }

  Widget translationsAreNotChecked() {
    return _statusText(
      'Not checked yet',
      _showArb
          ? 'Refresh to compare ARB with Excel'
          : 'Refresh to find missing translations',
    );
  }

  Widget _statusText(String title, String hint) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Colors.black54,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              hint,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, color: Colors.black45),
            ),
          ],
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

  Widget refreshButton(BuildContext context, TranslationState state) {
    if (state is TranslationGenerating) {
      return loader();
    }

    return IconButton(
      constraints: const BoxConstraints.tightFor(width: 36, height: 36),
      padding: const EdgeInsets.all(6),
      onPressed: () {
        context.read<TranslationCubit>().checkArbExcelDifference();
      },
      icon: const Tooltip(
        message: 'Check missing translations',
        child: Icon(Icons.refresh_rounded, color: smoothBlue, size: 24),
      ),
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

class _FadingTranslationCard extends StatefulWidget {
  const _FadingTranslationCard({
    required this.visible,
    required this.state,
    required this.builder,
  });

  final bool visible;
  final TranslationState state;
  final Widget Function(TranslationState) builder;

  @override
  State<_FadingTranslationCard> createState() => _FadingTranslationCardState();
}

class _FadingTranslationCardState extends State<_FadingTranslationCard> {
  late TranslationState _displayedState;
  late bool _hidden;

  @override
  void initState() {
    super.initState();
    _displayedState = widget.state;
    _hidden = !widget.visible;
  }

  @override
  void didUpdateWidget(_FadingTranslationCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Keep the previous report intact until the hide animation finishes.
    if (widget.visible) {
      _hidden = false;
      _displayedState = widget.state;
    } else if (_hidden) {
      _displayedState = widget.state;
    }
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      ignoring: !widget.visible,
      child: ExcludeSemantics(
        excluding: !widget.visible,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 250),
          opacity: widget.visible ? 1 : 0,
          onEnd: () {
            if (!widget.visible) {
              setState(() {
                _hidden = true;
                _displayedState = widget.state;
              });
            }
          },
          child: widget.builder(_displayedState),
        ),
      ),
    );
  }
}

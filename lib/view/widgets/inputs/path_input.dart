import 'package:arber/data/enums.dart';
import 'package:arber/logic/blocs/arb/arb_cubit.dart';
import 'package:arber/logic/blocs/path/path_cubit.dart';
import 'package:arber/theme/colors.dart';
import 'package:arber/theme/theme.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PathInput extends StatelessWidget {
  PathInput.excelPath({super.key, required this.controller}) {
    label = 'Excel';
    hint = 'Select an .xlsx file';
    artifactType = ArtifactType.excel;
  }

  PathInput.mainArbPath({super.key, required this.controller}) {
    label = 'ARB';
    hint = 'Optional .arb reference';
    artifactType = ArtifactType.mainArb;
  }

  PathInput.l10nPath({super.key, required this.controller}) {
    label = 'Output';
    hint = 'Select output folder';
    artifactType = ArtifactType.l10n;
  }

  late final String hint;
  late final String label;
  late final ArtifactType artifactType;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 450),
      child: input(),
    );
  }

  Widget input() {
    return BlocConsumer<PathCubit, PathState>(
      listenWhen: (prevState, state) => state is! PathConnected,
      listener: (context, state) {
        ArbCubit cubit = context.read<ArbCubit>();
        if (cubit.state is ArbDone) {
          cubit.reset();
        }
      },
      buildWhen: (prevState, state) => state is! PathInitial,
      builder: (context, state) {
        return _PathTextField(
          controller: controller,
          label: label,
          hint: hint,
          suffixIcon: getIcon(state),
        );
      },
    );
  }

  Widget errorIcon(PathConnectionFailed state) {
    String message = state.failedArtifacts
        .firstWhere((e) => e.artifactType == artifactType)
        .exceptionMessage;

    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: Tooltip(
        message: message,
        child: Icon(Icons.error_outline_rounded, color: Colors.red.shade700),
      ),
    );
  }

  Widget warningIcon(PathConnected state) {
    String message = state.failedArtifacts
        .firstWhere((e) => e.artifactType == artifactType)
        .exceptionMessage;

    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: Tooltip(
        message: message,
        child: const Icon(Icons.info_outline_rounded, color: Colors.amber),
      ),
    );
  }

  Widget successIcon() {
    return const Padding(
      padding: EdgeInsets.only(right: 10),
      child: Tooltip(
        message: 'Connected',
        child: Icon(Icons.done, color: smoothBlue),
      ),
    );
  }

  Widget? getIcon(PathState state) {
    if (state is PathConnectionFailed) {
      if (state.successArtifacts.contains(artifactType)) {
        return successIcon();
      } else if (state.failedArtifacts.any(
        (e) => e.artifactType == artifactType,
      )) {
        return errorIcon(state);
      }
    }

    if (state is PathConnected) {
      if (state.failedArtifacts.any((e) => e.artifactType == artifactType)) {
        return warningIcon(state);
      } else {
        return successIcon();
      }
    }

    return null;
  }
}

class _PathTextField extends StatefulWidget {
  const _PathTextField({
    required this.controller,
    required this.label,
    required this.hint,
    this.suffixIcon,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final Widget? suffixIcon;

  @override
  State<_PathTextField> createState() => _PathTextFieldState();
}

class _PathTextFieldState extends State<_PathTextField> {
  final _focusNode = FocusNode();
  final _scrollController = ScrollController();
  late String _text;
  bool _tailScheduled = false;

  @override
  void initState() {
    super.initState();
    _text = widget.controller.text;
    widget.controller.addListener(_onTextChanged);
    _focusNode.addListener(_onFocusChanged);
  }

  @override
  void didUpdateWidget(_PathTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_onTextChanged);
      widget.controller.addListener(_onTextChanged);
      _text = widget.controller.text;
      _showTail();
    }
  }

  void _onTextChanged() {
    if (_text == widget.controller.text) return;
    setState(() {
      _text = widget.controller.text;
    });
    _showTail();
  }

  void _onFocusChanged() {
    setState(() {});
    if (!_focusNode.hasFocus) {
      _showTail();
    }
  }

  void _showTail() {
    if (_tailScheduled || _focusNode.hasFocus) return;
    _tailScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tailScheduled = false;
      if (!mounted || _focusNode.hasFocus || !_scrollController.hasClients) {
        return;
      }
      final extent = _scrollController.position.maxScrollExtent;
      _scrollController.jumpTo(extent);
    });
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode
      ..removeListener(_onFocusChanged)
      ..dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        _showTail();
        final showTail = !_focusNode.hasFocus && _text.isNotEmpty;
        final inputStyle = Theme.of(context).textTheme.bodyLarge!
            .merge(AppTheme.inputTextStyle);
        return Tooltip(
          // An empty tooltip removes its wrappers and recreates the focused editor.
          message: _text.isEmpty ? widget.hint : _text,
          waitDuration: const Duration(milliseconds: 500),
          child: Semantics(
            label: '${widget.label} path',
            child: Stack(
              children: [
                TextField(
                  controller: widget.controller,
                  focusNode: _focusNode,
                  scrollController: _scrollController,
                  textAlignVertical: TextAlignVertical.center,
                  style: _text.isEmpty
                      ? AppTheme.hintTextStyle
                      : inputStyle.copyWith(
                          color: showTail
                              ? Colors.transparent
                              : inputStyle.color,
                        ),
                  decoration: InputDecoration(
                    hintText: widget.hint,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 14,
                    ),
                    prefixIconConstraints: const BoxConstraints.tightFor(
                      width: 72,
                      height: 48,
                    ),
                    prefixIcon: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
                      child: Container(
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          border: Border(
                            right: BorderSide(color: Colors.black12),
                          ),
                        ),
                        child: Text(
                          widget.label,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 0,
                            color: Colors.black45,
                          ),
                        ),
                      ),
                    ),
                    suffixIcon: widget.suffixIcon,
                    suffixIconConstraints: const BoxConstraints.tightFor(
                      width: 48,
                      height: 48,
                    ),
                  ),
                ),
                if (showTail)
                  Positioned(
                    left: 72,
                    right: widget.suffixIcon == null ? 12 : 48,
                    top: 0,
                    bottom: 0,
                    child: IgnorePointer(
                      child: ExcludeSemantics(
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: _PathTail(text: _text, style: inputStyle),
                        ),
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
}

class _PathTail extends StatelessWidget {
  const _PathTail({required this.text, required this.style});

  final String text;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final painter = TextPainter(
          textDirection: Directionality.of(context),
          textScaler: MediaQuery.textScalerOf(context),
          maxLines: 1,
        );
        bool fits(String value) {
          painter
            ..text = TextSpan(text: value, style: style)
            ..layout();
          return painter.width <= constraints.maxWidth;
        }

        var display = text;
        if (!fits(text)) {
          final characters = text.characters.toList(growable: false);
          var low = 0;
          var high = characters.length;
          while (low < high) {
            final middle = (low + high) ~/ 2;
            if (fits('… ${characters.skip(middle).join()}')) {
              high = middle;
            } else {
              low = middle + 1;
            }
          }
          display = '… ${characters.skip(low).join()}';
        }
        painter.dispose();
        return Text(
          display,
          key: const ValueKey('path-tail'),
          style: style,
          maxLines: 1,
          softWrap: false,
          overflow: TextOverflow.clip,
        );
      },
    );
  }
}

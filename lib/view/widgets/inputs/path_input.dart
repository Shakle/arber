import 'package:arber/data/enums.dart';
import 'package:arber/logic/blocs/path/path_cubit.dart';
import 'package:arber/theme/colors.dart';
import 'package:arber/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PathInput extends StatelessWidget {

  PathInput.excelPath({
    super.key,
    required this.controller,
  }) {
    hint = 'Excel file path';
    artifactType = ArtifactType.excel;
  }

  PathInput.l10nPath({
    super.key,
    required this.controller,
  }) {
    hint = 'l10n directory path';
    artifactType = ArtifactType.l10n;
  }

  late final String hint;
  late final ArtifactType artifactType;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 450,
      ),
      child: input(),
    );
  }

  Widget input() {
    return BlocBuilder<PathCubit, PathState>(
      buildWhen: (prevState, state) => state is! PathInitial,
      builder: (context, state) {
        return Form(
          child: TextFormField(
            autovalidateMode: AutovalidateMode.always,
            controller: controller,
            style: AppTheme.inputTextStyle,
            decoration: InputDecoration(
              hintText: hint,
              suffixIcon: getIcon(state),
            ),
          ),
        );
      }
    );
  }

  Widget errorIcon(PathConnectionFailed state) {
    String message = state.failedArtifacts.firstWhere((e)
      => e.artifactType == artifactType).exceptionMessage;

    return Padding(
      padding: const EdgeInsets.only(right: 5),
      child: Tooltip(
        message: message,
        child: Icon(
          Icons.error_outline_rounded,
          color: Colors.red.shade700,
        ),
      ),
    );
  }

  Widget successIcon() {
    return const Padding(
      padding: EdgeInsets.only(right: 10),
      child: Tooltip(
          message: 'Connected',
          child: Icon(
            Icons.done,
            color: smoothBlue,
          ),
      ),
    );
  }

  Widget? getIcon(PathState state) {

    if (state is PathConnectionFailed) {
      if (state.successArtifacts.contains(artifactType)) {
        return successIcon();
      } else if (
        state.failedArtifacts.any((e) => e.artifactType == artifactType)
      ) {
        return errorIcon(state);
      }
    }

    if (state is PathConnected) {
      return successIcon();
    }

    return null;
  }

}
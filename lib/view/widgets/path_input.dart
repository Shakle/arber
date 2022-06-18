import 'package:arber/data/enums.dart';
import 'package:arber/logic/blocs/path/path_cubit.dart';
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
        maxWidth: 550,
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
            decoration: InputDecoration(
              hintText: hint,
              enabledBorder: Theme.of(context).inputDecorationTheme
                  .enabledBorder
                  ?.copyWith(borderSide: getBorderSide(state)),
              focusedBorder: Theme.of(context).inputDecorationTheme
                  .focusedBorder
                  ?.copyWith(borderSide: getBorderSide(state)),
            ),
          ),
        );
      }
    );
  }

  BorderSide? getBorderSide(PathState state) {
    Color successColor = Colors.green;

    if (state is PathConnectionFailed) {
      if (state.successArtifacts.contains(artifactType)) {
        return BorderSide(color: successColor);
      } else if (state.failedArtifacts.any((e) => e.artifactType == artifactType)) {
        return const BorderSide(color: Colors.red);
      }
    }

    if (state is PathConnected) {
      return BorderSide(color:successColor);
    }

    return null;
  }

}

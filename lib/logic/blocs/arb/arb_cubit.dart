import 'dart:isolate';

import 'package:arber/data/models/arb.dart';
import 'package:arber/services/arb_service.dart';
import 'package:arber/services/file_service.dart';
import 'package:arber/view/widgets/animations/dash.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'arb_state.dart';

class ArbCubit extends Cubit<ArbState> {
  ArbCubit() : super(ArbInitial());

  final FileService _fileService = FileService();

  void reset() => emit(ArbInitial());

  Future<void> generateARBs(String excelPath, String l10nPath) async {
    try {
      dashAnimationNotifier.value = DashAnimationState.slowDance;
      emit(ArbGenerating());

      final List<Arb> arbs = await Isolate.run(
        () => ArbService().getArbs(excelPath),
      );

      await _fileService.writeArbFiles(l10nPath, arbs);
      emit(ArbDone());
    } catch (e) {
      emit(ArbFailed(e));
    } finally {
      dashAnimationNotifier.value = DashAnimationState.idle;
    }
  }
}

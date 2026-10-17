import 'dart:isolate';

import 'package:arber/services/arb_service.dart';
import 'package:arber/services/file_service.dart';
import 'package:arber/view/widgets/animations/dash.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'arb_state.dart';

class ArbCubit extends Cubit<ArbState> {
  ArbCubit() : super(ArbInitial());

  void reset() {
    if (isClosed || state is ArbGenerating) return;
    emit(ArbInitial());
  }

  Future<void> generateARBs(String excelPath, String l10nPath) async {
    if (isClosed || state is ArbGenerating) return;
    final activity = beginDashActivity();
    try {
      emit(ArbGenerating());

      await _generateArbFiles(excelPath, l10nPath);
      if (!isClosed) emit(ArbDone());
    } catch (e) {
      if (!isClosed) emit(ArbFailed(e));
    } finally {
      endDashActivity(activity);
    }
  }
}

// Keep the worker closure outside the Cubit so it only captures path strings.
Future<void> _generateArbFiles(String excelPath, String l10nPath) {
  return Isolate.run(() async {
    final arbs = ArbService().getArbs(excelPath);
    // Serialization and synchronous file operations must stay in this isolate.
    await FileService().writeArbFiles(l10nPath, arbs);
  }, debugName: 'arber.generateArbs');
}

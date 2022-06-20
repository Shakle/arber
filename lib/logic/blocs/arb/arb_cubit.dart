import 'package:arber/data/models/arb.dart';
import 'package:arber/services/arb_service.dart';
import 'package:arber/services/file_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'arb_state.dart';

class ArbCubit extends Cubit<ArbState> {
  ArbCubit() : super(ArbInitial());

  final ArbService _arbService = ArbService();
  final FileService _fileService = FileService();

  Future<void> generateARBs(String excelPath, String l10nPath) async {
    try {
      emit(ArbGenerating());
      List<Arb> arbs = _arbService.getArbs(excelPath);
      await _fileService.writeArbFiles(l10nPath, arbs);
      emit(ArbDone());
    } catch (e) {
      emit(ArbFailed(e));
    }
  }
}

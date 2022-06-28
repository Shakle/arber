import 'dart:async';

import 'package:arber/data/models/arb_data.dart';
import 'package:arber/logic/blocs/path/path_cubit.dart';
import 'package:arber/services/arb_service.dart';
import 'package:computer/computer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'translation_state.dart';

class TranslationCubit extends Cubit<TranslationState> {
  TranslationCubit({
    required PathCubit pathCubit,
  }) : super(TranslationInitial()) {
    _pathCubit = pathCubit;
    pathSubscription = pathCubit.stream.listen((event) {
      if (event is! PathConnected) {
        Future.delayed(const Duration(milliseconds: 300), () {
          emit(TranslationInitial());
        });
      }
    });
  }

  final ArbService _arbService = ArbService();
  late final PathCubit _pathCubit;
  late final StreamSubscription<PathState> pathSubscription;

  Future<void> checkArbExcelDifference() async {
    late final Computer computer;

    try {
      emit(TranslationGenerating());

      computer = Computer.create();
      await computer.turnOn();

      ArbData arbData = await computer.compute(
        _arbService.getArbExcelDifference,
        param: [
          _pathCubit.excelFilePathController.text,
          _pathCubit.arbFilePathController.text,
        ],
      );

      emit(TranslationDone(arbData: arbData));
    } catch (e) {
      emit(TranslationError(errorMessage: e.toString()));
    } finally {
      await computer.turnOff();
    }
  }

  @override
  Future<void> close() {
    pathSubscription.cancel();
    return super.close();
  }
}

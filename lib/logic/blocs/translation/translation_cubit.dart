import 'dart:async';
import 'dart:isolate';

import 'package:arber/data/models/arb_data.dart';
import 'package:arber/logic/blocs/arb/arb_cubit.dart';
import 'package:arber/logic/blocs/path/path_cubit.dart';
import 'package:arber/services/arb_service.dart';
import 'package:arber/view/widgets/animations/dash.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'translation_state.dart';

class TranslationCubit extends Cubit<TranslationState> {

  TranslationCubit({
    required PathCubit pathCubit,
    required ArbCubit arbCubit,
  }) : super(TranslationInitial()) {
    _pathCubit = pathCubit;
    _arbCubit = arbCubit;
    pathSubscription = pathCubit.stream.listen((event) {
      if (event is! PathConnected) {
        Future.delayed(const Duration(milliseconds: 300), () {
          emit(TranslationInitial());
        });
      }
    });
    translationSubscription = stream.listen((event) {
      if (_arbCubit.state is! ArbInitial) {
        _arbCubit.reset();
      }
    });
  }

  late final PathCubit _pathCubit;
  late final ArbCubit _arbCubit;
  late final StreamSubscription<PathState> pathSubscription;
  late final StreamSubscription<TranslationState> translationSubscription;

  Future<void> checkArbExcelDifference() async {
    try {
      dashAnimationNotifier.value = DashAnimationState.slowDance;
      emit(TranslationGenerating());

      final String excelPath = _pathCubit.excelFilePathController.text;
      final String arbPath = _pathCubit.arbFilePathController.text;

      ArbData arbData = await Isolate.run(() {
        return ArbService().getArbExcelDifference([excelPath, arbPath]);
      });

      emit(TranslationDone(arbData: arbData));
    } catch (e) {
      emit(TranslationError(errorMessage: e.toString()));
    } finally {
      dashAnimationNotifier.value = DashAnimationState.idle;
    }
  }

  @override
  Future<void> close() {
    pathSubscription.cancel();
    translationSubscription.cancel();
    return super.close();
  }
}

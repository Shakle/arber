import 'dart:async';
import 'dart:isolate';

import 'package:arber/data/models/arb_data.dart';
import 'package:arber/logic/blocs/arb/arb_cubit.dart';
import 'package:arber/logic/blocs/path/path_cubit.dart';
import 'package:arber/services/arb_service.dart';
import 'package:arber/view/widgets/animations/dash.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'translation_state.dart';

class TranslationCubit extends Cubit<TranslationState> {
  TranslationCubit({
    required PathCubit pathCubit,
    required this._arbCubit,
    Future<ArbData> Function(String, String)? checkDifference,
  }) : _pathCubit = pathCubit,
       _checkDifference = checkDifference ?? _checkArbExcelDifference,
       super(TranslationInitial()) {
    _paths = _readPaths();
    _pathControllers = [
      pathCubit.excelFilePathController,
      pathCubit.arbFilePathController,
      pathCubit.l10nDirPathController,
    ];
    for (final controller in _pathControllers) {
      controller.addListener(_onPathsChanged);
    }
    _pathSubscription = pathCubit.stream.listen((event) {
      if (!_closing && event is! PathConnected) _invalidateCheck();
    });
    _translationSubscription = stream.listen((event) {
      if (!_arbCubit.isClosed &&
          (_arbCubit.state is ArbDone || _arbCubit.state is ArbFailed)) {
        _arbCubit.reset();
      }
    });
  }

  final PathCubit _pathCubit;
  final ArbCubit _arbCubit;
  final Future<ArbData> Function(String, String) _checkDifference;
  late final List<TextEditingController> _pathControllers;
  late final StreamSubscription<PathState> _pathSubscription;
  late final StreamSubscription<TranslationState> _translationSubscription;
  late (String, String, String) _paths;
  int _requestId = 0;
  bool _closing = false;
  Object? _animationActivity;

  (String, String, String) _readPaths() => (
    _pathCubit.excelFilePathController.text,
    _pathCubit.arbFilePathController.text,
    _pathCubit.l10nDirPathController.text,
  );

  void _onPathsChanged() {
    if (_closing || isClosed) return;
    final paths = _readPaths();
    if (paths == _paths) return; // Selection changes do not change the inputs.
    _paths = paths;
    _invalidateCheck();
  }

  void _invalidateCheck() {
    _requestId++;
    _releaseAnimation();
    if (!_closing && !isClosed) emit(TranslationInitial());
  }

  void _releaseAnimation() {
    final activity = _animationActivity;
    _animationActivity = null;
    if (activity != null) endDashActivity(activity);
  }

  Future<void> checkArbExcelDifference() async {
    if (_closing || isClosed) return;
    final requestId = ++_requestId;
    final paths = _readPaths();
    _releaseAnimation();
    final activity = beginDashActivity();
    _animationActivity = activity;

    bool isCurrent() =>
        !_closing &&
        !isClosed &&
        requestId == _requestId &&
        paths == _readPaths();

    try {
      emit(TranslationGenerating());
      final arbData = await _checkDifference(paths.$1, paths.$2);
      if (isCurrent()) emit(TranslationDone(arbData: arbData));
    } catch (e) {
      if (isCurrent()) emit(TranslationError(errorMessage: e.toString()));
    } finally {
      if (identical(_animationActivity, activity)) _animationActivity = null;
      endDashActivity(activity);
    }
  }

  @override
  Future<void> close() async {
    _closing = true;
    _requestId++;
    for (final controller in _pathControllers) {
      controller.removeListener(_onPathsChanged);
    }
    _releaseAnimation();
    await Future.wait([
      _pathSubscription.cancel(),
      _translationSubscription.cancel(),
    ]);
    await super.close();
  }
}

Future<ArbData> _checkArbExcelDifference(String excelPath, String arbPath) {
  return Isolate.run(
    () => ArbService().getArbExcelDifference([excelPath, arbPath]),
    debugName: 'arber.checkTranslations',
  );
}

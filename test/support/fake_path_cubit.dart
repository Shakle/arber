import 'dart:async';
import 'dart:io';

import 'package:arber/data/models/pathway.dart';
import 'package:arber/logic/blocs/path/path_cubit.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

class FakePathCubit extends Fake implements PathCubit {
  FakePathCubit({
    String excelPath = 'initial.xlsx',
    String arbPath = 'initial.arb',
    String l10nPath = 'l10n',
  }) : excelFilePathController = TextEditingController(text: excelPath),
       arbFilePathController = TextEditingController(text: arbPath),
       l10nDirPathController = TextEditingController(text: l10nPath);

  @override
  final TextEditingController excelFilePathController;
  @override
  final TextEditingController arbFilePathController;
  @override
  final TextEditingController l10nDirPathController;

  final _states = StreamController<PathState>.broadcast();
  PathState _state = PathInitial();
  bool _closed = false;

  @override
  PathState get state => _state;
  @override
  Stream<PathState> get stream => _states.stream;
  @override
  bool get isClosed => _closed;

  void updateState(PathState state) {
    _state = state;
    _states.add(state);
  }

  void connect() {
    updateState(
      PathConnected(
        pathArtifact: PathArtifact(
          excelFile: File(excelFilePathController.text),
          l10nDirectory: l10nDirPathController.text,
        ),
        failedArtifacts: const [],
      ),
    );
  }

  @override
  Future<void> close() async {
    _closed = true;
    await _states.close();
    excelFilePathController.dispose();
    arbFilePathController.dispose();
    l10nDirPathController.dispose();
  }
}

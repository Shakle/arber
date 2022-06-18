import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

part 'arb_state.dart';

class ArbCubit extends Cubit<ArbState> {
  ArbCubit() : super(ArbInitial());
}

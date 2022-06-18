part of 'arb_cubit.dart';

@immutable
abstract class ArbState {}

class ArbInitial extends ArbState {}

class ArbGenerating extends ArbState {}

class ArbDone extends ArbState {}

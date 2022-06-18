import 'package:arber/logic/blocs/path/path_cubit.dart';
import 'package:arber/theme/theme.dart';
import 'package:arber/view/screens/main_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class Application extends StatelessWidget {
  const Application({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Arber',
      theme: AppTheme.lightTheme,
      home: BlocProvider<PathCubit>(
        create: (context) => PathCubit(),
        child: const MainScreen(),
      ),
    );
  }
}

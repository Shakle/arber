import 'package:arber/logic/blocs/update/update_cubit.dart';
import 'package:arber/theme/borders.dart';
import 'package:arber/theme/colors.dart';
import 'package:arber/view/widgets/animations/dash.dart';
import 'package:arber/view/widgets/background_field.dart';
import 'package:arber/view/widgets/buttons/app_back_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: backgroundGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Stack(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.18,
              child: const Align(
                alignment: Alignment(-1, 0.3),
                child: Padding(
                  padding: EdgeInsets.only(left: 16),
                  child: AppBackButton(),
                ),
              ),
            ),
            Center(child: generalLayout()),
          ],
        ),
      ),
    );
  }

  Widget generalLayout() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: constraints.maxWidth * 0.4,
            maxHeight: constraints.maxHeight * 0.35,
          ),
          child: BlocConsumer<UpdateCubit, UpdateState>(
            listenWhen: (pState, state) => state is UpdateSuccess,
            listener: (context, state) => showSuccessMessage(context),
            builder: (context, state) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: switch (state) {
                  UpdateChecked(
                      :String currentVersion,
                      :String availableVersion,
                      :bool isUpdateAvailable,
                  ) =>
                      layout(
                        currentVersion: currentVersion,
                        availableVersion: availableVersion,
                        isUpdateAvailable: isUpdateAvailable,
                      ),
                  UpdateInstalling(
                      :double updatePercent,
                  ) => updateLayout(updatePercent),
                  UpdateError(:String message) => errorLayout(
                    context,
                    message,
                  ),
                  _ => loading(),
                },
              );
            },
          ),
        );
      },
    );
  }

  Widget errorLayout(BuildContext context, String message) {
    return BackgroundField(
      borderRadius: allRoundBorderRadius,
      child: ListView(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Error', style: Theme.of(context).textTheme.headlineSmall),
              IconButton(
                onPressed: () {
                  context.read<UpdateCubit>().checkForUpdate();
                },
                tooltip: 'Retry',
                icon: const Icon(Icons.refresh, color: smoothBlue),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SelectableText(message),
        ],
      ),
    );
  }

  Widget updateLayout(double completePercent) {
    return BackgroundField(
      borderRadius: allRoundBorderRadius,
      padding: const EdgeInsets.all(20),
      child: SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 15,
          children: [
            const DashAnimation(initialAnimation: DashAnimationState.slowDance),
            const Text('Downloading...'),
            const SizedBox(height: 5),
            SizedBox(
              width: 250,
              child: LinearProgressIndicator(
                color: smoothBlue,
                value: completePercent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget loading() {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      spacing: 20,
      children: [
        DashAnimation(initialAnimation: DashAnimationState.slowDance),
        Text('Loading...'),
      ],
    );
  }

  Widget layout({
    required String currentVersion,
    required String availableVersion,
    required bool isUpdateAvailable,
  }) {
    final String newVersion = isUpdateAvailable
        ? 'Available version: $availableVersion'
        : 'No updates available';

    return SizedBox(
      width: double.infinity,
      child: BackgroundField(
        borderRadius: allRoundBorderRadius,
        child: Center(
          child: Column(
            spacing: 10,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Current version: $currentVersion'),
              Text(newVersion),

              if (isUpdateAvailable) ...[
                const SizedBox(height: 20),
                updateButton(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget updateButton() {
    return Builder(
      builder: (context) {
        return TextButton(
          onPressed: () {
            context.read<UpdateCubit>().update();
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: smoothBlue,
            padding: const EdgeInsets.all(20),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text('Download'),
        );
      },
    );
  }

  void showSuccessMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        content: const Row(
          children: [
            Icon(Icons.done, color: Colors.white),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'New version is downloaded to Downloads folder',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: smoothBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

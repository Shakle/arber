import 'package:arber/logic/blocs/update/update_cubit.dart';
import 'package:arber/theme/borders.dart';
import 'package:arber/theme/colors.dart';
import 'package:arber/view/widgets/animations/dash.dart';
import 'package:arber/view/widgets/background_field.dart';
import 'package:arber/view/widgets/buttons/app_back_button.dart';
import 'package:material_ui/material_ui.dart';
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
          child: BlocBuilder<UpdateCubit, UpdateState>(
            builder: (context, state) {
              return AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: switch (state) {
                  UpdateChecked checked => layout(checked),
                  UpdateDownloading(
                      :double updatePercent,
                  ) => downloadLayout(updatePercent),
                  UpdateApplying() => applyingLayout(),
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

  Widget downloadLayout(double completePercent) {
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

  Widget applyingLayout() {
    return BackgroundField(
      borderRadius: allRoundBorderRadius,
      padding: const EdgeInsets.all(20),
      child: const SizedBox(
        width: double.infinity,
        height: double.infinity,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          spacing: 15,
          children: [
            DashAnimation(initialAnimation: DashAnimationState.slowDance),
            Text('Installing...'),
            SizedBox(height: 5),
            Text(
              'Arber will restart in a moment',
              textAlign: TextAlign.center,
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

  Widget layout(UpdateChecked state) {
    final String newVersion = state.isNewerVersionAvailable
        ? 'Available version: ${state.availableVersion}'
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
              Text('Current version: ${state.currentVersion}'),
              Text(newVersion),

              if (state.isUpdateAvailable) ...[
                const SizedBox(height: 20),
                updateButton(),
              ],

              // A newer release exists but ships no build for this platform —
              // Windows builds are published irregularly.
              if (state.isUpdateUnavailableHere) ...[
                const SizedBox(height: 10),
                const Text(
                  'No build for this platform in that release yet',
                  textAlign: TextAlign.center,
                ),
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
          child: const Text('Update & restart'),
        );
      },
    );
  }
}

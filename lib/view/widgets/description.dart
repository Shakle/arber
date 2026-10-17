import 'package:arber/data/constants.dart';
import 'package:arber/theme/borders.dart';
import 'package:arber/theme/colors.dart';
import 'package:material_ui/material_ui.dart';

const _steps = [
  (
    title: 'Prepare the spreadsheet',
    detail: 'Share and edit the .xlsx with your team, then download a copy.',
  ),
  (
    title: 'Choose Excel and Output',
    detail: 'Select the .xlsx file and your project’s l10n folder.',
  ),
  (
    title: 'Add a reference ARB',
    detail: 'Select an ARB to compare keys with Excel in both directions. This is optional.',
  ),
  (
    title: 'Check what’s missing',
    detail: 'Click refresh on the left. Use the blue icon to switch between missing translations and ARB keys.',
  ),
  (
    title: 'Create translations',
    detail:
        'Generate new .arb files in Output. Existing .arb files are replaced.',
  ),
];

class Description extends StatelessWidget {
  const Description({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Tooltip(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: allRoundBorderRadius,
        boxShadow: const [lightShadow],
      ),
      padding: const EdgeInsets.all(24),
      margin: EdgeInsets.only(right: size.width * 0.08),
      verticalOffset: 0,
      ignorePointer: false,
      enableTapToDismiss: false,
      richMessage: TextSpan(
        text: '',
        semanticsLabel:
            'How to use Arber. ${_steps.map((step) => '${step.title}. ${step.detail}').join(' ')}',
        children: [
          WidgetSpan(
            child: SizedBox(
              width: (size.width * 0.84 - 48).clamp(0.0, 360.0),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxHeight: (size.height - 112).clamp(0.0, double.infinity),
                ),
                child: const _Instructions(),
              ),
            ),
          ),
        ],
      ),
      child: SizedBox(height: size.height * 0.15, width: size.height * 0.16),
    );
  }
}

class _Instructions extends StatelessWidget {
  const _Instructions();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How to use Arber',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'From Excel to Flutter translations',
            style: TextStyle(
              fontSize: 11,
              color: Colors.black45,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(height: 22),
          for (var index = 0; index < _steps.length; index++)
            Padding(
              padding: EdgeInsets.only(
                bottom: index == _steps.length - 1 ? 0 : 16,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 22,
                    height: 22,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: smoothBlue.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: smoothBlue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _steps[index].title,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                            color: Colors.black87,
                            letterSpacing: 0,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _steps[index].detail,
                          style: const TextStyle(
                            fontSize: 11,
                            height: 1.5,
                            color: Colors.black54,
                            letterSpacing: 0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 20),
          const Divider(height: 1, color: Colors.black12),
          const SizedBox(height: 12),
          Text(
            'Arber ${packageInfo.version}',
            style: const TextStyle(
              fontSize: 10,
              color: Colors.black38,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

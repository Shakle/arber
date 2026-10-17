import 'package:arber/theme/colors.dart';
import 'package:material_ui/material_ui.dart';

class InfoNote extends StatelessWidget {
  const InfoNote({super.key, required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: smoothBlue.withValues(alpha: 0.045),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.info_outline_rounded, size: 14, color: smoothBlue),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              message,
              style: const TextStyle(
                fontSize: 11,
                height: 1.35,
                fontWeight: FontWeight.w400,
                letterSpacing: 0,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

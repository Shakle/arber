import 'package:arber/data/constants.dart';
import 'package:arber/theme/borders.dart';
import 'package:arber/theme/colors.dart';
import 'package:flutter/material.dart';

class Description extends StatelessWidget {
  const Description({super.key});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: allRoundBorderRadius,
        boxShadow: const [lightShadow],
      ),
      padding: const EdgeInsets.all(20),
      margin: EdgeInsets.only(right: MediaQuery.of(context).size.width * 0.08),
      verticalOffset: 0,
      richMessage: TextSpan(
        children: [
          const TextSpan(
            style: TextStyle(color: Colors.black, fontSize: 14),
            text:
                'Hi 🐦, this is how to use it.'
                '\n\n1. Share .xlsx file across your team'
                '\n2. Edit it online in a browser'
                '\n3. Download a copy of .xlsx'
                '\n4. Choose the file in first input'
                '\n5. Choose project l10n directory in the second one'
                '\n6. Choose main arb file to match if something is missing in excel'
                '\n7. Click refresh on the left to see any missing translations'
                '\n8. Click create translations to put new .arb files to your project'
                '\n\nThanks for using ❤️',
          ),
          TextSpan(
            style: const TextStyle(color: Colors.grey),
            text: '\n\nversion: ${packageInfo.version}',
          ),
        ],
      ),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.15,
        width: MediaQuery.of(context).size.height * 0.16,
      ),
    );
  }
}

import 'package:flutter/material.dart';

class ArbButton extends StatelessWidget {
  const ArbButton({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return generateArbButton();
  }

  Widget generateArbButton() {
    return TextButton(
        style: TextButton.styleFrom(
          backgroundColor: Colors.blue,
          primary: Colors.white,
          padding: const EdgeInsets.all(20),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
          ),
        ),
        onPressed: () {},
        child: const Text('Create Arb files'),
    );
  }
}

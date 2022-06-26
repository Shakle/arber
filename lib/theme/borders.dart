import 'package:flutter/material.dart';

BorderRadius get leftRoundBorderRadius {
  return const BorderRadius.only(
    topLeft: Radius.circular(15),
    bottomLeft: Radius.circular(15),
  );
}

BorderRadius get rightRoundBorderRadius {
  return const BorderRadius.only(
    topRight: Radius.circular(15),
    bottomRight: Radius.circular(15),
  );
}
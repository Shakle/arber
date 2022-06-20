import 'package:flutter/material.dart';

const Color whiteBlue = Color(0xffd7e7f9);
const Color lightBlue = Color(0xffcce7f8);
const Color smoothBlue = Color(0xff5ca5f8);

const LinearGradient backgroundGradient = LinearGradient(
  colors: [whiteBlue, lightBlue],
  begin: Alignment.topCenter,
  end: Alignment.bottomCenter,
  stops: [0, 0.4],
);

const BoxShadow lightShadow = BoxShadow(
  color: Colors.black12,
  blurRadius: 20,
  offset: Offset(0, 4),
);
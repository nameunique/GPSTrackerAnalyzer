import 'package:flutter/widgets.dart';

abstract final class AppRadii {
  const AppRadii._();

  static const double small = 12;
  static const double medium = 16;
  static const double large = 20;
  static const double extraLarge = 24;
  static const double full = 999;

  static const BorderRadius smallBorder = BorderRadius.all(
    Radius.circular(small),
  );
  static const BorderRadius mediumBorder = BorderRadius.all(
    Radius.circular(medium),
  );
  static const BorderRadius largeBorder = BorderRadius.all(
    Radius.circular(large),
  );
  static const BorderRadius extraLargeBorder = BorderRadius.all(
    Radius.circular(extraLarge),
  );
  static const BorderRadius fullBorder = BorderRadius.all(
    Radius.circular(full),
  );
}

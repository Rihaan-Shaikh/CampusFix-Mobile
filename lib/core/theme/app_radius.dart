import 'package:flutter/material.dart';

/// Systematic corner radii for component shapes.
abstract final class AppRadius {
  static const double sm = 6.0;
  static const double md = 10.0;
  static const double lg = 14.0;
  static const double xl = 20.0;
  static const double full = 999.0;

  static const BorderRadius smBorderRadius = BorderRadius.all(
    Radius.circular(sm),
  );
  static const BorderRadius mdBorderRadius = BorderRadius.all(
    Radius.circular(md),
  );
  static const BorderRadius lgBorderRadius = BorderRadius.all(
    Radius.circular(lg),
  );
  static const BorderRadius xlBorderRadius = BorderRadius.all(
    Radius.circular(xl),
  );
  static const BorderRadius fullBorderRadius = BorderRadius.all(
    Radius.circular(full),
  );
}

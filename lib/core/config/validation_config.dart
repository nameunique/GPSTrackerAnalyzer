/// Criteria for the "Valid" stamp on the performance report.
abstract final class ValidationConfig {
  static const int minFixTypeForValid = 3;
  static const int minSatellitesForValid = 4;
  static const double minValidSampleRatio = 0.7;
}

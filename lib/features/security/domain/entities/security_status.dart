class SecurityStatus {
  final bool isRooted;
  final bool isEmulator;
  final bool isDevModeActive;
  final bool isVpnActive;
  final int overallRiskScore;

  const SecurityStatus({
    required this.isRooted,
    required this.isEmulator,
    required this.isDevModeActive,
    required this.isVpnActive,
    required this.overallRiskScore,
  });
}

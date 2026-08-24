import '../../domain/entities/security_status.dart';
import '../../domain/repositories/security_repository.dart';

class SecurityRepositoryImpl implements SecurityRepository {
  const SecurityRepositoryImpl();

  @override
  Future<SecurityStatus> checkDeviceIntegrity() async {
    // Return a mock security status for development
    return const SecurityStatus(
      isRooted: false,
      isEmulator: false,
      isDevModeActive: true, // Dev mode active in debug builds
      isVpnActive: false,
      overallRiskScore: 25,
    );
  }

  @override
  Future<bool> isMockProviderDetected() async {
    return false;
  }
}

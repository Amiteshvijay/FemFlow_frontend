class BiometricService {
  // Biometrics removed as of now.
  // We keep the structure for potential future re-implementation.
  // final LocalAuthentication _auth = LocalAuthentication();

  Future<bool> canCheckBiometrics() async {
    return false;
  }

  Future<dynamic> getAvailableBiometrics() async {
    return [];
  }

  Future<bool> authenticate() async {
    return false;
  }
}

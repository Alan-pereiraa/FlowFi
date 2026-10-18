abstract interface class DeviceRepository {
  Future<void> register(String token);

  Future<void> unregister(String token);
}

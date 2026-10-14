import 'package:pos_app/data/db/app_database.dart';

/// Lokal sozlamalar kalitlari.
abstract final class SettingKeys {
  static const String deviceId = 'device_id';
  static const String deviceNumber = 'device_number';
  static const String deviceName = 'device_name';
  static const String storeId = 'store_id';

  /// Ro'yxatdan o'tish javobi kelmay qolsa, qayta urinishda shu ID
  /// ishlatiladi — server yangi qurilma yaratmaydi (`devices.md`).
  static const String pendingDeviceId = 'pending_device_id';

  /// Avtomatik qulflash (daqiqa; 0 — o'chiq).
  static const String autoLockMinutes = 'auto_lock_minutes';
}

/// Ulangan qurilma haqida (chek raqami prefiksi, do'kon).
class DeviceInfo {
  const DeviceInfo({
    required this.id,
    required this.number,
    required this.name,
    required this.storeId,
  });

  final String id;

  /// Tenant ichida tartib raqami: chek `D{number}-000123`.
  final int number;
  final String name;
  final String storeId;

  static Future<DeviceInfo?> load(AppDatabase db) async {
    final id = await db.readSetting(SettingKeys.deviceId);
    final number = int.tryParse(
      await db.readSetting(SettingKeys.deviceNumber) ?? '',
    );
    if (id == null || number == null) return null;
    return DeviceInfo(
      id: id,
      number: number,
      name: await db.readSetting(SettingKeys.deviceName) ?? '',
      storeId: await db.readSetting(SettingKeys.storeId) ?? '',
    );
  }

  Future<void> save(AppDatabase db) => db.transaction(() async {
    await db.writeSetting(SettingKeys.deviceId, id);
    await db.writeSetting(SettingKeys.deviceNumber, '$number');
    await db.writeSetting(SettingKeys.deviceName, name);
    await db.writeSetting(SettingKeys.storeId, storeId);
    await (db.delete(
      db.localSettings,
    )..where((t) => t.key.equals(SettingKeys.pendingDeviceId))).go();
  });
}

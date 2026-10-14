import 'package:uuid/uuid.dart';

/// Klientda yaratiladigan ID'lar — UUIDv7 (vaqt bo'yicha tartiblanadi).
typedef IdGenerator = String Function();

const Uuid _uuid = Uuid();

String newId() => _uuid.v7();

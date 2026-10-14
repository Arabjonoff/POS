// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';

import 'clients/auth_client.dart';
import 'clients/devices_client.dart';
import 'clients/sync_client.dart';

/// POS API `v1.0.0`.
///
/// Mahalla do'konlari uchun kassa va ombor tizimi API.
class PosApi {
  PosApi(
    Dio dio, {
    String? baseUrl,
  })  : _dio = dio,
        _baseUrl = baseUrl;

  final Dio _dio;
  final String? _baseUrl;

  static String get version => '1.0.0';

  AuthClient? _auth;
  DevicesClient? _devices;
  SyncClient? _sync;

  AuthClient get auth => _auth ??= AuthClient(_dio, baseUrl: _baseUrl);

  DevicesClient get devices => _devices ??= DevicesClient(_dio, baseUrl: _baseUrl);

  SyncClient get sync => _sync ??= SyncClient(_dio, baseUrl: _baseUrl);
}

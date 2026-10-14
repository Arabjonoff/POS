// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, unused_import, invalid_annotation_target, unnecessary_import

import 'package:dio/dio.dart';
import 'package:retrofit/retrofit.dart';

import '../models/login_request.dart';
import '../models/login_response.dart';
import '../models/me.dart';
import '../models/token_refresh.dart';
import '../models/token_refresh_request.dart';

part 'auth_client.g.dart';

@RestApi()
abstract class AuthClient {
  factory AuthClient(Dio dio, {String? baseUrl}) = _AuthClient;

  /// Telefon + parol → JWT (ega, menejer, platforma admini).
  @POST('/api/v1/auth/login/')
  Future<LoginResponse> authLoginCreate({
    @Body() required LoginRequest body,
  });

  @GET('/api/v1/auth/me/')
  Future<Me> authMeRetrieve();

  /// Takes a refresh type JSON web token and returns an access type JSON web.
  /// token if the refresh token is valid.
  @POST('/api/v1/auth/refresh/')
  Future<TokenRefresh> authRefreshCreate({
    @Body() required TokenRefreshRequest body,
  });
}

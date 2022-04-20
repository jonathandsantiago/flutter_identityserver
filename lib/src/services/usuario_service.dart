import 'dart:convert';

import 'package:flutter_identityserver/src/models/user.dart';
import 'package:flutter_identityserver/src/secrets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_appauth/flutter_appauth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// -----------------------------------
///           Auth0 Variables
/// -----------------------------------
const String AUTH_CLIENT_ID = Secrets.AUTH_CLIENT_ID;
const String AUTH_DOMAIN = Secrets.AUTH_DOMAIN;
const String AUTH_REDIRECT_URI = Secrets.AUTH_REDIRECT_URI;
const String AUTH_ISSUER = Secrets.AUTH_ISSUER;
const String AUTH_SECRET = Secrets.AUTH_SECRET;

class UsuarioService {
  final FlutterAppAuth _appAuth = FlutterAppAuth();
  final FlutterSecureStorage secureStorage = const FlutterSecureStorage();

  final List<String> _scopes = <String>[
    'openid',
    'offline_access',
    'profile',
    'email',
    'offline_access'
  ];

  final AuthorizationServiceConfiguration _serviceConfiguration =
      const AuthorizationServiceConfiguration(
    authorizationEndpoint: 'https://$AUTH_DOMAIN/connect/authorize',
    tokenEndpoint: 'https://$AUTH_DOMAIN/connect/token',
    endSessionEndpoint: 'https://$AUTH_DOMAIN/connect/endsession',
  );

  Future<UserAuth?> login() async {
    try {
      final AuthorizationTokenResponse? result =
          await _appAuth.authorizeAndExchangeCode(
        AuthorizationTokenRequest(
          AUTH_CLIENT_ID,
          AUTH_REDIRECT_URI,
          serviceConfiguration: _serviceConfiguration,
          clientSecret: AUTH_SECRET,
          scopes: _scopes,
          preferEphemeralSession: false,
        ),
      );

      if (result != null) {
        var usuario = UserAuth();
        usuario.accessToken = result.accessToken!;
        usuario.idToken = parseIdToken(result.idToken!);
        usuario.refreshToken = result.refreshToken!;
        usuario.profile = await getUserInfo(usuario.accessToken!);

        await secureStorage.write(
            key: 'refresh_token', value: result.refreshToken);
        await secureStorage.write(key: 'idToken', value: result.idToken!);
        return usuario;
      }
    } on Exception catch (e, s) {
      debugPrint('login error: $e - stack: $s');
    }
    return null;
  }

  Map<String, dynamic> parseIdToken(String idToken) {
    final List<String> parts = idToken.split('.');
    assert(parts.length == 3);

    return json
        .decode(utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))));
  }

  Future<Map<String, dynamic>> getUserInfo(String accessToken) async {
    const String url = 'https://$AUTH_DOMAIN/connect/userinfo';
    final http.Response response = await http.get(
      Uri.parse(url),
      headers: <String, String>{'Authorization': 'Bearer $accessToken'},
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get user details');
    }
  }

  Future<void> logout() async {
    try {
      final String? idToken = await secureStorage.read(key: 'idToken');
      if (idToken != null) {
        await _appAuth.endSession(EndSessionRequest(
            idTokenHint: idToken,
            postLogoutRedirectUrl: AUTH_REDIRECT_URI,
            serviceConfiguration: _serviceConfiguration));
      }
      await secureStorage.delete(key: 'refresh_token');
      await secureStorage.delete(key: 'idToken');
    } on Exception catch (e, s) {
      debugPrint('error on refresh token: $e - stack: $s');
      await logout();
    }
  }

  Future<UserAuth?> init(String storedRefreshToken) async {
    try {
      final TokenResponse? response = await _appAuth.token(TokenRequest(
        AUTH_CLIENT_ID,
        AUTH_REDIRECT_URI,
        issuer: AUTH_ISSUER,
        clientSecret: AUTH_SECRET,
        scopes: _scopes,
        refreshToken: storedRefreshToken,
      ));

      if (response != null) {
        var usuario = UserAuth();
        usuario.accessToken = response.accessToken!;
        usuario.idToken = parseIdToken(response.idToken!);
        usuario.refreshToken = response.refreshToken!;
        usuario.profile = await getUserInfo(usuario.accessToken!);

        await secureStorage.write(key: 'idToken ', value: response.idToken);
        await secureStorage.write(
            key: 'refresh_token', value: response.refreshToken);

        return usuario;
      }

      return null;
    } on Exception catch (e, s) {
      debugPrint('error on refresh token: $e - stack: $s');
      await logout();
    }
    return null;
  }

  void dispose() async {}
}

import 'dart:convert';
import 'dart:io';

import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

/// Authentication method for Google Client.
enum AuthMethod {
  /// Uses service account JSON credentials for authentication.
  serviceAccount,

  /// Uses Application Default Credentials from the environment.
  defaultCredentials,

  /// Uses OAuth2 user consent flow for authentication.
  userConsent,

  /// No authentication (for emulator or unauthenticated use).
  unauthenticated,
}

/// A client for authenticating with Google Cloud services.
class GoogleClient {
  /// Creates a new GoogleClient with the provided service account JSON credentials.
  GoogleClient({
    required String serviceAccountJson,
    List<String>? scopes,
  })  : _credentials = jsonDecode(serviceAccountJson),
        _authMethod = AuthMethod.serviceAccount,
        _clientId = null,
        _scopes = scopes ?? _defaultScopes;

  /// Creates a new GoogleClient that uses Application Default Credentials (ADC).
  /// This constructor should be used when running in Google Cloud environments
  /// where the default service account is available.
  GoogleClient.defaultCredentials({
    List<String>? scopes,
  })  : _credentials = null,
        _authMethod = AuthMethod.defaultCredentials,
        _clientId = null,
        _scopes = scopes ?? _defaultScopes;

  /// Creates a new GoogleClient that uses OAuth2 user consent flow.
  /// This constructor should be used for CLI applications where a user needs to
  /// authorize access to their Google resources.
  /// 
  /// The [clientId] and [clientSecret] can be obtained from the Google Cloud Console.
  /// The user will be prompted to visit a URL and grant access.
  GoogleClient.userConsent({
    required String clientId,
    required String clientSecret,
    List<String>? scopes,
  })  : _credentials = null,
        _authMethod = AuthMethod.userConsent,
        _clientId = ClientId(clientId, clientSecret),
        _scopes = scopes ?? _defaultScopes;

  /// Creates a new GoogleClient for unauthenticated use.
  /// This constructor returns an unauthenticated client suitable for
  /// connecting to the Firestore emulator or other unauthenticated endpoints.
  GoogleClient.unauthenticated()
      : _credentials = null,
        _authMethod = AuthMethod.unauthenticated,
        _clientId = null,
        _scopes = [];

  static const _defaultScopes = ['https://www.googleapis.com/auth/cloud-platform'];

  final dynamic _credentials;
  final AuthMethod _authMethod;
  final ClientId? _clientId;
  final List<String> _scopes;

  /// The OAuth 2.0 scopes required for Google Cloud Platform access.
  List<String> get scopes => _scopes;

  /// Returns an authenticated HTTP client for making requests to Google Cloud services.
  /// For emulator mode, returns an unauthenticated client.
  Future<http.Client> getClient() async {
    switch (_authMethod) {
      case AuthMethod.serviceAccount:
        return clientViaServiceAccount(
          ServiceAccountCredentials.fromJson(_credentials),
          scopes,
        );
      case AuthMethod.defaultCredentials:
        return clientViaApplicationDefaultCredentials(scopes: scopes);
      case AuthMethod.userConsent:
        return clientViaUserConsent(
          _clientId!,
          scopes,
          _promptUserForConsent,
        );
      case AuthMethod.unauthenticated:
        // Return a plain HTTP client for unauthenticated use
        return http.Client();
    }
  }

  /// Prompts the user to visit a URL for OAuth consent.
  /// This is used for CLI applications where the user manually opens the URL.
  void _promptUserForConsent(String url) {
    stdout
      ..writeln('\nPlease visit the following URL to authorize access:')
      ..writeln('\n  $url\n')
      ..writeln('Waiting for authorization...');
  }
}

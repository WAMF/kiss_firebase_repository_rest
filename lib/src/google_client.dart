import 'dart:convert';

import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

/// A client for authenticating with Google Cloud services using service account credentials.
class GoogleClient {
  /// Creates a new GoogleClient with the provided service account JSON credentials.
  GoogleClient({required String serviceAccountJson}) {
    _credentials = jsonDecode(serviceAccountJson);
  }
  late final dynamic _credentials;
  /// The OAuth 2.0 scopes required for Google Cloud Platform access.
  final scopes = ['https://www.googleapis.com/auth/cloud-platform'];

  /// Returns an authenticated HTTP client for making requests to Google Cloud services.
  Future<http.Client> getClient() async {
    return clientViaServiceAccount(
      ServiceAccountCredentials.fromJson(_credentials),
      scopes,
    );
  }
}

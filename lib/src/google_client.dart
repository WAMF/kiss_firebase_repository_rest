import 'dart:convert';

import 'package:googleapis_auth/auth_io.dart';
import 'package:http/http.dart' as http;

class GoogleClient {
  GoogleClient({required String serviceAccountJson}) {
    _credentials = jsonDecode(serviceAccountJson);
  }
  late final dynamic _credentials;
  final scopes = ['https://www.googleapis.com/auth/cloud-platform'];

  Future<http.Client> getClient() async {
    return clientViaServiceAccount(
      ServiceAccountCredentials.fromJson(_credentials),
      scopes,
    );
  }
}

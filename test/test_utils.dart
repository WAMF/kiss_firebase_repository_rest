import 'package:googleapis/firestore/v1.dart';
import 'package:http/http.dart' as http;
import 'package:kiss_firebase_repository_rest/kiss_firebase_repository_rest.dart';

/// Test utilities for Firebase emulator setup
class TestUtils {
  static const String emulatorHost = '127.0.0.1';
  static const int emulatorPort = 8080;
  static const String testProjectId = 'test-project';

  /// Creates a FirestoreApi that connects to the emulator
  static Future<FirestoreApi> createEmulatorFirestoreApi() async {
    // Use the unauthenticated constructor for GoogleClient
    final googleClient = GoogleClient.unauthenticated();
    final httpClient = await googleClient.getClient();

    // Override the base URL to point to emulator
    const emulatorUrl = 'http://$emulatorHost:$emulatorPort';

    return FirestoreApi(httpClient, rootUrl: '$emulatorUrl/');
  }


  /// Clears all data from the emulator
  static Future<void> clearEmulatorData() async {
    try {
      final response = await http.delete(
        Uri.parse(
          'http://$emulatorHost:$emulatorPort/emulator/v1/projects/$testProjectId/databases/(default)/documents',
        ),
      );
      if (response.statusCode != 200) {
        print('Warning: Failed to clear emulator data: ${response.statusCode}');
      }
      // Add a small delay to ensure the operation completes
      await Future<void>.delayed(const Duration(milliseconds: 100));
    } on Exception catch (e) {
      print('Warning: Could not clear emulator data: $e');
    }
  }

  /// Checks if the Firebase emulator is running
  static Future<bool> isEmulatorRunning() async {
    try {
      final response = await http
          .get(Uri.parse('http://$emulatorHost:$emulatorPort/'))
          .timeout(const Duration(seconds: 2));
      return response.statusCode == 200;
    } on Exception {
      return false;
    }
  }

  /// Waits for the emulator to be ready
  static Future<void> waitForEmulator({
    Duration timeout = const Duration(seconds: 30),
  }) async {
    final endTime = DateTime.now().add(timeout);

    while (DateTime.now().isBefore(endTime)) {
      if (await isEmulatorRunning()) {
        return;
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }

    throw Exception(
      'Firebase emulator did not start within ${timeout.inSeconds} seconds',
    );
  }

}

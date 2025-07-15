import 'package:googleapis/firestore/v1.dart';
import 'package:http/http.dart' as http;
import 'package:kiss_firebase_repository_rest/kiss_firebase_repository_rest.dart';
import 'package:kiss_repository/kiss_repository.dart';

import 'test_models.dart';

/// Test utilities for Firebase emulator setup
class TestUtils {
  static const String emulatorHost = '127.0.0.1';
  static const int emulatorPort = 8080;
  static const String testProjectId = 'test-project';

  /// Creates a FirestoreApi that connects to the emulator
  static Future<FirestoreApi> createEmulatorFirestoreApi() async {
    // For emulator testing, we don't need real authentication
    // Create a simple HTTP client that works with the emulator
    final httpClient = http.Client();

    // Override the base URL to point to emulator
    const emulatorUrl = 'http://$emulatorHost:$emulatorPort';

    return FirestoreApi(httpClient, rootUrl: '$emulatorUrl/');
  }

  /// Creates a test repository for Users
  static Future<RepositoryFirestoreRestApi<User>> createUserRepository({
    String path = 'users',
  }) async {
    final firestore = await createEmulatorFirestoreApi();

    return RepositoryFirestoreRestApi<User>(
      projectId: testProjectId,
      database: null,
      firestore: firestore,
      toFirestore: UserFirestoreConverters.toFirestore,
      fromFirestore: UserFirestoreConverters.fromFirestore,
      path: path,
      queryBuilder: _TestQueryBuilder(collectionId: path),
    );
  }

  /// Creates a test JSON repository
  static Future<RepositoryFirestoreJsonRestApi> createJsonRepository({
    String path = 'test-collection',
  }) async {
    final firestore = await createEmulatorFirestoreApi();

    return RepositoryFirestoreJsonRestApi(
      projectId: testProjectId,
      firestore: firestore,
      path: path,
    );
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

  /// Creates sample test users
  static List<User> createSampleUsers() {
    return [
      User(
        id: 'user1',
        name: 'John Doe',
        email: 'john@example.com',
        age: 30,
        createdAt: DateTime(2024),
      ),
      User(
        id: 'user2',
        name: 'Jane Smith',
        email: 'jane@example.com',
        age: 25,
        createdAt: DateTime(2024, 1, 2),
      ),
      User(
        id: 'user3',
        name: 'Bob Johnson',
        email: 'bob@example.com',
        createdAt: DateTime(2024, 1, 3),
      ),
    ];
  }
}

class _TestQueryBuilder implements QueryBuilder<RunQueryRequest> {
  _TestQueryBuilder({required String collectionId})
    : _collectionId = collectionId;
  final String _collectionId;

  @override
  RunQueryRequest build(Query query) {
    return RunQueryRequest(
      structuredQuery: StructuredQuery(
        from: [CollectionSelector(collectionId: _collectionId)],
      ),
    );
  }
}

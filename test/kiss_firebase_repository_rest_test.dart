import 'package:kiss_firebase_repository_rest/kiss_firebase_repository_rest.dart';
import 'package:kiss_repository/kiss_repository.dart';
import 'package:test/test.dart';

import 'emulator_test_runner.dart';
import 'test_models.dart';
import 'test_utils.dart';

void main() {
  group('Firebase Repository Integration Tests', () {
    setUpAll(() async {
      // Auto-start Firebase emulator if not running
      await EmulatorTestRunner.startEmulator();
      print('✅ Firebase emulator ready for testing');
    });

    tearDownAll(() async {
      // Ensure complete cleanup of emulator processes
      await EmulatorTestRunner.ensureCleanup();
    });

    group('Repository Factory Tests', () {
      test('should create user repository successfully', () async {
        final repository = await TestUtils.createUserRepository();

        expect(repository.path, equals('users'));
        expect(repository.collectionId, equals('users'));
        expect(repository.collectionParentPath, equals(''));
      });

      test('should create JSON repository successfully', () async {
        final repository = await TestUtils.createJsonRepository();

        expect(repository.path, equals('test-collection'));
      });
    });

    group('End-to-End User Scenarios', () {
      late RepositoryFirestoreRestApi<User> userRepo;

      setUp(() async {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final uniqueCollectionName = 'users-test-$timestamp';
        userRepo = await TestUtils.createUserRepository(
          path: uniqueCollectionName,
        );
      });

      test('should handle complete user lifecycle', () async {
        // Create a new user
        final newUser = User(
          id: 'lifecycle-user',
          name: 'Test User',
          email: 'test@example.com',
          age: 28,
          createdAt: DateTime(2024),
        );

        // Add user
        final addedUser = await userRepo.add(
          IdentifiedObject('lifecycle-user', newUser),
        );
        expect(addedUser.name, equals('Test User'));
        expect(addedUser.email, equals('test@example.com'));

        // Retrieve user
        final retrievedUser = await userRepo.get('lifecycle-user');
        expect(retrievedUser.id, equals('lifecycle-user'));
        expect(retrievedUser.name, equals('Test User'));

        // Update user
        final updatedUser = await userRepo.update('lifecycle-user', (user) {
          return user.copyWith(name: 'Updated User', age: 29);
        });
        expect(updatedUser.name, equals('Updated User'));
        expect(updatedUser.age, equals(29));
        expect(
          updatedUser.email,
          equals('test@example.com'),
        ); // Should remain unchanged

        // Query to verify update
        final allUsers = await userRepo.query();
        expect(allUsers.length, equals(1));
        expect(allUsers.first.name, equals('Updated User'));

        // Delete user
        await userRepo.delete('lifecycle-user');

        // Verify deletion
        expect(
          () => userRepo.get('lifecycle-user'),
          throwsA(
            isA<RepositoryException>().having(
              (e) => e.code,
              'code',
              RepositoryErrorCode.notFound,
            ),
          ),
        );

        // Verify empty collection
        final emptyResult = await userRepo.query();
        expect(emptyResult, isEmpty);
      });

      test('should handle multiple users and batch operations', () async {
        final users = TestUtils.createSampleUsers();

        // Add multiple users
        for (final user in users) {
          await userRepo.add(IdentifiedObject(user.id, user));
        }

        // Query all users
        final allUsers = await userRepo.query();
        expect(allUsers.length, equals(3));

        // Verify all users are present
        final userNames = allUsers.map((u) => u.name).toSet();
        expect(
          userNames,
          containsAll(['John Doe', 'Jane Smith', 'Bob Johnson']),
        );

        // Test auto-identified user addition
        const autoUser = User(
          id: '',
          name: 'Auto User',
          email: 'auto@example.com',
        );

        final addedAutoUser = await userRepo.addAutoIdentified(
          autoUser,
          updateObjectWithId: (user, id) => user.copyWith(id: id),
        );
        expect(addedAutoUser.id, isNotEmpty);
        expect(addedAutoUser.id.length, equals(20));

        // Verify total count
        final finalUsers = await userRepo.query();
        expect(finalUsers.length, equals(4));
      });

      test('should handle error conditions gracefully', () async {
        // Test not found error
        expect(
          () => userRepo.get('non-existent'),
          throwsA(
            isA<RepositoryException>().having(
              (e) => e.code,
              'code',
              RepositoryErrorCode.notFound,
            ),
          ),
        );

        // Test already exists error
        const user = User(
          id: 'duplicate-test',
          name: 'Duplicate User',
          email: 'duplicate@example.com',
        );

        await userRepo.add(IdentifiedObject('duplicate-test', user));

        expect(
          () => userRepo.add(IdentifiedObject('duplicate-test', user)),
          throwsA(
            isA<RepositoryException>().having(
              (e) => e.code,
              'code',
              RepositoryErrorCode.alreadyExists,
            ),
          ),
        );

        // Test update non-existent
        expect(
          () => userRepo.update('non-existent', (user) => user),
          throwsA(
            isA<RepositoryException>().having(
              (e) => e.code,
              'code',
              RepositoryErrorCode.notFound,
            ),
          ),
        );
      });
    });

    group('JSON Repository End-to-End Tests', () {
      late RepositoryFirestoreJsonRestApi jsonRepo;

      setUp(() async {
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final uniqueCollectionName = 'json-test-$timestamp';
        jsonRepo = await TestUtils.createJsonRepository(
          path: uniqueCollectionName,
        );
      });

      test('should handle complex JSON document lifecycle', () async {
        final complexDoc = {
          'id': 'complex-1',
          'title': 'Complex Document',
          'metadata': {
            'author': 'Test Author',
            'created': DateTime.now().toIso8601String(),
            'tags': ['test', 'complex', 'json'],
            'stats': {'views': 0, 'likes': 0},
          },
          'content': {
            'sections': [
              {'title': 'Introduction', 'text': 'This is the intro'},
              {'title': 'Body', 'text': 'This is the main content'},
            ],
          },
        };

        // Add document
        final addedDoc = await jsonRepo.add(
          IdentifiedObject('complex-1', complexDoc),
        );
        expect(addedDoc['title'], equals('Complex Document'));
        final metadata = addedDoc['metadata'] as Map<String, dynamic>;
        expect(metadata['author'], equals('Test Author'));

        // Update document
        final updatedDoc = await jsonRepo.update('complex-1', (doc) {
          final metadata = Map<String, dynamic>.from(doc['metadata'] as Map);
          final stats = Map<String, dynamic>.from(metadata['stats'] as Map);
          stats['views'] = 10;
          metadata['stats'] = stats;

          return {
            ...doc,
            'metadata': metadata,
            'updated': DateTime.now().toIso8601String(),
          };
        });

        final updatedMetadata = updatedDoc['metadata'] as Map<String, dynamic>;
        final updatedStats = updatedMetadata['stats'] as Map<String, dynamic>;
        expect(updatedStats['views'], equals(10));
        expect(updatedDoc['updated'], isNotNull);

        // Query and verify
        final docs = await jsonRepo.query();
        expect(docs.length, equals(1));
        expect(docs.first['title'], equals('Complex Document'));
      });
    });
  });
}

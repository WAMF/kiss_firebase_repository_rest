import 'package:kiss_firebase_repository_rest/kiss_firebase_repository_rest.dart';
import 'package:kiss_repository/kiss_repository.dart';
import 'package:test/test.dart';

import '../test_models.dart';
import '../test_utils.dart';

void main() {
  group('RepositoryFirestoreRestApi Unit Tests', () {
    late Repository<User> repository;

    setUpAll(() async {
      // Wait for emulator to be ready
      if (!await TestUtils.isEmulatorRunning()) {
        fail(
          'Firebase emulator is not running. Please start it with: firebase emulators:start',
        );
      }
    });

    setUp(() async {
      // Use unique collection name for each test
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueCollectionName = 'unit-test-$timestamp';
      repository = await TestUtils.createUserRepository(
        path: uniqueCollectionName,
      );
    });

    group('CRUD Operations', () {
      test('should add and retrieve a user', () async {
        final user = User(
          id: 'test-user',
          name: 'Test User',
          email: 'test@example.com',
          age: 25,
          createdAt: DateTime.now(),
        );

        // Add user
        final addedUser = await repository.add(
          IdentifiedObject('test-user', user),
        );

        // Verify user was added
        expect(addedUser.name, equals(user.name));
        expect(addedUser.email, equals(user.email));
        expect(addedUser.age, equals(user.age));

        // Retrieve user
        final retrievedUser = await repository.get('test-user');
        expect(retrievedUser.id, equals('test-user'));
        expect(retrievedUser.name, equals(user.name));
        expect(retrievedUser.email, equals(user.email));
      });

      test(
        'should throw RepositoryException when getting non-existent user',
        () async {
          expect(
            () => repository.get('non-existent'),
            throwsA(
              isA<RepositoryException>().having(
                (e) => e.code,
                'code',
                RepositoryErrorCode.notFound,
              ),
            ),
          );
        },
      );

      test('should auto-identify and add user', () async {
        const user = User(
          id: '',
          name: 'Auto User',
          email: 'auto@example.com',
          age: 30,
        );

        final addedUser = await repository.addAutoIdentified(
          user,
          updateObjectWithId: (user, id) => user.copyWith(id: id),
        );

        expect(addedUser.name, equals(user.name));
        expect(addedUser.email, equals(user.email));
        expect(addedUser.id, isNotEmpty);
        expect(addedUser.id.length, equals(20)); // Default ID length
      });

      test('should update existing user', () async {
        const user = User(
          id: 'update-user',
          name: 'Original Name',
          email: 'original@example.com',
          age: 25,
        );

        // Add user
        await repository.add(IdentifiedObject('update-user', user));

        // Update user
        final updatedUser = await repository.update('update-user', (
          existingUser,
        ) {
          return existingUser.copyWith(name: 'Updated Name', age: 30);
        });

        expect(updatedUser.name, equals('Updated Name'));
        expect(updatedUser.age, equals(30));
        expect(updatedUser.email, equals('original@example.com')); // Unchanged
      });

      test(
        'should throw RepositoryException when updating non-existent user',
        () async {
          expect(
            () => repository.update('non-existent', (user) => user),
            throwsA(
              isA<RepositoryException>().having(
                (e) => e.code,
                'code',
                RepositoryErrorCode.notFound,
              ),
            ),
          );
        },
      );

      test('should delete user', () async {
        const user = User(
          id: 'delete-user',
          name: 'Delete Me',
          email: 'delete@example.com',
        );

        // Add user
        await repository.add(IdentifiedObject('delete-user', user));

        // Verify user exists
        final retrievedUser = await repository.get('delete-user');
        expect(retrievedUser.name, equals('Delete Me'));

        // Delete user
        await repository.delete('delete-user');

        // Verify user is deleted
        expect(
          () => repository.get('delete-user'),
          throwsA(
            isA<RepositoryException>().having(
              (e) => e.code,
              'code',
              RepositoryErrorCode.notFound,
            ),
          ),
        );
      });

      test('should handle already exists error', () async {
        const user = User(
          id: 'duplicate-user',
          name: 'Duplicate User',
          email: 'duplicate@example.com',
        );

        // Add user first time
        await repository.add(IdentifiedObject('duplicate-user', user));

        // Try to add same user again
        expect(
          () => repository.add(IdentifiedObject('duplicate-user', user)),
          throwsA(
            isA<RepositoryException>().having(
              (e) => e.code,
              'code',
              RepositoryErrorCode.alreadyExists,
            ),
          ),
        );
      });
    });

    group('Query Operations', () {
      setUp(() async {
        // Add sample users for querying
        final users = TestUtils.createSampleUsers();
        for (final user in users) {
          await repository.add(IdentifiedObject(user.id, user));
        }
      });

      test('should query all users', () async {
        final users = await repository.query();

        expect(users.length, equals(3));
        expect(
          users.map((u) => u.name).toSet(),
          equals({'John Doe', 'Jane Smith', 'Bob Johnson'}),
        );
      });

      test('should return empty list when no users exist', () async {
        // Create a new repository with unique collection name to ensure it's empty
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final emptyRepo = await TestUtils.createUserRepository(
          path: 'empty-test-$timestamp',
        );

        final users = await emptyRepo.query();
        expect(users, isEmpty);
      });
    });

    group('Path Handling', () {
      test('should handle simple collection path', () async {
        // Path now includes timestamp for test isolation, so check the pattern
        expect(repository.path, matches(r'^unit-test-\d+$'));
      });

      test('should handle nested collection path', () async {
        final nestedRepo = await TestUtils.createUserRepository(
          path: 'organizations/org1/users',
        );

        expect(nestedRepo.path, equals('organizations/org1/users'));
        expect(nestedRepo.collectionId, equals('users'));
        expect(nestedRepo.collectionParentPath, equals('organizations/org1'));
      });
    });

    group('Auto ID Generation', () {
      test('should generate unique IDs', () async {
        final ids = <String>{};

        for (var i = 0; i < 10; i++) {
          final user = User(
            id: '',
            name: 'User $i',
            email: 'user$i@example.com',
          );

          final identified = repository.autoIdentify(
            user,
            updateObjectWithId: (user, id) => user.copyWith(id: id),
          );
          expect(identified.id.length, equals(20));
          expect(ids.add(identified.id), isTrue); // Should be unique
        }
      });

      test('should update object with ID when provided', () async {
        const user = User(id: '', name: 'Test User', email: 'test@example.com');

        final identified = repository.autoIdentify(
          user,
          updateObjectWithId: (user, id) => user.copyWith(id: id),
        );

        expect(identified.object.id, equals(identified.id));
        expect(identified.object.id, isNotEmpty);
      });
    });

    group('Data Conversion', () {
      test('should convert JSON to Document and back', () async {
        final originalJson = {
          'name': 'Test User',
          'email': 'test@example.com',
          'age': 25,
          'active': true,
          'tags': ['developer', 'tester'],
          'metadata': {'department': 'Engineering', 'level': 'Senior'},
          'joinDate': DateTime(2024).toIso8601String(),
        };

        final document = RepositoryFirestoreRestApi.fromJson(
          json: originalJson,
          id: 'test-id',
        );

        expect(document.name, equals('test-id'));
        expect(document.fields, isNotNull);

        final convertedJson = RepositoryFirestoreRestApi.toJson(document);

        expect(convertedJson['name'], equals('Test User'));
        expect(convertedJson['email'], equals('test@example.com'));
        expect(convertedJson['age'], equals(25));
        expect(convertedJson['active'], equals(true));
        expect(convertedJson['tags'], equals(['developer', 'tester']));
        final metadata = convertedJson['metadata'] as Map<String, dynamic>;
        expect(metadata['department'], equals('Engineering'));
        expect(metadata['level'], equals('Senior'));
      });

      test('should handle null values in conversion', () async {
        final jsonWithNulls = {
          'name': 'Test User',
          'age': null,
          'metadata': null,
        };

        final document = RepositoryFirestoreRestApi.fromJson(
          json: jsonWithNulls,
          id: 'test-id',
        );

        final convertedJson = RepositoryFirestoreRestApi.toJson(document);

        expect(convertedJson['name'], equals('Test User'));
        expect(convertedJson['age'], isNull);
        expect(convertedJson['metadata'], isNull);
      });

      test('should handle empty arrays and maps', () async {
        final jsonWithEmpty = {
          'name': 'Test User',
          'tags': <String>[],
          'metadata': <String, dynamic>{},
        };

        final document = RepositoryFirestoreRestApi.fromJson(
          json: jsonWithEmpty,
          id: 'test-id',
        );

        final convertedJson = RepositoryFirestoreRestApi.toJson(document);

        expect(convertedJson['name'], equals('Test User'));
        expect(convertedJson['tags'], equals([]));
        expect(convertedJson['metadata'], equals({}));
      });
    });
  });
}

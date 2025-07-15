import 'package:kiss_repository/kiss_repository.dart';
import 'package:test/test.dart';

import '../test_utils.dart';

void main() {
  group('RepositoryFirestoreJsonRestApi Integration Tests', () {
    late Repository<Map<String, dynamic>> repository;

    setUpAll(() async {
      // Wait for emulator to be ready
      if (!await TestUtils.isEmulatorRunning()) {
        fail(
          'Firebase emulator is not running. Please start it with: firebase emulators:start',
        );
      }
    });

    setUp(() async {
      // Use unique collection name for each test run
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final uniqueCollectionName = 'json-test-$timestamp';
      repository = await TestUtils.createJsonRepository(
        path: uniqueCollectionName,
      );
    });

    group('JSON Document Operations', () {
      test('should add and retrieve JSON document', () async {
        final userData = {
          'id': 'user-1',
          'name': 'John Doe',
          'email': 'john@example.com',
          'age': 30,
          'active': true,
          'roles': ['user', 'admin'],
          'metadata': {
            'lastLogin': DateTime(2024).toIso8601String(),
            'preferences': {'theme': 'dark', 'notifications': true},
          },
        };

        // Add document
        final addedDoc = await repository.add(
          IdentifiedObject('user-1', userData),
        );

        expect(addedDoc['name'], equals('John Doe'));
        expect(addedDoc['email'], equals('john@example.com'));
        expect(addedDoc['age'], equals(30));
        expect(addedDoc['active'], equals(true));
        expect(addedDoc['roles'], equals(['user', 'admin']));

        // Retrieve document
        final retrievedDoc = await repository.get('user-1');
        expect(retrievedDoc['name'], equals('John Doe'));
        expect(retrievedDoc['email'], equals('john@example.com'));
        final metadata = retrievedDoc['metadata'] as Map<String, dynamic>;
        final preferences = metadata['preferences'] as Map<String, dynamic>;
        expect(
          preferences['theme'],
          equals('dark'),
        );
      });

      test('should handle complex nested data structures', () async {
        final complexData = {
          'id': 'complex-1',
          'stringField': 'test string',
          'numberField': 42,
          'doubleField': 3.14,
          'boolField': true,
          'nullField': null,
          'arrayField': [
            'string item',
            123,
            true,
            {'nested': 'object'},
            'nested_array_as_string',
          ],
          'objectField': {
            'level1': {
              'level2': {'level3': 'deep value'},
            },
          },
          'dateField': DateTime(2024, 1, 15, 10, 30).toIso8601String(),
        };

        await repository.add(IdentifiedObject('complex-1', complexData));
        final retrievedDoc = await repository.get('complex-1');

        expect(retrievedDoc['stringField'], equals('test string'));
        expect(retrievedDoc['numberField'], equals(42));
        expect(retrievedDoc['doubleField'], equals(3.14));
        expect(retrievedDoc['boolField'], equals(true));
        expect(retrievedDoc['nullField'], isNull);
        final arrayField = retrievedDoc['arrayField'] as List<dynamic>;
        expect(arrayField[0], equals('string item'));
        final nestedObj = arrayField[3] as Map<String, dynamic>;
        expect(nestedObj['nested'], equals('object'));
        expect(arrayField[4], equals('nested_array_as_string'));
        final objectField = retrievedDoc['objectField'] as Map<String, dynamic>;
        final level1 = objectField['level1'] as Map<String, dynamic>;
        final level2 = level1['level2'] as Map<String, dynamic>;
        expect(
          level2['level3'],
          equals('deep value'),
        );
      });

      test('should update JSON document', () async {
        final originalData = {
          'name': 'Original Name',
          'version': 1,
          'settings': {'enabled': false, 'count': 10},
        };

        await repository.add(IdentifiedObject('update-test', originalData));

        final updatedDoc = await repository.update('update-test', (doc) {
          return {
            ...doc,
            'name': 'Updated Name',
            'version': 2,
            'settings': {
              ...doc['settings'] as Map<String, dynamic>,
              'enabled': true,
              'count': 15,
            },
          };
        });

        expect(updatedDoc['name'], equals('Updated Name'));
        expect(updatedDoc['version'], equals(2));
        final settings = updatedDoc['settings'] as Map<String, dynamic>;
        expect(settings['enabled'], equals(true));
        expect(settings['count'], equals(15));
      });

      test('should auto-generate IDs for JSON documents', () async {
        final data = {
          'type': 'auto-generated',
          'timestamp': DateTime.now().toIso8601String(),
        };

        final addedDoc = await repository.addAutoIdentified(
          data,
          updateObjectWithId: (doc, id) => {...doc, 'id': id},
        );

        expect(addedDoc['type'], equals('auto-generated'));

        // Verify the document was actually saved with auto-generated ID
        final autoId = addedDoc['id'] as String;

        //fetch the document
        final fetchedDoc = await repository.get(autoId);
        expect(fetchedDoc['type'], equals('auto-generated'));
      });

      test('should query multiple JSON documents', () async {
        // Add multiple documents
        final documents = [
          {'id': 'doc1', 'category': 'A', 'value': 100},
          {'id': 'doc2', 'category': 'B', 'value': 200},
          {'id': 'doc3', 'category': 'A', 'value': 300},
        ];

        for (var i = 0; i < documents.length; i++) {
          await repository.add(IdentifiedObject('doc${i + 1}', documents[i]));
        }

        final allDocs = await repository.query();
        expect(allDocs.length, equals(3));

        final categoryADocs =
            allDocs.where((doc) => doc['category'] == 'A').toList();
        expect(categoryADocs.length, equals(2));
      });

      test('should delete JSON document', () async {
        final data = {'name': 'To Delete', 'type': 'temporary'};

        await repository.add(IdentifiedObject('delete-me', data));

        // Verify it exists
        final doc = await repository.get('delete-me');
        expect(doc['name'], equals('To Delete'));

        // Delete it
        await repository.delete('delete-me');

        // Verify it's gone
        expect(
          () => repository.get('delete-me'),
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

    group('Edge Cases', () {
      test('should handle empty objects and arrays', () async {
        final emptyData = {
          'emptyObject': <String, dynamic>{},
          'emptyArray': <dynamic>[],
          'emptyString': '',
        };

        await repository.add(IdentifiedObject('empty-test', emptyData));
        final retrievedDoc = await repository.get('empty-test');

        expect(retrievedDoc['emptyObject'], equals({}));
        expect(retrievedDoc['emptyArray'], equals([]));
        expect(retrievedDoc['emptyString'], equals(''));
      });

      test('should handle special characters and unicode', () async {
        final specialData = {
          'specialChars': '!@#\$%^&*()_+-=[]{}|;:\'",.<>?/~`',
          'unicode': '🚀 Hello 世界 🌟',
          'newlines': 'line1\nline2\r\nline3',
          'tabs': 'col1\tcol2\tcol3',
        };

        await repository.add(IdentifiedObject('special-test', specialData));
        final retrievedDoc = await repository.get('special-test');

        expect(
          retrievedDoc['specialChars'],
          equals('!@#\$%^&*()_+-=[]{}|;:\'",.<>?/~`'),
        );
        expect(retrievedDoc['unicode'], equals('🚀 Hello 世界 🌟'));
        expect(retrievedDoc['newlines'], equals('line1\nline2\r\nline3'));
        expect(retrievedDoc['tabs'], equals('col1\tcol2\tcol3'));
      });

      test('should handle large data structures', () async {
        // Create a reasonably large document to test serialization limits
        final largeArray = List.generate(1000, (i) => 'item_$i');
        final largeObject = Map.fromIterables(
          List.generate(100, (i) => 'key_$i'),
          List.generate(100, (i) => 'value_$i'),
        );

        final largeData = {
          'largeArray': largeArray,
          'largeObject': largeObject,
          'description': 'This is a test of large data structures',
        };

        await repository.add(IdentifiedObject('large-test', largeData));
        final retrievedDoc = await repository.get('large-test');

        final retrievedArray = retrievedDoc['largeArray'] as List<dynamic>;
        expect(retrievedArray.length, equals(1000));
        expect(retrievedArray[0], equals('item_0'));
        expect(retrievedArray[999], equals('item_999'));
        final retrievedObject = retrievedDoc['largeObject'] as Map<String, dynamic>;
        expect(retrievedObject['key_0'], equals('value_0'));
        expect(retrievedObject['key_99'], equals('value_99'));
      });
    });

    group('Error Handling', () {
      test('should handle concurrent modifications gracefully', () async {
        final data = {'counter': 0};

        await repository.add(IdentifiedObject('concurrent-test', data));

        // Simulate concurrent updates
        final futures = List.generate(5, (i) async {
          try {
            return repository.update('concurrent-test', (doc) {
              final currentCount = doc['counter'] as int;
              return {...doc, 'counter': currentCount + 1};
            });
          } on Exception {
            // Some updates may fail due to concurrent modifications
            return null;
          }
        });

        final results = await Future.wait(futures);

        // Some updates should succeed
        final successfulUpdates = results.where((r) => r != null).length;
        expect(successfulUpdates, greaterThan(0));

        // Final counter should be at least 1
        final finalDoc = await repository.get('concurrent-test');
        expect(finalDoc['counter'], greaterThan(0));
      });

      test('should maintain data integrity during errors', () async {
        final validData = {'name': 'Valid', 'status': 'active'};

        await repository.add(IdentifiedObject('integrity-test', validData));

        // Attempt an operation that might fail
        try {
          await repository.update('non-existent', (doc) => doc);
        } on Exception {
          // Expected to fail
        }

        // Original data should remain intact
        final doc = await repository.get('integrity-test');
        expect(doc['name'], equals('Valid'));
        expect(doc['status'], equals('active'));
      });
    });
  });
}

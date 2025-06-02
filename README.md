# KISS Firebase Repository REST

A lightweight, type-safe Firestore implementation of the KISS Repository pattern for Dart using the Google Cloud Firestore REST API.

## Features

- 🎯 **Type-safe**: Generic repository with compile-time type safety
- 🔥 **Firebase REST API**: Uses official Google Cloud Firestore REST API
- 📦 **Lightweight**: Minimal dependencies, focused on core functionality
- 🧪 **Testable**: Comprehensive test suite with Firebase emulator support
- 🔄 **CRUD Operations**: Full Create, Read, Update, Delete support
- 🔍 **Query Support**: Built-in querying capabilities
- 🆔 **Auto ID Generation**: Automatic document ID generation
- 📄 **JSON Support**: Built-in JSON document repository

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  kiss_firebase_repository_rest: ^0.0.2
```

## Quick Start

```dart
import 'package:kiss_firebase_repository_rest/kiss_firebase_repository_rest.dart';

// Create a Google client with service account credentials
final client = GoogleClient(serviceAccountJson: serviceAccountJson);
final httpClient = await client.getClient();
final firestore = FirestoreApi(httpClient);

// Create a repository for your model
final repository = RepositoryFirestoreRestApi<User>(
  projectId: 'your-project-id',
  database: null, // Uses default database
  firestore: firestore,
  toFirestore: (user, id) => Document(/* conversion logic */),
  fromFirestore: (document) => User(/* conversion logic */),
  path: 'users',
  queryBuilder: YourQueryBuilder(),
);

// Use the repository
final user = User(name: 'John', email: 'john@example.com');
final addedUser = await repository.addAutoIdentified(user);
final retrievedUser = await repository.get(addedUser.id);
```

## Testing

This package includes a comprehensive test suite that uses Firebase emulators for safe, isolated testing.

### Prerequisites

1. **Install Firebase CLI** (version 8.14 or higher):
   ```bash
   npm install -g firebase-tools
   ```

2. **Verify installation**:
   ```bash
   firebase --version
   ```

### Quick Test Setup

Before running tests, verify your environment is ready:

```bash
# Check if everything is properly set up
./scripts/check_test_setup.sh

# If everything looks good, start testing
./scripts/test_with_emulator.sh
```

### Setting Up Firebase Emulator

1. **Initialize Firebase emulators** in your project:
   ```bash
   firebase init emulators
   ```
   Select Firestore when prompted.

2. **Start the emulator**:
   ```bash
   firebase emulators:start
   ```

3. The emulator will be available at:
   - Firestore: `http://127.0.0.1:8080`
   - Emulator UI: `http://127.0.0.1:4000`

### Running Tests

Once the emulator is running, you can run the tests:

```bash
# Run all tests
dart test

# Run only unit tests
dart test test/unit/

# Run only integration tests
dart test test/integration/

# Run with expanded output showing each test
dart test --reporter=expanded
```

### Test Structure

```
test/
├── unit/                           # Unit tests
│   └── repository_firestore_rest_api_test.dart
├── integration/                    # Integration tests
│   └── json_repository_test.dart
├── test_models.dart               # Test data models
├── test_utils.dart                # Test utilities
└── emulator_test_runner.dart      # Automated test runner
```

### Test Utilities

The test suite includes helper utilities:

```dart
import 'package:test/test.dart';
import 'test_utils.dart';

void main() {
  group('My Tests', () {
    setUpAll(() async {
      // Verify emulator is running
      if (!await TestUtils.isEmulatorRunning()) {
        fail('Firebase emulator is not running');
      }
    });

    setUp(() async {
      // Clear test data before each test
      await TestUtils.clearEmulatorData();
    });

    test('should work with emulator', () async {
      final repository = await TestUtils.createUserRepository();
      // Your test code here
    });
  });
}
```

### Automated Test Runner

Use the built-in test runner for automatic emulator management:

```dart
// Run this to check your test environment
dart run test/emulator_test_runner.dart
```

### Test Features

- ✅ **Emulator Integration**: Tests run against Firebase emulator
- ✅ **Data Isolation**: Each test gets a clean database state  
- ✅ **CRUD Testing**: Comprehensive Create, Read, Update, Delete tests
- ✅ **Error Handling**: Tests for various error conditions
- ✅ **Type Safety**: Tests with strongly-typed models
- ✅ **JSON Support**: Tests for JSON document operations
- ✅ **Edge Cases**: Tests for special characters, large data, etc.
- ✅ **Concurrent Operations**: Tests for concurrent modifications

### Testing Best Practices

1. **Always use emulators** for testing - never test against production
2. **Clear data between tests** using `TestUtils.clearEmulatorData()`
3. **Check emulator status** before running tests
4. **Use descriptive test names** that explain what's being tested
5. **Test both happy path and error conditions**

### Troubleshooting Tests

**Emulator not starting:**
```bash
# Check if ports are in use
lsof -i :8080
lsof -i :4000

# Kill processes using the ports
kill -9 <PID>

# Restart emulator
firebase emulators:start
```

**Tests failing with connection errors:**
```dart
// Verify emulator connectivity
if (!await TestUtils.isEmulatorRunning()) {
  print('Emulator is not running!');
}

// Check firestore configuration
final firestore = await TestUtils.createEmulatorFirestoreApi();
```

**Invalid reporter option errors:**
```bash
# Use valid reporter options
dart test --reporter=expanded  # Detailed output
dart test --reporter=compact   # Default, concise output
dart test --reporter=github    # For CI/CD environments
```

**Permission errors:**
- Ensure your service account has proper permissions
- For emulator testing, mock credentials are used automatically

**Port conflicts:**
```bash
# Check what's using the ports
lsof -i :8080
lsof -i :4000

# Kill processes if needed
kill -9 <PID>
```

## Usage Examples

### Basic User Repository

```dart
class User {
  final String id;
  final String name;
  final String email;
  final int? age;

  User({required this.id, required this.name, required this.email, this.age});
}

// Convert User to Firestore Document
Document userToFirestore(User user, String? id) {
  return RepositoryFirestoreRestApi.fromJson(
    json: {
      'name': user.name,
      'email': user.email,
      if (user.age != null) 'age': user.age,
    },
    id: id,
  );
}

// Convert Firestore Document to User
User userFromFirestore(Document document) {
  final json = RepositoryFirestoreRestApi.toJson(document);
  return User(
    id: document.name?.split('/').last ?? '',
    name: json['name'] as String,
    email: json['email'] as String,
    age: json['age'] as int?,
  );
}

// Create repository
final userRepository = RepositoryFirestoreRestApi<User>(
  projectId: 'my-project',
  firestore: firestore,
  toFirestore: userToFirestore,
  fromFirestore: userFromFirestore,
  path: 'users',
  queryBuilder: CollectionQueryBuilder(collectionId: 'users'),
);
```

### JSON Repository (Schemaless)

```dart
final jsonRepository = RepositoryFirestoreJsonRestApi(
  projectId: 'my-project',
  firestore: firestore,
  path: 'documents',
);

// Add any JSON data
await jsonRepository.add(IdentifiedObject('doc1', {
  'title': 'My Document',
  'content': 'Some content',
  'tags': ['important', 'draft'],
  'metadata': {
    'author': 'John Doe',
    'created': DateTime.now().toIso8601String(),
  }
}));
```

### Advanced Querying

```dart
// Custom query builder (implement your own logic)
class CustomQueryBuilder implements QueryBuilder<RunQueryRequest> {
  @override
  RunQueryRequest build(Query query) {
    // Implement custom query logic based on your needs
    return RunQueryRequest(
      structuredQuery: StructuredQuery(
        from: [CollectionSelector(collectionId: 'users')],
        // Add filters, ordering, limits, etc.
      ),
    );
  }
}
```

## API Reference

### RepositoryFirestoreRestApi<T>

Main repository class for typed operations.

**Constructor Parameters:**
- `projectId`: Firebase project ID
- `database`: Database name (optional, defaults to "(default)")
- `firestore`: FirestoreApi instance
- `toFirestore`: Function to convert your model to Firestore Document
- `fromFirestore`: Function to convert Firestore Document to your model
- `path`: Collection path (e.g., 'users' or 'organizations/org1/users')
- `queryBuilder`: Query builder for search operations
- `createId`: Custom ID generator (optional)

**Methods:**
- `get(String id)`: Retrieve document by ID
- `add(IdentifiedObject<T> item)`: Add document with specific ID
- `addAutoIdentified(T item)`: Add document with auto-generated ID
- `update(String id, T Function(T) updater)`: Update existing document
- `delete(String id)`: Delete document
- `query({Query query})`: Query multiple documents

### RepositoryFirestoreJsonRestApi

Specialized repository for JSON documents (schemaless).

**Constructor Parameters:**
- `projectId`: Firebase project ID
- `firestore`: FirestoreApi instance  
- `path`: Collection path
- `database`: Database name (optional)
- `queryBuilder`: Query builder (optional)

## Error Handling

The package throws `RepositoryException` for various error conditions:

```dart
try {
  final user = await repository.get('non-existent-id');
} on RepositoryException catch (e) {
  switch (e.code) {
    case RepositoryErrorCode.notFound:
      print('User not found');
      break;
    case RepositoryErrorCode.alreadyExists:
      print('User already exists');
      break;
    default:
      print('Other error: ${e.message}');
  }
}
```

## Performance Considerations

- Use batch operations when possible (planned for future releases)
- Implement proper indexing in Firestore for query performance
- Consider pagination for large result sets
- Use subcollections for hierarchical data organization

## Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Write tests for your changes
4. Ensure all tests pass (`dart test`)
5. Commit your changes (`git commit -m 'Add amazing feature'`)
6. Push to the branch (`git push origin feature/amazing-feature`)
7. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

# Testing Guide

This document provides a comprehensive guide to testing the KISS Firebase Repository REST package using Firebase emulators.

## 🚀 Quick Start

1. **Check your setup**:
   ```bash
   ./scripts/check_test_setup.sh
   ```

2. **Run all tests**:
   ```bash
   ./scripts/test_with_emulator.sh
   ```

That's it! The script will automatically start the Firebase emulator, run tests, and clean up.

## 📋 Prerequisites

### Required Software

- **Dart SDK**: 3.7.2 or higher
- **Node.js**: 18.x or higher  
- **Firebase CLI**: 8.14 or higher

### Installation

```bash
# Install Firebase CLI
npm install -g firebase-tools

# Verify installation
firebase --version
dart --version
```

## 🧪 Test Structure

```
test/
├── unit/                           # Unit tests for core functionality
│   └── repository_firestore_rest_api_test.dart
├── integration/                    # Integration tests with emulator
│   └── json_repository_test.dart
├── test_models.dart               # Shared test models
├── test_utils.dart                # Test utilities and helpers
├── emulator_test_runner.dart      # Automated test runner
└── kiss_firebase_repository_rest_test.dart  # Main integration tests
```

## 🔧 Testing Commands

### Basic Commands

```bash
# Check environment setup
./scripts/check_test_setup.sh

# Run all tests
./scripts/test_with_emulator.sh

# Run specific test types
./scripts/test_with_emulator.sh unit
./scripts/test_with_emulator.sh integration

# Run with coverage
./scripts/test_with_emulator.sh coverage

# Watch mode (reruns on changes)
./scripts/test_with_emulator.sh watch
```

### Manual Commands

```bash
# Start emulator manually
firebase emulators:start

# Run tests with different reporters
dart test --reporter=expanded
dart test --reporter=compact
dart test --reporter=github
```

## 🎯 What's Tested

### Core Repository Operations
- ✅ **CRUD Operations**: Create, Read, Update, Delete
- ✅ **Auto ID Generation**: Unique document ID creation
- ✅ **Error Handling**: Not found, already exists, validation errors
- ✅ **Type Safety**: Strongly-typed model conversions
- ✅ **Path Handling**: Simple and nested collection paths

### JSON Repository Operations  
- ✅ **Schema-less Documents**: Any JSON structure
- ✅ **Complex Data Types**: Nested objects, arrays, primitives
- ✅ **Data Conversion**: JSON ↔ Firestore Document conversion
- ✅ **Edge Cases**: Empty values, special characters, Unicode

### Advanced Scenarios
- ✅ **Concurrent Operations**: Multiple simultaneous operations
- ✅ **Batch Processing**: Multiple document operations
- ✅ **Performance Testing**: Response times and efficiency
- ✅ **Data Integrity**: Consistency during errors

## 🔥 Firebase Emulator Setup

### Automatic Setup (Recommended)

The test scripts automatically manage the emulator, but you can also set it up manually:

```bash
# Initialize emulators (one-time setup)
firebase init emulators

# Start emulator
firebase emulators:start
```

### Configuration

The `firebase.json` file configures the emulator:

```json
{
  "emulators": {
    "firestore": {
      "host": "127.0.0.1",
      "port": 8080
    },
    "ui": {
      "enabled": true,
      "host": "127.0.0.1", 
      "port": 4000
    }
  }
}
```

### Emulator URLs

- **Firestore API**: `http://127.0.0.1:8080`
- **Emulator UI**: `http://127.0.0.1:4000`

## 🧰 Test Utilities

### TestUtils Class

The `TestUtils` class provides helpful methods for testing:

```dart
// Check if emulator is running
await TestUtils.isEmulatorRunning()

// Clear all test data
await TestUtils.clearEmulatorData()

// Create test repositories
final userRepo = await TestUtils.createUserRepository()
final jsonRepo = await TestUtils.createJsonRepository()

// Generate sample test data
final users = TestUtils.createSampleUsers()
```

### Test Models

The `User` model demonstrates best practices:

```dart
class User {
  const User({
    required this.id,
    required this.name, 
    required this.email,
    this.age,
    this.createdAt,
  });
  
  // JSON serialization
  factory User.fromJson(Map<String, dynamic> json) => ...
  Map<String, dynamic> toJson() => ...
  
  // Utility methods
  User copyWith({...}) => ...
  @override bool operator ==(Object other) => ...
}
```

## 📊 Coverage Reports

Generate coverage reports:

```bash
# Run tests with coverage
./scripts/test_with_emulator.sh coverage

# View coverage report
open coverage/lcov.info
```

## 🚨 Troubleshooting

### Common Issues

**Emulator not starting:**
```bash
# Check ports
lsof -i :8080 :4000

# Kill conflicting processes
kill -9 <PID>
```

**Test dependencies issues:**
```bash
# Clean and reinstall
dart clean
dart pub get
```

**Reporter option errors:**
```bash
# Use valid options
dart test --reporter=expanded  # ✅
dart test --reporter=verbose   # ❌ Invalid
```

### Environment Check

Run the environment checker to diagnose issues:

```bash
./scripts/check_test_setup.sh
```

This will check:
- ✅ Required software versions
- ✅ Project configuration files
- ✅ Network port availability  
- ✅ Dependency resolution

## 🏗️ CI/CD Integration

### GitHub Actions

The package includes a GitHub Actions workflow (`.github/workflows/test.yml`) that:

1. Sets up Node.js and Dart
2. Installs Firebase CLI
3. Starts the emulator
4. Runs tests with coverage
5. Uploads coverage reports

### Local CI Testing

Test the CI setup locally:

```bash
# Simulate CI environment
NODE_ENV=ci ./scripts/test_with_emulator.sh
```

## 🔄 Development Workflow

### Adding New Tests

1. **Create test file** in appropriate directory:
   ```bash
   touch test/unit/my_new_test.dart
   ```

2. **Use test utilities**:
   ```dart
   import '../test_utils.dart';
   import '../test_models.dart';
   
   void main() {
     group('My New Tests', () {
       setUp(() async {
         await TestUtils.clearEmulatorData();
       });
       
       test('should do something', () async {
         final repo = await TestUtils.createUserRepository();
         // Test implementation
       });
     });
   }
   ```

3. **Run your tests**:
   ```bash
   dart test test/unit/my_new_test.dart --reporter=expanded
   ```

### Testing Best Practices

1. **Always clear data** between tests:
   ```dart
   setUp(() async {
     await TestUtils.clearEmulatorData();
   });
   ```

2. **Use descriptive test names**:
   ```dart
   test('should throw RepositoryException when user not found', () async {
     // Test implementation
   });
   ```

3. **Test both success and error cases**:
   ```dart
   group('User Creation', () {
     test('should create user successfully', () async { ... });
     test('should fail when user already exists', () async { ... });
   });
   ```

4. **Use type-safe assertions**:
   ```dart
   expect(
     () => repository.get('non-existent'),
     throwsA(isA<RepositoryException>()
         .having((e) => e.code, 'code', RepositoryErrorCode.notFound)),
   );
   ```

## 📚 Additional Resources

- [Firebase Emulator Suite Documentation](https://firebase.google.com/docs/emulator-suite)
- [Dart Testing Documentation](https://dart.dev/guides/testing)
- [Package Test Documentation](https://pub.dev/packages/test)

## 🤝 Contributing

When contributing tests:

1. Run the full test suite: `./scripts/test_with_emulator.sh`
2. Check coverage: `./scripts/test_with_emulator.sh coverage`
3. Verify CI compatibility: Test with GitHub Actions workflow
4. Update documentation as needed

For questions or issues, please check the main README or open an issue. 

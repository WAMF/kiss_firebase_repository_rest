import 'dart:io';
import 'package:test/test.dart';
import 'test_utils.dart';

/// Test runner that manages Firebase emulator lifecycle
class EmulatorTestRunner {
  static Process? _emulatorProcess;
  static bool _isEmulatorStarted = false;

  /// Starts the Firebase emulator if not already running
  static Future<void> startEmulator() async {
    if (_isEmulatorStarted || await TestUtils.isEmulatorRunning()) {
      print('📡 Firebase emulator is already running');
      return;
    }

    print('🚀 Starting Firebase emulator...');

    try {
      // Start the emulator in the background
      _emulatorProcess = await Process.start('firebase', [
        'emulators:start',
        '--only',
        'firestore',
      ], mode: ProcessStartMode.detached);

      // Wait for emulator to be ready
      await TestUtils.waitForEmulator();
      _isEmulatorStarted = true;

      print('✅ Firebase emulator started successfully');
      print('🌐 Emulator UI available at: http://127.0.0.1:4000');
      print('🔥 Firestore emulator available at: http://127.0.0.1:8080');
    } on ProcessException catch (e) {
      print('❌ Failed to start Firebase emulator: $e');
      print('💡 Make sure Firebase CLI is installed and configured');
      print('💡 Run: npm install -g firebase-tools');
      rethrow;
    }
  }

  /// Stops the Firebase emulator
  static Future<void> stopEmulator() async {
    if (_emulatorProcess != null) {
      print('🛑 Stopping Firebase emulator...');
      _emulatorProcess!.kill();
      _emulatorProcess = null;
      _isEmulatorStarted = false;
      print('✅ Firebase emulator stopped');
    }
  }

  /// Runs tests with automatic emulator management
  static Future<void> runTests(void Function() testFunction) async {
    try {
      await startEmulator();

      // Clear any existing data before running tests
      await TestUtils.clearEmulatorData();

      // Run the test function
      testFunction();
    } catch (e) {
      print('❌ Test execution failed: $e');
      rethrow;
    }
  }

  /// Cleans up resources and stops emulator
  static Future<void> cleanup() async {
    await stopEmulator();
  }
}

/// Main test runner entry point
void main() async {
  // Check if Firebase CLI is available
  try {
    final result = await Process.run('firebase', ['--version']);
    if (result.exitCode != 0) {
      throw Exception('Firebase CLI not found');
    }
    print('🔧 Firebase CLI version: ${result.stdout.toString().trim()}');
  } on ProcessException {
    print('❌ Firebase CLI is not installed or not in PATH');
    print('💡 Install with: npm install -g firebase-tools');
    exit(1);
  }

  // Check if firebase.json exists
  if (!File('firebase.json').existsSync()) {
    print('❌ firebase.json not found');
    print('💡 Run: firebase init emulators');
    exit(1);
  }

  setUpAll(() async {
    await EmulatorTestRunner.startEmulator();
  });

  tearDownAll(() async {
    await EmulatorTestRunner.cleanup();
  });

  group('All Firebase Repository Tests', () {
    test('Emulator connectivity test', () async {
      expect(await TestUtils.isEmulatorRunning(), isTrue);
      print('✅ Emulator connectivity verified');
    });

    group('Repository Tests', () {
      // Import and run individual test files
      test('Run repository unit tests', () async {
        // This would be replaced by importing actual test files
        // For now, we'll just verify the setup
        final repository = await TestUtils.createUserRepository();
        expect(repository.path, equals('users'));
        print('✅ Repository creation test passed');
      });

      test('Run JSON repository tests', () async {
        final jsonRepo = await TestUtils.createJsonRepository();
        expect(jsonRepo.path, equals('test-collection'));
        print('✅ JSON repository creation test passed');
      });
    });
  });
}

/// Helper class for development and debugging
class TestDevelopmentHelper {
  /// Prints useful information for developers
  static void printDevelopmentInfo() {
    print('');
    print('🧪 Firebase Emulator Test Suite');
    print('================================');
    print('');
    print('📋 Available test commands:');
    print('  dart test                    - Run all tests');
    print('  dart test test/unit/         - Run unit tests only');
    print('  dart test test/integration/  - Run integration tests only');
    print('');
    print('🔧 Firebase Emulator URLs:');
    print('  UI:        http://127.0.0.1:4000');
    print('  Firestore: http://127.0.0.1:8080');
    print('');
    print('💡 Tips:');
    print(
      '  - Keep the emulator running between test runs for faster execution',
    );
    print('  - Use the emulator UI to inspect test data');
    print('  - Clear emulator data with: TestUtils.clearEmulatorData()');
    print('');
  }

  /// Checks the current test environment
  static Future<void> checkEnvironment() async {
    print('🔍 Checking test environment...');

    // Check Firebase CLI
    try {
      final result = await Process.run('firebase', ['--version']);
      print('✅ Firebase CLI: ${result.stdout.toString().trim()}');
    } on ProcessException {
      print('❌ Firebase CLI: Not found');
    }

    // Check emulator status
    final isRunning = await TestUtils.isEmulatorRunning();
    print(
      '${isRunning ? "✅" : "❌"} Emulator: ${isRunning ? "Running" : "Stopped"}',
    );

    // Check configuration files
    final hasFirebaseJson = File('firebase.json').existsSync();
    print(
      '${hasFirebaseJson ? "✅" : "❌"} firebase.json: ${hasFirebaseJson ? "Found" : "Missing"}',
    );

    final hasPubspec = File('pubspec.yaml').existsSync();
    print(
      '${hasPubspec ? "✅" : "❌"} pubspec.yaml: ${hasPubspec ? "Found" : "Missing"}',
    );
  }
}

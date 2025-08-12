import 'package:kiss_repository_tests/kiss_repository_tests.dart';
import 'package:test/test.dart';

import 'emulator_test_runner.dart';
import 'repository_factories.dart';
import 'test_utils.dart';

void main() {
  setUpAll(() async {
    // Start emulator once for all tests
    await EmulatorTestRunner.startEmulator();

    // Clear database before starting tests
    print('🧹 Clearing database before test suite...');
    await TestUtils.clearEmulatorData();
    print('✅ Database cleared');
  });

  tearDownAll(() async {
    // Stop emulator after all tests
    await EmulatorTestRunner.ensureCleanup();
  });

  runRepositoryTests(
    implementationName: 'Firebase REST API',
    factoryProvider: ProductModelRepositoryFactory.new,
    cleanup: () {
      // Factory.cleanup() already clears the database, so no additional cleanup needed
    },
    config: const TestSuiteConfig.crudAndBatch(),
  );
}

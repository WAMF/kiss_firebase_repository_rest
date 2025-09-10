## 0.3.0

- Add multiple authentication methods to GoogleClient:
  - Application Default Credentials (ADC) support via `GoogleClient.defaultCredentials()`
  - OAuth2 user consent flow for CLI tools via `GoogleClient.userConsent()`
  - Unauthenticated mode for emulator support via `GoogleClient.unauthenticated()`
  - Custom OAuth2 scopes support for all authentication methods
- Improve documentation with authentication examples

## 0.2.2

- Update kiss_repository_tests dependency to v0.3.1
- Code formatting improvements

## 0.2.1

- Implement automatic Firebase emulator management for tests
- Fix all analyzer warnings and improve code quality
- Improve test infrastructure with repository factories
- Add comprehensive Firebase repository tests

## 0.2.0

- Remove the idField from the toJson, as the higher level interface should handle setting Ids

## 0.1.0

- Update to new interface
- Added tests with firebase emulators

## 0.0.2

- Add missing export

## 0.0.1

- Initial version.


# KISS Repository Firestore REST API

A lightweight, type-safe Firestore implementation of the KISS Repository pattern for Dart and Flutter applications.

## Overview

This package provides a Firestore implementation of the Repository pattern using Google's REST API. It allows you to interact with Firestore collections in a type-safe manner, with support for CRUD operations, querying, and document mapping.

*This is intended for server side use only*

## Features

- 🔄 Complete CRUD operations (Create, Read, Update, Delete)
- 🔍 Type-safe querying
- 🗃️ Collection and subcollection support
- 🔄 JSON serialization and deserialization
- 🆔 Custom ID generation
- ⚡ Efficient Firestore REST API integration

## Installation

Install the package using the Dart CLI:

```bash
dart pub add kiss_firebase_repository_rest
dart pub add googleapis
```

## Usage

### Quick Start Example

```dart
import 'package:googleapis/firestore/v1.dart';
import 'package:kiss_firebase_repository_rest/kiss_firebase_repository_rest.dart';
import 'package:google_auth_client/google_auth_client.dart'; // Assuming this is the package for GoogleClient

void main() async {
  const serviceAccountJson = '''
  {
    "type": "service_account",
    "project_id": "your-project-id",
    "private_key_id": "your-private-key-id",
  }
  ''';
  final firestore = FirestoreApi(
    await GoogleClient(serviceAccountJson: serviceAccountJson).getClient(),
  );
  final repository = RepositoryFirestoreJsonRestApi(
    projectId: 'your-project-id',
    firestore: firestore,
    path: 'your-collection-path',
  );

  final document = await repository.get('your-document-id');
  print(document);
}
```

## Type Conversion

The library provides utilities for converting between Dart types and Firestore types:

- Strings, booleans, integers, doubles
- DateTime (stored as ISO-8601 strings)
- Lists
- Maps (stored as nested documents)

## Error Handling

The repository throws `RepositoryException` with appropriate error codes:

- `RepositoryErrorCode.notFound` - When a document doesn't exist
- `RepositoryErrorCode.alreadyExists` - When trying to create a document with an existing ID

## Future Development

- Implement missing methods: `addAll`, `deleteAll`, `updateAll`
- Add support for streaming changes with `stream` and `streamQuery`
- Add patch updates for more efficient document updates

## License

MIT

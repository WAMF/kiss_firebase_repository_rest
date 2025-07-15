import 'dart:math';

import 'package:googleapis/firestore/v1.dart';
import 'package:kiss_repository/kiss_repository.dart';

/// A function that converts an item of type T to a Firestore Document.
typedef ToFirestore<T> = Document Function(T item, String? id);
/// A function that converts a Firestore Document to an item of type T.
typedef FromFirestore<T> = T Function(Document document);

/// A repository implementation that uses the Firestore REST API for data persistence.
class RepositoryFirestoreRestApi<T> extends Repository<T> {
  /// Creates a new RepositoryFirestoreRestApi instance.
  RepositoryFirestoreRestApi({
    required String projectId,
    required String? database,
    required FirestoreApi firestore,
    required ToFirestore<T> toFirestore,
    required FromFirestore<T> fromFirestore,
    required String path,
    required QueryBuilder<RunQueryRequest> queryBuilder,
    String Function()? createId,
  }) : _firestore = firestore,
       _database = database ?? 'projects/$projectId/databases/(default)',
       _path = path,
       _toFirestore = toFirestore,
       _fromFirestore = fromFirestore,
       _queryBuilder = queryBuilder,
       _createId = createId ?? defaultCreateId;
  final FirestoreApi _firestore;
  final String _database;
  final String _path;
  final ToFirestore<T> _toFirestore;
  final FromFirestore<T> _fromFirestore;
  final QueryBuilder<RunQueryRequest> _queryBuilder;
  final String Function() _createId;
  /// Returns the base path for documents in the Firestore database.
  String get documentsPath => '$_database/documents';

  /// Returns the collection ID from the path.
  String get collectionId => _path.split('/').last;

  /// Returns the parent path of the collection.
  String get collectionParentPath {
    final lastSlashIndex = _path.lastIndexOf('/');
    return lastSlashIndex == -1 ? '' : _path.substring(0, lastSlashIndex);
  }

  /// Generates a default random ID for new documents.
  static String defaultCreateId() {
    const chars =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    const length = 20;
    final random = Random.secure();
    return String.fromCharCodes(
      Iterable.generate(
        length,
        (_) => chars.codeUnitAt(random.nextInt(chars.length)),
      ),
    );
  }

  @override
  String? get path => _path;

  @override
  Future<T> get(String id) async {
    final parent =
        collectionParentPath.isEmpty
            ? documentsPath
            : '$documentsPath/$collectionParentPath';
    final documentPath = '$parent/$collectionId/$id';
    late Document document;
    try {
      document = await _firestore.projects.databases.documents.get(
        documentPath,
      );
      return _fromFirestore(document);
    } catch (e) {
      if (e is DetailedApiRequestError && e.status == 404) {
        throw RepositoryException(
          message: 'Item with id $id not found',
          code: RepositoryErrorCode.notFound,
        );
      }
      rethrow;
    }
  }

  @override
  Future<T> add(IdentifiedObject<T> item) async {
    try {
      final document = _toFirestore(item.object, item.id)
        ..name = null;
      final parent =
          collectionParentPath.isEmpty
              ? documentsPath
              : '$documentsPath/$collectionParentPath';
      final createdDocument = await _firestore.projects.databases.documents
          .createDocument(document, parent, collectionId, documentId: item.id);
      return _fromFirestore(createdDocument);
    } catch (e) {
      if (e is DetailedApiRequestError && e.status == 409) {
        throw RepositoryException.alreadyExists(item.id);
      }
      rethrow;
    }
  }

  @override
  IdentifiedObject<T> autoIdentify(
    T item, {
    T Function(T, String)? updateObjectWithId,
  }) {
    final id = _createId();
    final updatedItem = updateObjectWithId?.call(item, id) ?? item;
    return IdentifiedObject(id, updatedItem);
  }

  @override
  Future<T> addAutoIdentified(
    T item, {
    T Function(T, String)? updateObjectWithId,
  }) async {
    return add(autoIdentify(item, updateObjectWithId: updateObjectWithId));
  }

  @override
  Future<T> update(String id, T Function(T) updater) async {
    try {
      final existingItem = await get(id);
      final updatedItem = updater(existingItem);
      final document = _toFirestore(updatedItem, id);
      final parent =
          collectionParentPath.isEmpty
              ? documentsPath
              : '$documentsPath/$collectionParentPath';
      final documentPath = '$parent/$collectionId/$id';
      document.name = documentPath;

      //only update whats changed.......

      final updatedDocument = await _firestore.projects.databases.documents
          .patch(document, documentPath, currentDocument_exists: true);
      return _fromFirestore(updatedDocument);
    } catch (e) {
      if (e is DetailedApiRequestError) {
        if (e.status == 404) {
          throw RepositoryException(
            message: 'Item with id $id not found',
            code: RepositoryErrorCode.notFound,
          );
        }
      }
      rethrow;
    }
  }

  @override
  Future<void> delete(String id) async {
    final parent =
        collectionParentPath.isEmpty
            ? documentsPath
            : '$documentsPath/$collectionParentPath';
    final documentPath = '$parent/$collectionId/$id';
    await _firestore.projects.databases.documents.delete(documentPath);
  }

  @override
  Future<List<T>> query({Query query = const AllQuery()}) async {
    final request = _queryBuilder.build(query);
    final response = await _firestore.projects.databases.documents.runQuery(
      request,
      documentsPath,
    );
    return response
        .map((e) {
          final doc = e.document;
          if (doc != null) {
            return _fromFirestore(doc);
          }
          return null;
        })
        .whereType<T>()
        .toList();
  }

  /// Converts a JSON map to a Firestore Document.
  static Document fromJson({required Map<String, dynamic> json, String? id}) {
    return Document(
      name: id,
      fields: json.map((key, value) => MapEntry(key, toDocumentValue(value))),
    );
  }

  /// Converts a Firestore Document to a JSON map.
  static Map<String, dynamic> toJson(Document document) {
    final value = fromDocumentValue(
      Value(mapValue: MapValue(fields: document.fields)),
    );
    return value as Map<String, dynamic>;
  }

  /// Converts a JSON value to a Firestore Value.
  static Value toDocumentValue(dynamic jsonValue) {
    if (jsonValue == null) {
      return Value(nullValue: 'NULL_VALUE');
    }
    if (jsonValue is String) {
      return Value(stringValue: jsonValue);
    }
    if (jsonValue is bool) {
      return Value(booleanValue: jsonValue);
    }
    if (jsonValue is int) {
      return Value(integerValue: jsonValue.toString());
    }
    if (jsonValue is double) {
      return Value(doubleValue: jsonValue);
    }
    if (jsonValue is DateTime) {
      return Value(timestampValue: jsonValue.toIso8601String());
    }
    if (jsonValue is List) {
      return Value(
        arrayValue: ArrayValue(values: jsonValue.map(toDocumentValue).toList()),
      );
    }
    if (jsonValue is Map<String, dynamic>) {
      return Value(
        mapValue: MapValue(
          fields: jsonValue.map(
            (key, value) => MapEntry(key, toDocumentValue(value)),
          ),
        ),
      );
    }
    throw ArgumentError('Unsupported type: ${jsonValue.runtimeType}');
  }

  /// Converts a Firestore Value to a JSON value.
  static dynamic fromDocumentValue(Value value) {
    if (value.nullValue != null) {
      return null;
    }

    if (value.doubleValue != null) {
      return value.doubleValue!;
    }
    if (value.integerValue != null) {
      return int.parse(value.integerValue!);
    }
    if (value.stringValue != null) {
      return value.stringValue!;
    }
    if (value.booleanValue != null) {
      return value.booleanValue!;
    }
    if (value.timestampValue != null) {
      return DateTime.parse(value.timestampValue!);
    }
    if (value.arrayValue != null) {
      final values = value.arrayValue!.values;
      if (values != null && values.isNotEmpty) {
        return values.map(fromDocumentValue).toList();
      }
      return List<dynamic>.empty();
    }
    if (value.mapValue != null) {
      final map = <String, dynamic>{};
      final fields = value.mapValue!.fields;
      if (fields != null && fields.entries.isNotEmpty) {
        for (final entry in fields.entries) {
          map[entry.key] = fromDocumentValue(entry.value);
        }
      }
      return map;
    }
    return null;
  }

  @override
  Future<Iterable<T>> addAll(Iterable<IdentifiedObject<T>> items) async {
    return Future.wait(items.map(add));
  }

  @override
  Future<void> deleteAll(Iterable<String> ids) async {
    await Future.wait(ids.map(delete));
  }

  @override
  Stream<T> stream(String id) {
    // REST API does not support streaming, but we can return a stream of one item
    //warn about this
    print('Warning: Streaming is not supported for REST API');
    return Stream.fromFuture(get(id));
  }

  @override
  Stream<List<T>> streamQuery({Query query = const AllQuery()}) {
    // REST API does not support streaming queries
    print('Warning: Streaming queries are not supported for REST API');
    return Stream.fromFuture(this.query(query: query));
  }

  @override
  Future<Iterable<T>> updateAll(Iterable<IdentifiedObject<T>> items) async {
    return Future.wait(
      items.map((e) => update(e.id, (existingItem) => e.object)),
    );
  }

  @override
  void dispose() {
    // nothing to do
  }
}

/// A specialized repository implementation for JSON documents in Firestore.
class RepositoryFirestoreJsonRestApi
    extends RepositoryFirestoreRestApi<Map<String, dynamic>> {
  /// Creates a new RepositoryFirestoreJsonRestApi instance.
  RepositoryFirestoreJsonRestApi({
    required super.projectId,
    required super.firestore,
    required super.path,
    QueryBuilder<RunQueryRequest>? queryBuilder,
    super.database,
  }) : super(
         toFirestore:
             (map, id) =>
                 RepositoryFirestoreRestApi.fromJson(json: map, id: id),
         fromFirestore: RepositoryFirestoreRestApi.toJson,
         queryBuilder:
             queryBuilder ?? _CollectionQueryBuilder(collectionId: path),
       );
}

class _CollectionQueryBuilder implements QueryBuilder<RunQueryRequest> {
  _CollectionQueryBuilder({required String collectionId})
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

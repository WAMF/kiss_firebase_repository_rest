import 'package:googleapis/firestore/v1.dart';
import 'package:kiss_repository/kiss_repository.dart';
import 'dart:math';

typedef ToFirestore<T> = Document Function(T item, String? id);
typedef FromFirestore<T> = T Function(Document document);

class RepositoryFirestoreRestApi<T> extends Repository<T> {
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
  String get documentsPath => '$_database/documents';

  String get collectionId => _path.split('/').last;

  String get collectionParentPath {
    final lastSlashIndex = _path.lastIndexOf('/');
    return lastSlashIndex == -1 ? '' : _path.substring(0, lastSlashIndex);
  }

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
  Future<T> add(T item) async {
    final id = _createId();
    return addWithId(id, item);
  }

  @override
  Future<T> addWithId(String id, T item) async {
    try {
      final document = _toFirestore(item, id);
      document.name = null;
      final parent =
          collectionParentPath.isEmpty
              ? documentsPath
              : '$documentsPath/$collectionParentPath';
      final createdDocument = await _firestore.projects.databases.documents
          .createDocument(document, parent, collectionId, documentId: id);
      return _fromFirestore(createdDocument);
    } catch (e) {
      if (e is DetailedApiRequestError && e.status == 409) {
        throw RepositoryException.alreadyExists(id);
      }
      rethrow;
    }
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

  static Document fromJson({required Map<String, dynamic> json, String? id}) {
    return Document(
      name: id,
      fields: json.map((key, value) => MapEntry(key, toDocumentValue(value))),
    );
  }

  static Map<String, dynamic> toJson(Document document, {String? idField}) {
    final value = fromDocumentValue(
      Value(mapValue: MapValue(fields: document.fields)),
    );
    if (idField != null) {
      return {...value as Map<String, dynamic>, idField: document.name};
    }
    return value as Map<String, dynamic>;
  }

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
  Future<Iterable<T>> addAll(Object items) {
    // TODO: implement addAll
    throw UnimplementedError();
  }

  @override
  Future<void> deleteAll(Iterable<String> ids) {
    // TODO: implement deleteAll
    throw UnimplementedError();
  }

  @override
  Stream<T> stream(String id) {
    // TODO: implement stream
    throw UnimplementedError();
  }

  @override
  Stream<List<T>> streamQuery({Query query = const AllQuery()}) {
    // TODO: implement streamQuery
    throw UnimplementedError();
  }

  @override
  Future<Iterable<T>> updateAll(Iterable<IdentifedObject<T>> items) {
    // TODO: implement updateAll
    throw UnimplementedError();
  }
}

class RepositoryFirestoreJsonRestApi
    extends RepositoryFirestoreRestApi<Map<String, dynamic>> {
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

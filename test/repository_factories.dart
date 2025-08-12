import 'package:googleapis/firestore/v1.dart';
import 'package:kiss_firebase_repository_rest/kiss_firebase_repository_rest.dart';
import 'package:kiss_repository/kiss_repository.dart';
import 'package:kiss_repository_tests/kiss_repository_tests.dart';

import 'test_utils.dart';

/// Factory for creating ProductModel repositories for standardized testing
class ProductModelRepositoryFactory implements RepositoryFactory<ProductModel> {
  Repository<ProductModel>? _repository;

  @override
  Future<Repository<ProductModel>> createRepository() async {
    // Create unique collection name for test isolation
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uniqueCollectionName = 'standardized-product-test-$timestamp';
    
    _repository = await _createProductRepository(uniqueCollectionName);
    
    return _repository!;
  }

  @override
  Future<void> cleanup() async {
    // Clear test data between tests
    await TestUtils.clearEmulatorData();
  }

  @override
  void dispose() {
    _repository?.dispose();
    _repository = null;
  }

  /// Creates a ProductModel repository with proper conversions
  Future<Repository<ProductModel>> _createProductRepository(String path) async {
    final firestore = await TestUtils.createEmulatorFirestoreApi();
    
    return RepositoryFirestoreRestApi<ProductModel>(
      projectId: 'test-project',
      database: null,
      firestore: firestore,
      toFirestore: _productToFirestore,
      fromFirestore: _productFromFirestore,
      path: path,
      queryBuilder: _TestQueryBuilder(collectionId: path),
    );
  }

  /// Converts ProductModel to Firestore Document
  Document _productToFirestore(ProductModel product, String? id) {
    return RepositoryFirestoreRestApi.fromJson(
      json: {
        'name': product.name,
        'price': product.price,
        'description': product.description,
        'created': product.created.toIso8601String(),
      },
      id: id,
    );
  }

  /// Converts Firestore Document to ProductModel
  ProductModel _productFromFirestore(Document document) {
    final json = RepositoryFirestoreRestApi.toJson(document);
    final documentPath = document.name ?? '';
    final id = documentPath.split('/').last;
    
    return ProductModel(
      id: id,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      description: json['description'] as String,
      created: DateTime.parse(json['created'] as String),
    );
  }
}

/// Test query builder for ProductModel repository
class _TestQueryBuilder implements QueryBuilder<RunQueryRequest> {
  _TestQueryBuilder({required String collectionId})
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

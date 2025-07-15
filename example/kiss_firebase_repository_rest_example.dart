import 'package:googleapis/firestore/v1.dart';
import 'package:kiss_firebase_repository_rest/kiss_firebase_repository_rest.dart';

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

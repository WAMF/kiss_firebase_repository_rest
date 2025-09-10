import 'package:googleapis/firestore/v1.dart';
import 'package:kiss_firebase_repository_rest/kiss_firebase_repository_rest.dart';

void main() async {
  // Example 1: Using Service Account JSON (for server/backend applications)
  const serviceAccountJson = r'''
  {
    "type": "service_account",
    "project_id": "your-project-id",
    "private_key_id": "your-private-key-id",
    "private_key": "-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n",
    "client_email": "your-service-account@your-project-id.iam.gserviceaccount.com",
    "client_id": "your-client-id",
    "auth_uri": "https://accounts.google.com/o/oauth2/auth",
    "token_uri": "https://oauth2.googleapis.com/token"
  }
  ''';

  final googleClient = GoogleClient(
    serviceAccountJson: serviceAccountJson,
    scopes: [
      'https://www.googleapis.com/auth/datastore',
    ], // Optional, defaults to cloud-platform
  );

  // Example 2: Using Application Default Credentials (for Google Cloud environments)
  // final googleClient = GoogleClient.defaultCredentials(
  //   scopes: ['https://www.googleapis.com/auth/datastore'],
  // );

  // Example 3: Using Unauthenticated client (for emulators)
  // final googleClient = GoogleClient.unauthenticated();
  // final firestore = FirestoreApi(
  //   await googleClient.getClient(),
  //   rootUrl: 'http://localhost:8080/', // Emulator URL
  // );

  // Example 4: Using OAuth2 User Consent (for CLI tools)
  // final googleClient = GoogleClient.userConsent(
  //   clientId: 'your-client-id.apps.googleusercontent.com',
  //   clientSecret: 'your-client-secret',
  //   scopes: ['https://www.googleapis.com/auth/datastore'],
  // );

  final firestore = FirestoreApi(await googleClient.getClient());

  final repository = RepositoryFirestoreJsonRestApi(
    projectId: 'your-project-id',
    firestore: firestore,
    path: 'your-collection-path',
  );

  final document = await repository.get('your-document-id');
  print(document);
}

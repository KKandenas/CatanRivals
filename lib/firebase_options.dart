// Genererad manuellt (inte via `flutterfire configure`, som kräver en
// interaktiv webbläsarinloggning) från webb-appens Firebase-config i
// Firebase Console → Project settings → General → Your apps.
//
// Firebase-klientkonfiguration av den här typen (apiKey, projectId osv.)
// är avsedd att vara publik i klientkod – de skyddar inte i sig, det
// gör Realtime Database-reglerna. Se
// https://firebase.google.com/docs/projects/api-keys
//
// Projektet är webb-only just nu (Flutter Web för iPad Safari), så
// `currentPlatform` returnerar webb-konfigurationen oavsett plattform.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => web;

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDNBmBUXNc3HzCqlperFR1xQJC0Q66xEgE',
    authDomain: 'catan-rivals.firebaseapp.com',
    databaseURL: 'https://catan-rivals-default-rtdb.europe-west1.firebasedatabase.app',
    projectId: 'catan-rivals',
    storageBucket: 'catan-rivals.firebasestorage.app',
    messagingSenderId: '605431988607',
    appId: '1:605431988607:web:eb182d18268a5935d65a4a',
  );
}

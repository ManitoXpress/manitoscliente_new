import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Example:
/// ```dart
/// import 'firebase_options.dart';
/// // ...
/// await Firebase.initializeApp(
///   options: DefaultFirebaseOptions.currentPlatform,
/// );
/// ```
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
              'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
              'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDpVVMrsN7Uitt9MNTxdZdMgWSr2O36CnQ',
    appId: '1:933474056744:web:eca78d8837c445e6f8131d',
    messagingSenderId: '933474056744',
    projectId: 'manitoxpress-cf855',
    authDomain: 'manitoxpress-cf855.firebaseapp.com',
    databaseURL: 'https://manitoxpress-cf855-default-rtdb.firebaseio.com',
    storageBucket: 'manitoxpress-cf855.appspot.com',
    measurementId: 'G-V0M15KGXTR',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCSp5RbLBZKMLHT0RJH3Zk5JRXZ4LOrQYc',
    appId: '1:933474056744:android:b583a1e55ec53854f8131d',
    messagingSenderId: '933474056744',
    projectId: 'manitoxpress-cf855',
    databaseURL: 'https://manitoxpress-cf855-default-rtdb.firebaseio.com',
    storageBucket: 'manitoxpress-cf855.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCSp5RbLBZKMLHT0RJH3Zk5JRXZ4LOrQYc',
    appId: '1:933474056744:ios:a11f644ba60ff592f8131d',
    messagingSenderId: '933474056744',
    projectId: 'manitoxpress-cf855',
    databaseURL: 'https://manitoxpress-cf855-default-rtdb.firebaseio.com',
    storageBucket: 'manitoxpress-cf855.appspot.com',
    androidClientId: '933474056744-5m32u4i8ltf1r975qbghcfe7slh6fmop.apps.googleusercontent.com',
    iosClientId: '933474056744-5t2nnrvq4a45jtv2pv2fpbkt8ko9a02i.apps.googleusercontent.com',
    iosBundleId: 'com.example.manitoCliente',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCSp5RbLBZKMLHT0RJH3Zk5JRXZ4LOrQYc',
    appId: '1:933474056744:ios:bd98d572bd4a6005f8131d',
    messagingSenderId: '933474056744',
    projectId: 'manitoxpress-cf855',
    databaseURL: 'https://manitoxpress-cf855-default-rtdb.firebaseio.com',
    storageBucket: 'manitoxpress-cf855.appspot.com',
    androidClientId: '933474056744-5m32u4i8ltf1r975qbghcfe7slh6fmop.apps.googleusercontent.com',
    iosClientId: '933474056744-1n2pn1bfsubeiekccbc6und5b8nmcfnl.apps.googleusercontent.com',
    iosBundleId: 'com.example.manitoCliente.RunnerTests',
  );
}


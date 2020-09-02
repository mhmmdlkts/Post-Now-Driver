import 'package:firebase_database/firebase_database.dart';

import 'message.dart';

class JobChat {
  String key;
  List<Message> messages;

  JobChat.fromSnapshot(DataSnapshot snapshot) {
    key = snapshot.key;
    print(snapshot.value);
  }
}
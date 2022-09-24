import 'dart:io';

import 'package:mineral_ioc/ioc.dart';
import 'package:mineral_mongodb/src/connections/database_connection.dart';

class MongoDB {
  final String label = 'MongoDB';
  static String namespace = 'Mineral/Plugins/Mongodb';
  late final Directory root;
  late DatabaseConnection connection;

  Future<void> init () async {
    final environment = ioc.singleton(Service.environment);

    connection = DatabaseConnection(environment.get('MONGODB_URL'));

    await open();
  }

  void testing (String uri) {
    connection = DatabaseConnection(uri);
  }

  Future<void> open () async {
    await connection.open();
  }
}

import 'dart:io';

import 'package:mineral_ioc/ioc.dart';
import 'package:mineral_mongodb/mineral_mongodb.dart';
import 'package:mineral_mongodb/src/connections/database_connection.dart';
import 'package:mineral_mongodb/src/connections/local_connection.dart';

class MongoDB {
  final String label = 'MongoDB';
  static String namespace = 'Mineral/Plugins/Mongodb';
  late final Directory root;
  late DatabaseConnection connection;

  Future<void> init () async {
    final environment = ioc.singleton(Service.environment);

    local(Uri(
      host: environment.get('MONGODB_HOST') ?? '127.0.0.1',
      port: environment.get('MONGODB_PORT') != null
        ? int.parse(environment.get('MONGODB_PORT'))
        : 27017,
      scheme: 'mongodb',
      path: environment.get('MONGODB_DATABASE'),
    ));

    await open();

    print(environment.get('MONGODB_HOST'));
  }

  void local (Uri uri, { MongoDBAuth? auth }) {
    connection = LocalConnection(uri, null);
  }

  Future<void> open () async {
    await connection.open();
  }
}

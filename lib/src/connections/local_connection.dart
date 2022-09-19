import 'package:mineral_mongodb/src/connections/database_connection.dart';
import 'package:mongo_dart/mongo_dart.dart';

class LocalConnection extends DatabaseConnection {
  LocalConnection(super.uri, super.auth);

  @override
  Future<void> open () async {
    database = Db('$uri');
    await database.open(secure: false);
  }
}

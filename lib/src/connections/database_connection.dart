import 'package:mongo_dart/mongo_dart.dart';

class DatabaseConnection {
  final String _uri;
  late final Db database;

  DatabaseConnection(this._uri);

  String get uri => _uri;

  Future<void> open () async {
    database = await Db.create(_uri);
    await database.open(secure: false);
  }

  DbCollection collection (String name) {
    return database.collection(name);
  }
}

import 'package:mineral_mongodb/mineral_mongodb.dart';
import 'package:mongo_dart/mongo_dart.dart';

abstract class DatabaseConnection {
  final Uri _uri;
  final MongoDBAuth? _auth;
  late final Db database;

  DatabaseConnection(this._uri, this._auth);

  Uri get uri => _uri;
  MongoDBAuth? get auth => _auth;

  Future<void> open ();

  DbCollection collection (String name) {
    return database.collection(name);
  }
}

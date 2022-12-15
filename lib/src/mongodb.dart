import 'package:mineral_environment/environment.dart';
import 'package:mineral_mongodb/mineral_mongodb.dart';
import 'package:mineral_mongodb/src/connections/database_connection.dart';
import 'package:mineral_mongodb/src/contracts/mongodb_contract.dart';
import 'package:mineral_mongodb/src/entities/static_schema.dart';
import 'package:mineral_package/mineral_package.dart';

class MongoDB extends MineralPackage implements MongodbContract {
  @override
  String namespace = 'Mineral/Plugins/MongoDB';

  @override
  String label = 'MongoDB';

  @override
  String description =  'The mongoDB module was designed exclusively for the Mineral framework, it allows you to communicate with a MongoDB database.';

  late DatabaseConnection connection;

  final ModelFactory _models;

  @override
  ModelFactory get models => _models;

  MongoDB(this._models);

  @override
  Future<void> init () async {
    final environment = container.use<MineralEnvironment>();
    connection = DatabaseConnection(environment.getOrFail('MONGODB_URL', message: 'The mongodb url was not provided'));

    await open();
  }

  void testing (String uri) {
    connection = DatabaseConnection(uri);
  }

  Future<void> open () async {
    await connection.open();
  }

  @override
  StaticSchema<T> use<T extends Schema> () => StaticSchema<T>();

  /// Delete the database
  /// ```dart
  /// await Schema.drop();
  /// ```
  /// The action requires special permission to operate.
  Future<void> dropDatabase () async {
    await connection.database.drop();
  }
}

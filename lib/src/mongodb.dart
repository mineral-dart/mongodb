import 'package:mineral_environment/environment.dart';
import 'package:mineral_mongodb/src/connections/database_connection.dart';
import 'package:mineral_package/mineral_package.dart';

class MongoDB extends MineralPackage {
  @override
  String namespace = 'Mineral/Plugins/MongoDB';

  @override
  String label = 'MongoDB';

  @override
  String description =  'The mongoDB module was designed exclusively for the Mineral framework, it allows you to communicate with a MongoDB database.';

  late DatabaseConnection connection;

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
}

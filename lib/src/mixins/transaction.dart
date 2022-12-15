import 'package:mineral_ioc/ioc.dart';
import 'package:mineral_mongodb/src/contracts/mongodb_contract.dart';
import 'package:mineral_mongodb/src/mongodb.dart';

mixin Transaction {
  MongodbContract _getPlugin () {
    final dynamic pluginManager = ioc.services.entries.firstWhere((element) => element.key.toString() == 'PluginManagerCraft').value;
    return pluginManager.use<MongoDB>();
  }

  MongodbContract get schema => _getPlugin();
}
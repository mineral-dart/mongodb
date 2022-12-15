import 'package:mineral_ioc/ioc.dart';
import 'package:mineral_mongodb/mineral_mongodb.dart';
import 'package:mineral_mongodb/src/contracts/metadata_contract.dart';
import 'package:mineral_mongodb/src/contracts/schema_contract.dart';

typedef ItemCreator<S> = S Function();

class Metadata extends MetadataContract {
  final Map<Symbol, dynamic> _payload = {};

  @override
  dynamic get (String key) => _payload[Symbol(key)];

  void put (String key, dynamic value) => _payload.putIfAbsent(Symbol(key), () => value);
}

class Schema<T> implements SchemaContract<T> {
  final Metadata _metadata = Metadata();

  @override
  MetadataContract get payload => _metadata;

  String get id => payload.get('_id');

  static dynamic _getPluginManager () {
    final dynamic pluginManager = ioc.services.entries.firstWhere((element) => element.key.toString() == 'PluginManagerCraft').value;
    return pluginManager.use<MongoDB>();
  }

  DbCollection _query () {
    return _getPluginManager().connection.database.collection(T.toString().toLowerCase().replaceAll('model', ''));
  }

  @override
  Future<T> update (Map<String, dynamic> values) async {
    await _query().update(where.eq('_id', ObjectId.parse(id)), { 'bar': 'Miaou' }, writeConcern: WriteConcern(w: 0, wtimeout: 0, fsync: false, j: false));

    values.removeWhere((key, value) => key == 'id' || key == '_id');
    for (final field in values.entries) {
      _metadata._payload[Symbol(field.key)] = field.value;
    }

    return this as T;
  }

  @override
  Future<void> delete () async {
    await _query().deleteOne(where.eq('_id', ObjectId.parse(id)));
  }
}

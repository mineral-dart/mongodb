import 'package:mineral_ioc/ioc.dart';
import 'package:mineral_mongodb/mineral_mongodb.dart';
import 'package:mineral_mongodb/src/contracts/static_schema_contract.dart';
import 'package:mineral_mongodb/src/entities/schema.dart';
import 'package:mineral_mongodb/src/exceptions/schema_exception.dart';

class StaticSchema<T> implements StaticSchemaContract<T> {
  MongoDB _getPluginManager () {
    final dynamic pluginManager = ioc.services.entries.firstWhere((element) => element.key.toString() == 'PluginManagerCraft').value;
    return pluginManager.use<MongoDB>();
  }

  @override
  DbCollection query () {
    _hasSchema();

    return _getPluginManager().connection.database.collection(T.toString().toLowerCase().replaceAll('model', ''));
  }

  @override
  Future<bool> dropCollection () async {
    _hasSchema();
    return await query().drop();
  }

  @override
  Future<bool> clear () async {
    _hasSchema();

    final result = await query().deleteMany(where.exists('_id'));
    return result.isSuccess;
  }

  @override
  Future<List<T>> all () async {
    _hasSchema();

    final caller = _getPluginManager().models.entries.firstWhere((element) => element.key == T).value;
    final List<T> models = [];
    final rows = query().find();

    await for (final row in rows) {
      final instance = caller.call();
      assignFields(instance, row);

      models.add(instance as T);
    }

    return models;
  }

  @override
  Future<T?> findBy (String column, dynamic value) async {
    _hasSchema();

    final row = await query().findOne(where.eq(column == 'id' ? '_$column' : column, ObjectId.parse(value)));
    if (row == null) {
      return null;
    }

    final caller = _getPluginManager().models.entries.firstWhere((element) => element.key == T).value;
    final instance = caller.call();
    assignFields(instance, row);

    return instance as T?;
  }

  @override
  Future<T?> find (String value) async {
    _hasSchema();
    return await findBy('id', value);
  }

  @override
  Future<T> create (Map<String, dynamic> values) async {
    _hasSchema();

    final result = await query().insertOne(values, writeConcern: WriteConcern(w: 0, wtimeout: 0, fsync: false, j: false));

    final caller = _getPluginManager().models.entries.firstWhere((element) => element.key == T).value;
    final instance = caller.call();
    assignFields(instance, { ...values, '_id': result.id });

    return instance as T;
  }

  @override
  Future<List<T>> createMany (List<Map<String, dynamic>> values) async {
    _hasSchema();

    List<T> results = [];
    for (final schema in values) {
      results.add(await create(schema));
    }

    return results;
  }

  /// @nodoc
  void _hasSchema () {
    if (T.toString() == 'dynamic') {
      throw SchemaException('The mongodb schema cannot be found, please provide it');
    }
  }

  /// @nodoc
  V _apply<V> (dynamic value) => value as V;

  /// @nodoc
  void assignFields (Schema<dynamic> instance, Map<String, dynamic> row) {
    for (final field in row.entries) {
      _apply<Metadata>(instance.payload).put(field.key, field.key == '_id'
        ? _apply<ObjectId>(row['_id']).$oid
        : field.value);
    }
  }
}
import 'dart:mirrors';

import 'package:mineral_ioc/ioc.dart';
import 'package:mineral_mongodb/mineral_mongodb.dart';
import 'package:mineral_mongodb/src/exceptions/schema_exception.dart';
import 'package:mineral_mongodb/src/mongodb.dart';
import 'package:mongo_dart/mongo_dart.dart';

class Schema<T extends Schema<T>> {
  late String id;

  static DbCollection query<T> () {
    _hasSchema<T>();
    final MongoDB mongoDB = ioc.singleton(MongoDB.namespace);
    return mongoDB.connection.database.collection(T.toString().toLowerCase());
  }

  static Future<bool> dropCollection<T> () async {
    return await query<T>().drop();
  }

  static Future<dynamic> drop () async {
    final MongoDB mongoDB = ioc.singleton(MongoDB.namespace);
    await mongoDB.connection.database.drop();
  }

  static Future<bool> clear<T> () async {
    final result = await query<T>().deleteMany(where.exists('_id'));
    return result.success;
  }

  static Future<List<T>> all<T> () async {
    final reflected = reflectClass(T);
    final rows = query<T>().find();

    final List<T> results = [];
    await for (final fields in rows) {
      final instance = reflected.newInstance(Symbol(''), []);
      for (final field in fields.entries) {
        if (field.key == '_id') {
          instance.setField(Symbol('id'), field.value);
        } else {
          instance.setField(Symbol(field.key), field.value);
        }
      }

      results.add(instance.reflectee);
    }

    return results;
  }

  static Future<T?> findBy<T> (String column, dynamic value) async {
    final reflected = reflectClass(T);
    final row = await query<T>().findOne(where.eq(column == 'id' ? '_$column' : column, value));

    if (row == null) {
      return null;
    }

    final instance = reflected.newInstance(Symbol(''), []);
    for (final field in row.entries) {
      if (field.key == '_id') {
        instance.setField(Symbol('id'), field.value);
      } else {
        instance.setField(Symbol(field.key), field.value);
      }
    }

    return instance.reflectee;
  }

  static Future<T?> find<T> (dynamic value) async {
    return await findBy<T>('id', value);
  }

  static Future<T> create<T> (void Function(T schema) schema) async {
    final reflected = reflectClass(T);
    final classMirror = reflected.newInstance(Symbol(''), []);

    schema(classMirror.reflectee);

    String uuid = Uuid().v4();
    classMirror.reflectee.id = uuid;

    final Map<String, dynamic> props = {};
    props.putIfAbsent('_id', () => uuid);

    for (final f in classMirror.type.declarations.entries) {
      if (f.value is VariableMirror) {
        final field = MirrorSystem.getName(f.value.simpleName);
        try {
          final value = classMirror.getField(f.key);
          props.putIfAbsent(field, () => value.reflectee);
        } catch (_) {}
      }
    }

    await query<T>().insert(props);

    return classMirror.reflectee;
  }

  static Future<List<T>> createMany<T> (List<void Function(T schema)> schemas) async {
    List<T> results = [];
    for (final schema in schemas) {
      final T result = await create(schema);
      results.add(result);
    }

    return results;
  }


  Future<T> update (void Function(T schema) schema) async {
    final reflected = reflect(this);
    schema(this as T);

    final Map<String, dynamic> props = {};
    for (final f in reflected.type.declarations.entries) {
      if (f.value is VariableMirror) {
        final field = MirrorSystem.getName(f.value.simpleName);
        try {
          final value = reflected.getField(f.key);
          props.putIfAbsent(field, () => value.reflectee);
        } catch (_) {}
      }
    }

    await query<T>().update(where.eq('_id', id), props);
    return reflected.reflectee;
  }

  Future<void> delete () async {
    await query<T>().deleteOne(where.eq('_id', id));
  }

  Object toJson () {
    Map<String, dynamic> fields = {};

    final reflected = reflect(this);
    for (final f in reflected.type.declarations.entries) {
      if (f.value is VariableMirror) {
        final field = MirrorSystem.getName(f.value.simpleName);
        try {
          final value = reflected.getField(f.key);
          fields.putIfAbsent(field, () => value.reflectee);
        } catch (_) {}
      }
    }

    return fields;
  }

  static void _hasSchema<T> () {
    if (T.toString() == 'dynamic') {
      throw SchemaException('The mongodb schema cannot be found, please provide it');
    }
  }
}

import 'dart:mirrors';

import 'package:mineral_ioc/ioc.dart';
import 'package:mineral_mongodb/mineral_mongodb.dart';
import 'package:mineral_mongodb/src/exceptions/schema_exception.dart';
import 'package:mineral_mongodb/src/mongodb.dart';
import 'package:mongo_dart/mongo_dart.dart';

class Schema<T extends Schema<T>> {
  late String id;

  /// Access point to mongodb's native query builder as [DbCollection]
  /// ```dart
  /// class Model {
  ///   late String username;
  ///   late int age;
  /// }
  ///
  /// final DbCollection = Schema.query<Model>();
  /// ```
  static DbCollection query<T> () {
    _hasSchema<T>();
    final MongoDB mongoDB = ioc.singleton(MongoDB.namespace);
    return mongoDB.connection.database.collection(T.toString().toLowerCase());
  }

  /// Delete the current collection
  /// ```dart
  /// class Model {
  ///   late String username;
  ///   late int age;
  /// }
  ///
  /// await Schema.dropCollection<Model>();
  /// ```
  static Future<bool> dropCollection<T> () async {
    return await query<T>().drop();
  }

  /// Delete the database
  /// ```dart
  /// await Schema.drop();
  /// ```
  /// The action requires special permission to operate.
  static Future<dynamic> drop () async {
    final MongoDB mongoDB = ioc.singleton(MongoDB.namespace);
    await mongoDB.connection.database.drop();
  }

  /// Empty the entire current collection
  /// ```dart
  /// class Model {
  ///   late String username;
  ///   late int age;
  /// }
  ///
  /// await Schema.clear<Model>();
  /// ```
  static Future<bool> clear<T> () async {
    final result = await query<T>().deleteMany(where.exists('_id'));
    return result.success;
  }

  /// Get the whole data of the current schema
  /// ```dart
  /// class Model {
  ///   late String username;
  ///   late int age;
  /// }
  ///
  /// final List<Model> models = await Schema.all<Model>();
  /// ```
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

  /// Retrieves the first item found according to a [column] and a [value]
  /// ```dart
  /// class Model {
  ///   late String username;
  ///   late int age;
  /// }
  ///
  /// final Model? models = await Schema.findBy<Model>('username', 'Freeze');
  /// ```
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

  /// Retrieves the first item found according to the _id column from a [value]
  /// ```dart
  /// class Model {
  ///   late String username;
  ///   late int age;
  /// }
  ///
  /// final Model? models = await Schema.find<Model>('81153671-1af6-4ba5-89aa-e36f94a86748');
  /// ```
  static Future<T?> find<T> (dynamic value) async {
    return await findBy<T>('id', value);
  }

  /// Created a new entry in the current collection
  /// ```dart
  /// class Model {
  ///   late String username;
  ///   late int age;
  /// }
  ///
  /// final Model? model = await Schema.create<Model>((model) {
  ///   model.username: 'Freeze',
  ///   model.age: 25,
  /// }));
  /// ```
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

  /// Created several new entries in the current collection
  /// ```dart
  /// class Model {
  ///   late String username;
  ///   late int age;
  /// }
  ///
  /// final List<Model> models = await Schema.createMany<Model>([
  ///   (model) => model.username: 'Freeze',
  ///   (model) => model.username: 'John',
  /// ]);
  /// ```
  static Future<List<T>> createMany<T> (List<void Function(T schema)> schemas) async {
    List<T> results = [];
    for (final schema in schemas) {
      final T result = await create(schema);
      results.add(result);
    }

    return results;
  }


  /// Update a current entry in the current collection
  /// ```dart
  /// class Model {
  ///   late String username;
  ///   late int age;
  /// }
  ///
  /// final Model? model = await Schema.find<Model>('...');
  /// await model.update<Model>((model) {
  ///   model.username = 'John Doe'
  /// });
  /// ```
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

  /// Convert this to json object
  /// ```dart
  /// final Model? model = await Schema.find<Model>('...');
  /// print(model?.toJson());
  /// ```
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

  /// @nodoc
  static void _hasSchema<T> () {
    if (T.toString() == 'dynamic') {
      throw SchemaException('The mongodb schema cannot be found, please provide it');
    }
  }
}

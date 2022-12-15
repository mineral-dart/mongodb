import 'package:mineral_mongodb/mineral_mongodb.dart';
import 'package:mineral_mongodb/src/entities/static_schema.dart';

typedef ModelFactory = Map<dynamic, Schema Function()>;

abstract class MongodbContract {
  ModelFactory get models;

  /// Retrieves the specified model from the application instance
  /// ```dart
  /// class FooModel extends Schema {
  ///   late String username;
  ///   late int age;
  /// }
  ///
  /// class MyClass with Transaction {
  ///   Future<void> handle () async {
  ///     final model = schema.use<FooModel>();
  ///   }
  /// }
  /// ```
  StaticSchema<T> use<T extends Schema> ();

  /// Delete the database
  /// ```dart
  /// class MyClass with Transaction {
  ///   Future<void> handle () async {
  ///     await schema.dropDatabase();
  ///   }
  /// }
  /// ```
  /// The action requires special permission to operate.
  Future<void> dropDatabase ();
}
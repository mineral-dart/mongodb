
import 'package:mineral_mongodb/src/contracts/metadata_contract.dart';

abstract class SchemaContract<T> {
  /// Reflect de votre modèle
  MetadataContract get payload;

  /// Update a current entry in the current collection
  /// ```dart
  /// class FooModel extends Schema<FooModel> {
  ///   String get username => payload.get('username');
  ///   int get age => payload.get('age');
  /// }
  ///
  /// class MyClass with Transaction {
  ///   Future<void> handle () async {
  ///     final foo = await schema.use<FooModel>().find('1234');
  ///     await foo?.update({ age: 26 });
  ///   }
  /// }
  /// ```
  Future<T> update (Map<String, dynamic> values);

  Future<void> delete ();
}
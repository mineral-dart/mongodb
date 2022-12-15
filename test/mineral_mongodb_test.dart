import 'dart:convert';
import 'dart:io';

import 'package:mineral_ioc/ioc.dart';
import 'package:mineral_mongodb/mineral_mongodb.dart';
import 'package:mineral_package/mineral_package.dart';
import 'package:test/test.dart';

class PluginManagerCraft extends MineralService {
  final Map<dynamic, MineralPackage> packages = {};
  T use<T extends MineralPackage> () => packages[T] as T;
}

class FooModel extends Schema<FooModel> {
  String get bar => payload.get('bar');
}

void main() {
  final mongodb = MongoDB({
    FooModel: () => FooModel(),
  });

  final pluginManager = PluginManagerCraft();
  pluginManager.packages.putIfAbsent(MongoDB, () => mongodb);

  ioc.bind((ioc) => pluginManager);

  final environmentFile = File('.env');
  final properties = environmentFile.readAsLinesSync(encoding: utf8);
  final mongodbUrl = properties.firstWhere((element) => element.contains('MONGODB_URL'));
  final url = mongodbUrl.replaceAll(' ', '').split(':').sublist(1);
  final endpoint = url.join(':');

  mongodb.testing(endpoint);

  test('can connect to database', () async {
    await mongodb.open();
    expect(mongodb.connection.database.state, equals(State.open));
  });

  group('use mongodb orm', () {
    test('can create one element', () async {
      final foo = await mongodb.use<FooModel>().create({ 'bar': 'bar' });

      expect(foo, isNotNull);
      expect(foo.runtimeType, equals(FooModel));
      expect(foo.bar, 'bar');
    });

    test('can get all', () async {
      await mongodb.use<FooModel>().create({ 'bar': 'bar' });

      final foo = await mongodb.use<FooModel>().all();
      expect(foo.length, equals(1));
    });

    test('can get one element by id', () async {
      final foo = await mongodb.use<FooModel>().create({ 'bar': 'bar' });

      final result = await mongodb.use<FooModel>().find(foo.id);
      expect(result, isNotNull);
      expect(result?.id, foo.id);
    });

    test('can create many elements', () async {
      final results = await mongodb.use<FooModel>().createMany([
        { 'bar': 'foo1'},
        { 'bar': 'foo2' }
      ]);

      expect(results, isNotNull);
      expect(results.runtimeType, equals(List<FooModel>));
      expect(results.length, equals(2));
    });

    test('can update one element', () async {
      final foo = await mongodb.use<FooModel>().create({ 'bar': 'bar' });

      final result = await foo.update({ 'bar': 'foo' });
      expect(result, isNotNull);
      expect(result.bar, 'foo');
    });

    test('can delete one element', () async {
      final foo = await mongodb.use<FooModel>().create({ 'bar': 'bar' });
      await foo.delete();

      final result = await mongodb.use<FooModel>().all();

      expect(result, isNotNull);
      expect(result, isEmpty);
    });

    tearDown (() async {
      await mongodb.use<FooModel>().dropCollection();
    });
  });
}

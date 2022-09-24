import 'package:mineral_ioc/ioc.dart';
import 'package:mineral_mongodb/mineral_mongodb.dart';
import 'package:mongo_dart/mongo_dart.dart';
import 'package:test/test.dart';

class Foo extends Schema<Foo> {
  late String bar;
}

void main() {
  final endpoint = 'mongodb://127.0.0.1/mongodb';
  final mongodb = MongoDB()
    ..testing(endpoint);

  test('can registered into mineral ioc', () {
    ioc.bind(namespace: MongoDB.namespace, service: mongodb);
    expect(ioc.singleton(MongoDB.namespace), equals(mongodb));
  });

  test('can connect to database', () async {
    await mongodb.open();
    expect(mongodb.connection.database.state, equals(State.OPEN));
  });

  test('can get all', () async {
    final foo = await Schema.all<Foo>();
    expect(foo.length, equals(0));
  });

  test('can create one element', () async {
    final foo = await Schema.create<Foo>((schema) {
        schema.bar = 'bar';
    });

    final result = await Schema.all<Foo>();

    expect(foo.runtimeType, equals(Foo));
    expect(result.length, equals(1));
  });

  test('can create many elements', () async {
    final tests = await Schema.createMany<Foo>([
      (schema) => schema.bar = 'Bar1',
      (schema) => schema.bar = 'Bar2'
    ]);

    expect(tests.length, equals(2));
  });
}

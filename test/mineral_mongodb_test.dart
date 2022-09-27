import 'package:mineral_ioc/ioc.dart';
import 'package:mineral_mongodb/mineral_mongodb.dart';
import 'package:test/test.dart';

class Foo extends Schema<Foo> {
  late String bar;
}

void main() {
  final endpoint = 'mongodb+srv://root:root@cluster0.dp9zo6r.mongodb.net/?retryWrites=true&w=majority';
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

  group('description', () {
    late final Foo foo;

    test('can get all', () async {
      final foo = await Schema.all<Foo>();
      expect(foo.length, equals(0));
    });

    test('can create one element', () async {
      foo = await Schema.create<Foo>((schema) {
        schema.bar = 'bar';
      });

      expect(foo, isNotNull);
      expect(foo.runtimeType, equals(Foo));
      expect(foo.bar, 'bar');
    });

    test('can create many elements', () async {
      final results = await Schema.createMany<Foo>([
        (schema) => schema.bar = 'Bar1',
        (schema) => schema.bar = 'Bar2'
      ]);

      expect(results, isNotNull);
      expect(results.runtimeType, equals(List<Foo>));
      expect(results.length, equals(2));
    });

    tearDownAll (() async {
      await Schema.drop();
    });
  });
}

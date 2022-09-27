# 📦 MongoDB

The mongoDB module was designed exclusively for the Mineral framework, it allows you to communicate with a MongoDB
database.

## Register the module
After installing the module, please register it within `./src/main.dart` following the scheme below

```dart
import 'package:mineral_mongodb/mineral_mongodb.dart';

Future<void> main() async {
  final mongoDB = MongoDB();

  Kernel kernel = Kernel()
    ..intents.defined(all: true)
    ..plugins.use([mongoDB]);

  await kernel.init();
}
```

## Usage
Like a classic use of MongoDB technology, the Mineral framework requires you to use Models representing your noSQL schema.

We will create our first model :
```dart
class Foo {
  late String username;
  late int age;
}
```

### Create all foo
```dart
import 'package:mineral_mongodb/mineral_mongodb.dart';

final List<Foo> foo = await Schema.all<Foo>();
```

### Find one foo
```dart
import 'package:mineral_mongodb/mineral_mongodb.dart';

final Foo? foo = await Schema.find<Foo>('.....');
```

### Find one foo from defined column
```dart
import 'package:mineral_mongodb/mineral_mongodb.dart';

final Foo? foo = await Schema.findBy<Foo>('username', 'John Doe');
```


### Create one foo
```dart
import 'package:mineral_mongodb/mineral_mongodb.dart';

final Foo? foo = await Schema.create<Foo>((schema) {
  schema.username = 'John Doe',
  schema.age = 25,
});
```

### Create many foo
```dart
import 'package:mineral_mongodb/mineral_mongodb.dart';

final List<Foo> foo = await Schema.createMany<Foo>([
  (model) => model.username: 'Freeze',
  (model) => model.username: 'John',
]);
```

### Update one foo
```dart
import 'package:mineral_mongodb/mineral_mongodb.dart';

final Foo? foo = Schema.find<Foo>('...');

await foo?.update((schema) {
  schema.username = 'John Doe',
  schema.age = 25,
});
```

### Delete one foo
```dart
import 'package:mineral_mongodb/mineral_mongodb.dart';

final Foo? foo = Schema.find<Foo>('...');
await foo?.delete();
```

### Access to mongodb query builder
```dart
import 'package:mineral_mongodb/mineral_mongodb.dart';

final DbCollection? fooCollection = Schema.query<Foo>();
```
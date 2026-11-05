# Data classes

Generates the `copyWith`, `==` and `hashCode` of the data classes of the
package, so no hand keeps 96 and 30 fields in step three times:

    dart pub get -C tool/data_classes
    dart tool/data_classes/bin/data_classes.dart

from the root of the package. Each class (`classes` in
`bin/data_classes.dart`) gets a part file in `lib/src/generated`, with a
mixin `_$Name` the class applies. The fields are the parameters of the
unnamed constructor, in their order, with the types of the fields:

- a nullable field takes the `unset` sentinel in `copyWith`, so `null`
  clears it;
- a `List` compares element by element, a `Map` by entry and a `Set` by
  membership;
- `hashCode` is `Object.hashAll` over the fields, a `Map` and a `Set`
  hashed unordered.

A new field needs only its declaration and its constructor parameter, then
a run of the generator. The job Quality fails when the generated files
differ from what the generator emits. test/models/data_classes_test.dart
checks the generated code against the code written by hand up to 0.6.1.

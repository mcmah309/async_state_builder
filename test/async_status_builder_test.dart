import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Keys work as expected', () { 
    expect(Object(), isNot(Object()));
    expect((1,"String"), (1,"String"));
    final object = Object();
    expect((1,"String",object), (1,"String",object));
    expect((1,"String",object), isNot((1,"Strin",object)));
  });
}
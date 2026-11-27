import 'package:app_mascotas/features/pets/add_pet_screen.dart';
import 'package:app_mascotas/features/pets/pet_mascot.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('La ilustración sigue la especie seleccionada', (tester) async {
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: AddPetScreen()),
    ));
    String species() => tester.widget<PetMascot>(find.byType(PetMascot)).species;
    expect(species(), 'dog');
    await tester.tap(find.text('Perro').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Gato').last);
    await tester.pumpAndSettle();
    expect(species(), 'cat');
  });
}

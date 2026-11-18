import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lost_and_found/ui/home.dart';
import 'package:lost_and_found/domain/listing.dart';
import 'package:lost_and_found/domain/listing_repository.dart';

class MemoryRepository implements ListingRepository {
  List<Listing> values = [];
  bool failLoad = false, failSave = false;
  @override
  Future<List<Listing>> load() async {
    if (failLoad) throw StateError('Unavailable');
    return values;
  }

  @override
  Future<void> save(List<Listing> listings) async {
    if (failSave) throw StateError('Storage full');
    values = listings;
  }
}

void main() {
  testWidgets(
    'mobile creates, searches and changes language without losing data',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = MemoryRepository();
      await tester.pumpWidget(
        MaterialApp(home: Home(repository: () async => repository)),
      );
      await tester.pumpAndSettle();
      expect(find.text('Nenhum objeto por aqui ainda'), findsOneWidget);
      await tester.tap(find.text('Registrar objeto'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome do objeto'),
        'Guarda-chuva azul',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Descrição pública'),
        'Um guarda-chuva perto do banco',
      );
      await tester.enterText(
        find.widgetWithText(
          TextFormField,
          'Bairro ou espaço público (sem endereço)',
        ),
        'Centro',
      );
      await tester.tap(find.text('Salvar neste navegador'));
      await tester.pumpAndSettle();
      expect(repository.values.single.title, 'Guarda-chuva azul');
      await tester.tap(find.text('EN'));
      await tester.pumpAndSettle();
      expect(find.text('LOCAL DEMONSTRATION'), findsOneWidget);
      final search = find.widgetWithText(TextField, 'Search items or areas');
      await tester.ensureVisible(search);
      await tester.enterText(search, 'GUARDA');
      await tester.pumpAndSettle();
      expect(find.text('Guarda-chuva azul'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('load error can be retried without replacing saved data', (
    tester,
  ) async {
    final repository = MemoryRepository()..failLoad = true;
    await tester.pumpWidget(
      MaterialApp(home: Home(repository: () async => repository)),
    );
    await tester.pumpAndSettle();
    expect(find.text('Seus dados não foram alterados.'), findsOneWidget);
    repository.failLoad = false;
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    expect(find.text('Nenhum objeto por aqui ainda'), findsOneWidget);
  });
  testWidgets(
    'editing then confirmed resolution updates filters and locks the record',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = MemoryRepository();
      repository.values = [
        Listing.create(
          id: 'test',
          title: 'Chave azul',
          description: 'Registro fictício na biblioteca',
          area: 'Centro',
          category: Category.accessories,
          kind: ListingKind.found,
        ),
      ];
      await tester.pumpWidget(
        MaterialApp(home: Home(repository: () async => repository)),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Ver detalhes'));
      await tester.tap(find.text('Ver detalhes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Editar'));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Nome do objeto'),
        'Chave vermelha',
      );
      await tester.tap(find.text('Salvar neste navegador'));
      await tester.pumpAndSettle();
      expect(repository.values.single.title, 'Chave vermelha');
      await tester.ensureVisible(find.text('Ver detalhes'));
      await tester.tap(find.text('Ver detalhes'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Simular resolução'));
      await tester.pumpAndSettle();
      final complete = find.widgetWithText(FilledButton, 'Concluir simulação');
      expect(tester.widget<FilledButton>(complete).onPressed, isNull);
      await tester.enterText(
        find.byType(TextFormField),
        'Simulação conferida no balcão',
      );
      await tester.tap(find.byType(CheckboxListTile));
      await tester.pumpAndSettle();
      await tester.tap(complete);
      await tester.pumpAndSettle();
      expect(repository.values.single.status, ListingStatus.resolved);
      expect(find.text('Ver detalhes'), findsNothing);
      await tester.ensureVisible(find.text('Resolvidos'));
      await tester.tap(find.text('Resolvidos'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Ver detalhes'));
      await tester.tap(find.text('Ver detalhes'));
      await tester.pumpAndSettle();
      expect(find.text('Editar'), findsNothing);
      expect(find.text('Simular resolução'), findsNothing);
      expect(
        find.textContaining('Simulação conferida no balcão'),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'failed save preserves visible state and retries the pending snapshot',
    (tester) async {
      tester.view.physicalSize = const Size(1200, 1100);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = MemoryRepository()..failSave = true;
      await tester.pumpWidget(
        MaterialApp(home: Home(repository: () async => repository)),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Carregar 3 exemplos fictícios'));
      await tester.tap(find.text('Carregar 3 exemplos fictícios'));
      await tester.pumpAndSettle();
      expect(repository.values, isEmpty);
      expect(find.text('Nenhum objeto por aqui ainda'), findsOneWidget);
      repository.failSave = false;
      await tester.tap(find.text('Tentar novamente'));
      await tester.pumpAndSettle();
      expect(repository.values.length, 3);
      expect(find.text('Chaves com chaveiro azul'), findsOneWidget);
    },
  );
}

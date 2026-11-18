import 'package:flutter_test/flutter_test.dart';
import 'package:lost_and_found/domain/listing.dart';
import 'package:lost_and_found/data/local_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  Listing item({String title = 'Óculos azul'}) => Listing.create(
    id: 'a',
    title: title,
    description: 'Na praça central',
    area: 'Centro',
    category: Category.accessories,
    kind: ListingKind.found,
  );

  test('search ignores accents and combines category and status filters', () {
    final all = [item(), item(title: 'Mochila')];
    expect(
      searchListings(
        all,
        query: 'oculos',
        category: Category.accessories,
        status: ListingStatus.open,
      ).length,
      1,
    );
    expect(searchListings(all, category: Category.documents), isEmpty);
  });
  test('invalid content and sensitive contact information are rejected', () {
    expect(() => item(title: '  '), throwsFormatException);
    expect(() => item(title: 'Ligue 11987654321'), throwsFormatException);
    expect(() => item(title: 'user@example.com'), throwsFormatException);
  });
  test(
    'resolution requires confirmation and a note and cannot be repeated',
    () {
      final original = item();
      expect(
        () => original.resolve('Confirmado', confirmed: false),
        throwsStateError,
      );
      expect(
        () => original.resolve(' ', confirmed: true),
        throwsFormatException,
      );
      final resolved = original.resolve(
        'Simulação confirmada no balcão',
        confirmed: true,
      );
      expect(resolved.status, ListingStatus.resolved);
      expect(resolved.kind, ListingKind.found);
      expect(
        () => resolved.resolve('Outra', confirmed: true),
        throwsStateError,
      );
    },
  );
  test('create, edit and resolve survive a repository reload', () async {
    SharedPreferences.setMockInitialValues({});
    final repository = LocalListingRepository(
      await SharedPreferences.getInstance(),
    );
    await repository.save([item()]);
    var loaded = await repository.load();
    expect(loaded.single.title, 'Óculos azul');
    loaded = [
      loaded.single.edit(
        title: 'Óculos preto',
        description: 'Na praça central',
        area: 'Centro',
        category: Category.accessories,
      ),
    ];
    await repository.save([
      loaded.single.resolve('Demonstração concluída', confirmed: true),
    ]);
    final reloaded = await LocalListingRepository(
      await SharedPreferences.getInstance(),
    ).load();
    expect(reloaded.single.title, 'Óculos preto');
    expect(reloaded.single.status, ListingStatus.resolved);
  });
  test(
    'corrupt storage is surfaced rather than replaced with fixtures',
    () async {
      SharedPreferences.setMockInitialValues({'reencontra.v1': '{broken'});
      final repository = LocalListingRepository(
        await SharedPreferences.getInstance(),
      );
      expect(repository.load(), throwsFormatException);
    },
  );
}

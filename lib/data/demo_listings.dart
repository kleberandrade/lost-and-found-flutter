import '../domain/listing.dart';

List<Listing> demoListings() => [
  Listing.create(
    id: 'demo-keys',
    title: 'Chaves com chaveiro azul',
    description:
        'Um molho de chaves com chaveiro de tecido. Descreva um detalhe para reconhecer.',
    area: 'Centro · Praça da biblioteca',
    category: Category.accessories,
    kind: ListingKind.found,
  ),
  Listing.create(
    id: 'demo-bag',
    title: 'Mochila verde',
    description:
        'Mochila de uso diário, sem documentos expostos. Registro fictício para aprendizado.',
    area: 'Vila Nova · Parque municipal',
    category: Category.bags,
    kind: ListingKind.lost,
    createdAt: DateTime.now().subtract(const Duration(hours: 2)),
  ),
  Listing.create(
    id: 'demo-headphones',
    title: 'Fone de ouvido',
    description:
        'Fone sem fio em um estojo. O proprietário deve identificar a marca no balcão.',
    area: 'Centro · Terminal de ônibus',
    category: Category.electronics,
    kind: ListingKind.found,
    createdAt: DateTime.now().subtract(const Duration(hours: 5)),
  ),
];

import 'dart:convert';

enum ListingKind { found, lost }

enum ListingStatus { open, resolved }

enum Category { accessories, electronics, documents, bags, pets, other }

String normalize(String value) {
  const accents = 'áàâãäéèêëíìîïóòôõöúùûüç';
  const plain = 'aaaaaeeeeiiiiooooouuuuc';
  var result = value.toLowerCase();
  for (var i = 0; i < accents.length; i++) {
    result = result.replaceAll(accents[i], plain[i]);
  }
  return result;
}

String validatePublicText(String value, {int min = 3, int max = 400}) {
  final text = value.trim();
  if (text.length < min || text.length > max) {
    throw FormatException('Use $min–$max caracteres / characters.');
  }
  if (RegExp(
    r'@|https?://|\d[\d\s()+.-]{7,}\d|[-+]?\d{1,3}[.,]\d{4,}',
  ).hasMatch(text)) {
    throw const FormatException(
      'Remova contatos, links e coordenadas / Remove contacts, links and coordinates.',
    );
  }
  return text;
}

class Listing {
  final String id, title, description, area;
  final Category category;
  final ListingKind kind;
  final ListingStatus status;
  final DateTime createdAt;
  final String? photo, resolution;
  final DateTime? resolvedAt;

  const Listing._({
    required this.id,
    required this.title,
    required this.description,
    required this.area,
    required this.category,
    required this.kind,
    required this.status,
    required this.createdAt,
    this.photo,
    this.resolution,
    this.resolvedAt,
  });

  factory Listing.create({
    required String id,
    required String title,
    required String description,
    required String area,
    required Category category,
    required ListingKind kind,
    String? photo,
    DateTime? createdAt,
  }) {
    if (id.isEmpty) throw const FormatException('Missing ID');
    validatePhoto(photo);
    return Listing._(
      id: id,
      title: validatePublicText(title, max: 70),
      description: validatePublicText(description),
      area: validatePublicText(area, max: 60),
      category: category,
      kind: kind,
      status: ListingStatus.open,
      createdAt: createdAt ?? DateTime.now(),
      photo: photo,
    );
  }

  Listing edit({
    required String title,
    required String description,
    required String area,
    required Category category,
    String? photo,
  }) {
    if (status == ListingStatus.resolved) {
      throw StateError('Resolved items are read-only');
    }
    return Listing.create(
      id: id,
      title: title,
      description: description,
      area: area,
      category: category,
      kind: kind,
      photo: photo,
      createdAt: createdAt,
    );
  }

  Listing resolve(String note, {required bool confirmed}) {
    if (!confirmed || status != ListingStatus.open) {
      throw StateError('Confirm an open listing before resolving it');
    }
    return Listing._(
      id: id,
      title: title,
      description: description,
      area: area,
      category: category,
      kind: kind,
      status: ListingStatus.resolved,
      createdAt: createdAt,
      photo: photo,
      resolution: validatePublicText(note, max: 160),
      resolvedAt: DateTime.now(),
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'area': area,
    'category': category.name,
    'kind': kind.name,
    'status': status.name,
    'createdAt': createdAt.toIso8601String(),
    'photo': photo,
    'resolution': resolution,
    'resolvedAt': resolvedAt?.toIso8601String(),
  };

  factory Listing.fromJson(Map<String, dynamic> json) {
    try {
      final base = Listing.create(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        area: json['area'] as String,
        category: Category.values.byName(json['category'] as String),
        kind: ListingKind.values.byName(json['kind'] as String),
        photo: json['photo'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
      final status = ListingStatus.values.byName(json['status'] as String);
      if (status == ListingStatus.open) {
        if (json['resolution'] != null || json['resolvedAt'] != null) {
          throw const FormatException('Invalid open state');
        }
        return base;
      }
      return Listing._(
        id: base.id,
        title: base.title,
        description: base.description,
        area: base.area,
        category: base.category,
        kind: base.kind,
        status: status,
        createdAt: base.createdAt,
        photo: base.photo,
        resolution: validatePublicText(json['resolution'] as String, max: 160),
        resolvedAt: DateTime.parse(json['resolvedAt'] as String),
      );
    } catch (_) {
      throw const FormatException('Invalid stored listing');
    }
  }
}

void validatePhoto(String? photo) {
  if (photo == null) return;
  try {
    final bytes = base64Decode(photo);
    final jpeg =
        bytes.length > 3 &&
        bytes[0] == 255 &&
        bytes[1] == 216 &&
        bytes[2] == 255;
    final png =
        bytes.length > 8 &&
        bytes[0] == 137 &&
        bytes[1] == 80 &&
        bytes[2] == 78 &&
        bytes[3] == 71;
    if (bytes.length > 350000 || (!jpeg && !png)) throw const FormatException();
  } catch (_) {
    throw const FormatException('Use PNG/JPEG até 350 KB / up to 350 KB.');
  }
}

List<Listing> searchListings(
  Iterable<Listing> items, {
  String query = '',
  Category? category,
  ListingKind? kind,
  ListingStatus? status,
}) {
  final needle = normalize(query.trim());
  return items
      .where(
        (item) =>
            (category == null || item.category == category) &&
            (kind == null || item.kind == kind) &&
            (status == null || item.status == status) &&
            normalize(
              '${item.title} ${item.description} ${item.area}',
            ).contains(needle),
      )
      .toList()
    ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
}

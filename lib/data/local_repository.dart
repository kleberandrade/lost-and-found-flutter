import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../domain/listing.dart';
import '../domain/listing_repository.dart';

class LocalListingRepository implements ListingRepository {
  final SharedPreferences preferences;
  LocalListingRepository(this.preferences);
  static const key = 'reencontra.v1';

  @override
  Future<List<Listing>> load() async {
    final data = preferences.getString(key);
    if (data == null) return [];
    try {
      final decoded = jsonDecode(data) as List<dynamic>;
      return decoded
          .map((value) => Listing.fromJson(value as Map<String, dynamic>))
          .toList();
    } catch (_) {
      throw const FormatException(
        'Não foi possível ler os registros / Cannot read saved listings.',
      );
    }
  }

  @override
  Future<void> save(List<Listing> listings) async {
    final encoded = jsonEncode(listings.map((item) => item.toJson()).toList());
    if (encoded.length > 3000000) {
      throw StateError('Limite local de 3 MB / Local 3 MB limit.');
    }
    if (!await preferences.setString(key, encoded)) {
      throw StateError('Falha ao salvar / Save failed.');
    }
  }
}

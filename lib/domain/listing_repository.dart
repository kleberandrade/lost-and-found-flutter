import 'listing.dart';

/// Replace this boundary with an authenticated backend; never imply local users
/// or ownership claims are server-verified identities.
abstract interface class ListingRepository {
  Future<List<Listing>> load();
  Future<void> save(List<Listing> listings);
}

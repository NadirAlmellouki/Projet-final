import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';

/// Résultat de géocodage avec distance par rapport à l'utilisateur.
class GeocodingResult {
  const GeocodingResult({
    required this.lat,
    required this.lng,
    required this.displayName,
    required this.distanceKm,
  });

  final double lat;
  final double lng;
  final String displayName;
  final double distanceKm;
}

/// Géocodage du lieu saisi : synonymes + priorité aux endroits proches de vous.
class GeocodingService {
  GeocodingService._();

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 12),
      receiveTimeout: const Duration(seconds: 12),
      headers: const {
        'User-Agent': 'StudySyncApp/1.0 (student study sessions)',
      },
    ),
  );

  static const Map<String, List<String>> _synonymGroups = {
    'bibliothèque': ['biblio', 'library', 'bibliotheque', 'médiathèque', 'mediatheque'],
    'biblio': ['bibliothèque', 'library', 'bibliotheque'],
    'library': ['bibliothèque', 'biblio'],
    'faculté': ['fac', 'facs', 'université', 'university', 'faculte'],
    'fac': ['faculté', 'université', 'facs'],
    'université': ['faculté', 'fac', 'university', 'univ', 'universite'],
    'univ': ['université', 'faculté'],
    'amphi': ['amphithéâtre', 'amphitheatre'],
    'café': ['cafe', 'coffee', 'cafeteria', 'cafétéria'],
    'cafe': ['café', 'coffee'],
    'cantine': ['restaurant universitaire', 'ru', 'self'],
    'parc': ['park', 'jardin', 'garden'],
    'gare': ['station', 'train station'],
    'mosquée': ['mosque', 'mosquee'],
    'centre': ['center', 'mall', 'centre commercial'],
    'école': ['school', 'lycée', 'lycee', 'college', 'collège'],
    'hôpital': ['hopital', 'hospital', 'chu'],
    'stade': ['stadium', 'terrain'],
    'mcdo': ['mcdonalds', 'macdo'],
  };

  /// Meilleur lieu proche de [nearLat]/[nearLng].
  static Future<GeocodingResult> geocodeNearMe(
    String query, {
    required double nearLat,
    required double nearLng,
    double maxDistanceKm = 50,
  }) async {
    final list = await searchNearMe(
      query,
      nearLat: nearLat,
      nearLng: nearLng,
      maxDistanceKm: maxDistanceKm,
    );
    if (list.isEmpty) {
      throw Exception(
        'Aucun lieu « ${query.trim()} » trouvé à moins de '
        '${maxDistanceKm.round()} km. Essayez un autre nom (biblio, fac, café…).',
      );
    }
    return list.first;
  }

  /// Tous les lieux proches correspondants (synonymes inclus), triés par pertinence.
  static Future<List<GeocodingResult>> searchNearMe(
    String query, {
    required double nearLat,
    required double nearLng,
    double maxDistanceKm = 50,
  }) async {
    final q = query.trim();
    if (q.isEmpty) {
      throw Exception('Indiquez un lieu (ex. Bibliothèque, Faculté des sciences)');
    }

    final city = await _reverseGeocodeCity(nearLat, nearLng);
    final variants = _buildQueryVariants(q, city);
    final viewbox = _viewboxAround(nearLat, nearLng, maxDistanceKm);

    final candidates = <_Candidate>[];
    final seen = <String>{};

    for (var i = 0; i < variants.length; i++) {
      if (i > 0) {
        await Future<void>.delayed(const Duration(milliseconds: 350));
      }
      final batch = await _searchNominatim(
        variants[i],
        viewbox: viewbox,
        nearLat: nearLat,
        nearLng: nearLng,
      );
      for (final c in batch) {
        final key = '${c.lat.toStringAsFixed(4)}_${c.lng.toStringAsFixed(4)}';
        if (seen.add(key)) candidates.add(c);
      }
    }

    if (candidates.isEmpty) {
      final wider = await _searchNominatim(
        city != null ? '$q, $city, Maroc' : '$q, Maroc',
        viewbox: _viewboxAround(nearLat, nearLng, maxDistanceKm * 1.5),
        nearLat: nearLat,
        nearLng: nearLng,
        limit: 8,
      );
      candidates.addAll(wider);
    }

    final nearby = candidates
        .where((c) => c.distanceKm <= maxDistanceKm)
        .toList()
      ..sort((a, b) => b.scoreFor(q).compareTo(a.scoreFor(q)));

    return nearby
        .map(
          (c) => GeocodingResult(
            lat: c.lat,
            lng: c.lng,
            displayName: c.displayName,
            distanceKm: c.distanceKm,
          ),
        )
        .toList();
  }

  static List<String> _buildQueryVariants(String query, String? city) {
    final variants = <String>{query};
    final lower = query.toLowerCase();

    for (final entry in _synonymGroups.entries) {
      if (!lower.contains(entry.key)) continue;
      for (final syn in entry.value) {
        variants.add(
          query.replaceAll(
            RegExp(RegExp.escape(entry.key), caseSensitive: false),
            syn,
          ),
        );
      }
    }

    for (final entry in _synonymGroups.entries) {
      for (final syn in entry.value) {
        if (lower.contains(syn)) {
          variants.add(
            query.replaceAll(
              RegExp(RegExp.escape(syn), caseSensitive: false),
              entry.key,
            ),
          );
        }
      }
    }

    if (city != null && city.isNotEmpty && !lower.contains(city.toLowerCase())) {
      variants.add('$query, $city');
      variants.add('$query, $city, Maroc');
    }

    if (!lower.contains('maroc') && !lower.contains('morocco')) {
      variants.add('$query, Maroc');
    }

    return variants.take(10).toList();
  }

  static String _viewboxAround(double lat, double lng, double radiusKm) {
    final delta = radiusKm / 111.0;
    final lonDelta = delta / math.cos(lat * math.pi / 180).clamp(0.3, 1.0);
    final left = lng - lonDelta;
    final right = lng + lonDelta;
    final top = lat + delta;
    final bottom = lat - delta;
    return '$left,$top,$right,$bottom';
  }

  static Future<String?> _reverseGeocodeCity(double lat, double lng) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        'https://nominatim.openstreetmap.org/reverse',
        queryParameters: {
          'lat': lat,
          'lon': lng,
          'format': 'json',
          'zoom': 12,
          'addressdetails': 1,
        },
      );
      final address = response.data?['address'];
      if (address is! Map) return null;
      final map = Map<String, dynamic>.from(address);
      for (final key in [
        'city',
        'town',
        'village',
        'municipality',
        'county',
        'state',
      ]) {
        final v = map[key]?.toString().trim();
        if (v != null && v.isNotEmpty) return v;
      }
    } catch (_) {}
    return null;
  }

  static Future<List<_Candidate>> _searchNominatim(
    String q, {
    required String viewbox,
    required double nearLat,
    required double nearLng,
    int limit = 6,
  }) async {
    try {
      final response = await _dio.get<List<dynamic>>(
        'https://nominatim.openstreetmap.org/search',
        queryParameters: {
          'q': q,
          'format': 'json',
          'limit': limit,
          'addressdetails': 0,
          'viewbox': viewbox,
          'bounded': 1,
        },
      );

      final list = response.data;
      if (list == null || list.isEmpty) return [];

      final out = <_Candidate>[];
      for (final raw in list) {
        if (raw is! Map) continue;
        final item = Map<String, dynamic>.from(raw);
        final lat = double.tryParse('${item['lat']}');
        final lng = double.tryParse('${item['lon']}');
        if (lat == null || lng == null) continue;

        final distM = Geolocator.distanceBetween(nearLat, nearLng, lat, lng);
        final displayName = item['display_name']?.toString().trim();
        if (displayName == null || displayName.isEmpty) continue;

        out.add(
          _Candidate(
            lat: lat,
            lng: lng,
            displayName: displayName,
            distanceKm: distM / 1000,
            importance: double.tryParse('${item['importance']}') ?? 0,
          ),
        );
      }
      return out;
    } catch (_) {
      return [];
    }
  }
}

class _Candidate {
  _Candidate({
    required this.lat,
    required this.lng,
    required this.displayName,
    required this.distanceKm,
    required this.importance,
  });

  final double lat;
  final double lng;
  final String displayName;
  final double distanceKm;
  final double importance;

  double scoreFor(String originalQuery) {
    final name = displayName.toLowerCase();
    final tokens = originalQuery
        .toLowerCase()
        .split(RegExp(r'[\s,;]+'))
        .where((t) => t.length > 2);

    var tokenScore = 0.0;
    for (final t in tokens) {
      if (name.contains(t)) tokenScore += 3;
    }

    return tokenScore * 8 + importance * 2 - distanceKm;
  }
}

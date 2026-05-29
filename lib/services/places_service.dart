import 'dart:convert';
import 'package:http/http.dart' as http;

class PlaceSuggestion {
  final String displayName;
  final double lat;
  final double lon;

  PlaceSuggestion(
      {required this.displayName, required this.lat, required this.lon});
}

class PlacesService {
  // Use Nominatim (OpenStreetMap) for free autocomplete lookup.
  // Keep requests polite: include a user-agent.

  Future<List<PlaceSuggestion>> search(String query, {int limit = 8}) async {
    if (query.trim().isEmpty) return [];
    final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search?format=jsonv2&q=${Uri.encodeQueryComponent(query)}&limit=$limit&addressdetails=1');
    final resp = await http.get(uri,
        headers: {'User-Agent': 'cafe-finder/1.0 (contact@example.com)'});
    if (resp.statusCode != 200) return [];
    final data = json.decode(resp.body) as List<dynamic>;
    return data.map((e) {
      final lat = double.tryParse(e['lat']?.toString() ?? '') ?? 0.0;
      final lon = double.tryParse(e['lon']?.toString() ?? '') ?? 0.0;
      final display = e['display_name'] ?? e['name'] ?? '';
      return PlaceSuggestion(displayName: display, lat: lat, lon: lon);
    }).toList();
  }
}

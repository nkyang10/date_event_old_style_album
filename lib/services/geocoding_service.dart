import 'dart:convert';
import 'package:http/http.dart' as http;

class GeocodingService {
  Future<String?> reverseGeocode(double latitude, double longitude) async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://nominatim.openstreetmap.org/reverse?lat=$latitude&lon=$longitude&format=json&zoom=10'),
        headers: {
          'User-Agent': 'PhotoOrganizerApp/1.0',
          'Accept-Language': 'en',
        },
      );

      if (response.statusCode != 200) return null;

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final address = data['address'] as Map<String, dynamic>?;

      if (address == null) return null;

      // Try city, town, village, county, state, country in order
      final city = address['city'] ??
          address['town'] ??
          address['village'] ??
          address['county'] ??
          address['state'];
      final country = address['country'];

      if (city != null && country != null) {
        return '$city, $country';
      } else if (city != null) {
        return city as String;
      } else if (country != null) {
        return country as String;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

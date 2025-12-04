import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../services/event_api.dart';

class TicketmasterApi {
  static const String _baseUrl =
      'https://app.ticketmaster.com/discovery/v2/events.json';

  static String get _apiKey {
    final key = dotenv.env['TICKETMASTER_API_KEY'];
    if (key == null || key.isEmpty) {
      throw Exception('TICKETMASTER_API_KEY not found in .env file');
    }
    return key;
  }

  static Future<List<Event>> fetchEvents({String city = 'Chicago'}) async {
    final url = Uri.parse(
      '$_baseUrl?apikey=$_apiKey&city=$city&classificationName=music',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final events = data['_embedded']?['events'] as List?;
      if (events == null) return [];
      return events.map((e) => Event.fromJson(e)).toList();
    } else {
      throw Exception('Failed to load events');
    }
  }
}

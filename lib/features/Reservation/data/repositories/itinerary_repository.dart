
import 'package:dio/dio.dart';
import 'package:front/constants/strings.dart';
import 'package:front/features/Reservation/data/models/itinerary_model.dart';

class ItineraryRepository {
  Dio _dio = Dio();


  Future<List<ItineraryModel>> getAllItineraries() async {
    try {
      final response = await _dio.get('$baseUrl/itinerary/getAllItinerary');
      final data = response.data as List<dynamic>;
      final itineraries = data
          .map((json) => ItineraryModel(
                name: json['name'],
                stations: List<MarkerModel>.from(json['stations'].map(
                  (station) => MarkerModel(
                    name: station['name'],
                    description: station['description'],
                    latitude: station['latitude'],
                    longitude: station['longitude'],
                  ),
                )),
              ))
          .toList();
      return itineraries;
    } catch (error) {
      throw Exception('Failed to fetch itineraries');
    }
  }
}
  




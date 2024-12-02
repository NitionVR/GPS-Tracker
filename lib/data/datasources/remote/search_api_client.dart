import 'package:dio/dio.dart';

class SearchApiClient{
  final Dio _dio = Dio();

  Future<List<String>> getLocationSuggestions(String query) async{
    final String apiUrl = "<API_ENDPOINT>?query=$query";
    final response = await _dio.get(apiUrl);

    if (response.statusCode == 200){
      List<dynamic> results = response.data;
      return results.map((result) => result['display_name'] as String).toList();
    }
    return [];
  }

}

import 'package:http/http.dart' as http;
import 'dart:convert';

class Post {
  final String fromCurrencyCode;
  final String fromCurrencyName;
  final String toCurrencyCode;
  final String toCurrencyName;
  final String exchangeRate;
  final String lastRefreshed;
  final String timeZone;
  final Map realtimeExchangeRateMap;

  Post({this.realtimeExchangeRateMap, this.fromCurrencyCode, this.fromCurrencyName, this.toCurrencyCode, this.toCurrencyName, this.exchangeRate, this.lastRefreshed, this.timeZone});

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      realtimeExchangeRateMap: json['Realtime Currency Exchange Rate'],
      fromCurrencyCode: json['Realtime Currency Exchange Rate']['1. From_Currency Code'],
      fromCurrencyName: json['Realtime Currency Exchange Rate']['2. From_Currency Name'],
      toCurrencyCode: json['Realtime Currency Exchange Rate']['3. To_Currency Code'],
      toCurrencyName: json['Realtime Currency Exchange Rate']['4. To_Currency Name'],
      exchangeRate: json['Realtime Currency Exchange Rate']['5. Exchange Rate'],
      lastRefreshed: json['Realtime Currency Exchange Rate']['6. Last Refreshed'],
      timeZone: json['Realtime Currency Exchange Rate']['7. Time Zone'],
    );
  }
}

Future<Post> fetchPost(String fromCurrencyCode, String toCurrencyCode) async {
  String apiKey = '4WDHBYVHGAJ9OQ0A';
  String query = 'https://www.alphavantage.co/query?function=CURRENCY_EXCHANGE_RATE&from_currency=${fromCurrencyCode}&to_currency=${toCurrencyCode}&apikey=${apiKey}';
  print('query: $query');
  final response =
      await http.get(query);

  if (response.statusCode == 200) {
    // If the call to the server was successful, parse the JSON
    return Post.fromJson(json.decode(response.body));
  } else {
    // If that call was not successful, throw an error.
    throw Exception('Failed to load post');
  }
  
}
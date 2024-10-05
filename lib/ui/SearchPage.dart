import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SearchPage extends StatefulWidget {
  @override
  _SearchPageState createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  TextEditingController _searchController = TextEditingController();
  List<dynamic> _suggestions = [];
  bool _isSearchActive = false;
  bool _isLoading = false;

  final String _mapboxAccessToken = 'pk.eyJ1IjoiZW1pbmlhbnQiLCJhIjoiY20xdXRuZmM5MDQyNDJrcGlrcTJuc3h6cCJ9.PKYZ401C7yYeyKTfd_jHCA';
  final String _weatherAPIApiKey = '6a5fdf1096094ee3812233148240310'; // Remplacez par votre clé API Tomorrow

  Future<void> _getSuggestions(String query) async {
    setState(() {
      _isLoading = true;
    });

    final String url = 'https://api.mapbox.com/geocoding/v5/mapbox.places/$query.json?access_token=$_mapboxAccessToken&autocomplete=true&limit=5';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      setState(() {
        _suggestions = json.decode(response.body)['features'];
      });
    } else {
      throw Exception('Échec du chargement des suggestions');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<Map<String, dynamic>> _getWeather(double latitude, double longitude) async {
    final String url = 'http://api.weatherapi.com/v1/current.json?key=$_weatherAPIApiKey&q=$latitude,$longitude';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      // Extraire la température, le texte des conditions et l'icône
      double temperature = data['current']['temp_c'];
      String conditionText = data['current']['condition']['text'];
      String conditionIcon = data['current']['condition']['icon'];

      return {
        'temperature': temperature,
        'conditionText': conditionText,
        'conditionIcon': conditionIcon,
      };
    } else {
      throw Exception('Échec du chargement des données météorologiques');
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isDarkTheme = Theme.of(context).brightness == Brightness.dark;

    Color backgroundColor = isDarkTheme ? Color(0xFF212121) : Colors.white;
    Color textColor = isDarkTheme ? Colors.white : Colors.black;
    Color hintColor = isDarkTheme ? Colors.white54 : Colors.black54;
    Color iconColor = isDarkTheme ? Colors.white : Colors.black;
    Color dividerColor = isDarkTheme ? Colors.white54 : Colors.black54;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Expanded(
              child: Container(
                height: 40,
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                decoration: BoxDecoration(
                  color: isDarkTheme ? Color(0xFF424242) : Colors.grey[200],
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: isDarkTheme ? Colors.white54 : Colors.black54,
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.search,
                      color: iconColor,
                      size: 18,
                    ),
                    SizedBox(width: 8.0),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: InputDecoration(
                          hintText: 'Enter location...',
                          hintStyle: TextStyle(color: hintColor, fontSize: 14),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 11.0),
                        ),
                        style: TextStyle(color: textColor, fontSize: 14),
                        onChanged: (value) {
                          setState(() {
                            _isSearchActive = value.isNotEmpty;
                          });
                          if (value.isNotEmpty) {
                            _getSuggestions(value);
                          } else {
                            setState(() {
                              _suggestions = [];
                            });
                          }
                        },
                      ),
                    ),
                    if (_isSearchActive)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() {
                            _suggestions = [];
                            _isSearchActive = false;
                          });
                        },
                        child: Icon(
                          Icons.cancel,
                          color: iconColor,
                          size: 18,
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(width: 8.0),
            TextButton(
              onPressed: () {
                _searchController.clear();
                Navigator.pop(context);
              },
              child: Text(
                'Cancel',
                style: TextStyle(color: textColor),
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Divider(color: dividerColor),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator())
                : ListView.builder(
              itemCount: _suggestions.length,
              itemBuilder: (context, index) {
                var locationName = _suggestions[index]['place_name'];
                var coordinates = _suggestions[index]['geometry']['coordinates'];

                return ListTile(
                  leading: Icon(Icons.location_on, color: iconColor),
                  title: Text(
                    locationName,
                    style: TextStyle(color: textColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  onTap: () async {
                    double latitude = coordinates[1];
                    double longitude = coordinates[0];

                    // Récupérer la météo incluant température, condition et icône
                    Map<String, dynamic> weatherData = await _getWeather(latitude, longitude);

                    Navigator.pop(context, {
                      'location': locationName,
                      'temperature': weatherData['temperature'],
                      'conditionText': weatherData['conditionText'],
                      'conditionIcon': weatherData['conditionIcon'],
                      'coordinates': LatLng(latitude, longitude),
                    });
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

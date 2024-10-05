import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:weather_app/ui/connection_page.dart';
import 'package:weather_app/ui/developper_info_page.dart';
import 'package:weather_app/ui/search_page.dart';
import 'package:weather_app/ui/user_info_page.dart';
import 'package:weather_app/utils/weather_icon_example.dart';
import 'package:weather_icons/weather_icons.dart';
import 'package:http/http.dart' as http;

import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      // Thème clair
      darkTheme: ThemeData.dark(),
      // Thème sombre
      themeMode: ThemeMode.system,
      // Adapte le thème au mode système
      home: AuthChecker(),
      // Vérification de l'authentification
      debugShowCheckedModeBanner: false, // Masque le bandeau de debug
    );
  }
}

// Widget pour vérifier l'état d'authentification
class AuthChecker extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Affiche un indicateur de chargement pendant la vérification
          return Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        // Vérifiez si l'utilisateur est connecté
        if (snapshot.hasData) {
          final User user = snapshot.data!;

          // Vérification si l'utilisateur existe encore
          return FutureBuilder<User?>(
            future: _checkUserExists(user.uid),
            // Vérifiez si l'utilisateur existe
            builder: (context, futureSnapshot) {
              if (futureSnapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }

              if (futureSnapshot.hasError || futureSnapshot.data == null) {
                // L'utilisateur a été supprimé, déconnexion
                FirebaseAuth.instance.signOut();
                return LoginPage(); // Retournez à la page de connexion
              }

              // L'utilisateur existe toujours
              return MapScreen(); // Affichez la MapScreen
            },
          );
        } else {
          // Si l'utilisateur n'est pas connecté, afficher la page de connexion
          return LoginPage();
        }
      },
    );
  }

  Future<User?> _checkUserExists(String uid) async {
    try {
      // Essaye de récupérer les données de l'utilisateur pour vérifier s'il existe
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null && user.uid == uid) {
        return user;
      }
    } catch (e) {
      // Si une erreur se produit, cela peut signifier que l'utilisateur a été supprimé
      print('User not found: $e');
    }
    return null; // L'utilisateur n'existe pas
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  MapScreenState createState() => MapScreenState();
}

class MapScreenState extends State<MapScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late GoogleMapController mapController;
  final LatLng _center = const LatLng(4.0511, 9.7085); // Initial map center
  bool _isExpanded = false; // Variable to manage the bottom sheet state
  int _selectedIndex = 1; // Track the selected tab index
  bool _isBottomNavVisible =
      false; // Variable to manage BottomNavigationBar visibility
  late DraggableScrollableController
      _scrollableController; // DraggableScrollableController

  String _selectedOption = 'Temperature'; // Option par défaut

  // Variables to store location name, temperature, and weather conditions
  String _locationName = "Aucun lieu sélectionné";
  double _temperature = 0.0;
  String _conditionText = ""; // Example condition text
  final Set<Marker> _markers = {}; // Set of markers to display on the map
  Map<String, dynamic>? _forecastData;

  @override
  void initState() {
    super.initState();
    _scrollableController = DraggableScrollableController();
  }

  void _onMapCreated(GoogleMapController controller) {
    mapController = controller;
  }

  // Function to add marker to the map at the specified coordinates
  void _addMarker(LatLng position, String title) {
    final marker = Marker(
      markerId: MarkerId(position.toString()),
      position: position,
      infoWindow: InfoWindow(
        title: title,
        snippet: '$_temperature°C - $_conditionText',
      ),
    );

    setState(() {
      _markers.add(marker); // Add the marker to the set of markers
    });
  }

  Future<void> _navigateToSearchPage() async {
    _selectedIndex = 1;

    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SearchPage()),
    );

    if (result != null) {
      setState(() {
        _locationName = result['location']; // Nom de la localisation
        _temperature = result['temperature']; // Température
        _conditionText = result['conditionText'];

        LatLng coordinates = result['coordinates']; // Coordonnées du résultat
        mapController.animateCamera(
          CameraUpdate.newLatLng(
              coordinates), // Centrer la carte sur les coordonnées
        );

        // Vider les anciens marqueurs avant d'en ajouter un nouveau
        _markers.clear(); // Clear previous markers

        // Ajouter un marqueur à la nouvelle localisation
        _addMarker(coordinates, _locationName);

        // Automatiquement étendre le DraggableScrollableSheet
        _scrollableController.animateTo(
          0.4, // Étendre à la taille maximale
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
        _fetchWeatherForecast(coordinates.latitude, coordinates.longitude);
      });
    }
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;

      if (index == 0) {
        // Navigate to the user info page when index 1 is selected
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => UserInfoPage()), // Navigate to the new page
        );
      } else if (index == 2) {
        // Navigate to the developer info page when index 2 is selected
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DeveloperInfoPage()),
        );
      }
    });
  }

  // Méthode pour obtenir l'abréviation des jours de la semaine
  String _getDayAbbreviation(int weekday) {
    switch (weekday) {
      case 1:
        return 'Mon';
      case 2:
        return 'Tue';
      case 3:
        return 'Wed';
      case 4:
        return 'Thu';
      case 5:
        return 'Fri';
      case 6:
        return 'Sat';
      case 7:
        return 'Sun';
      default:
        return '';
    }
  }

// Fonction pour faire la requête
  Future<void> _fetchWeatherForecast(double latitude, double longitude) async {
    const String weatherAPIApiKey = '6a5fdf1096094ee3812233148240310';
    final String url =
        'http://api.weatherapi.com/v1/forecast.json?key=$weatherAPIApiKey&q=$latitude,$longitude&days=5&aqi=no&alerts=no';

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        setState(() {
          _forecastData = json.decode(response.body); // Stocker la réponse JSON
        });
      } else {
        throw Exception('Failed to load forecast');
      }
    } catch (e) {}
  }

  @override
  void dispose() {
    _scrollableController.dispose(); // Libération du contrôleur
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLightTheme = Theme.of(context).brightness == Brightness.light;

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            onMapCreated: _onMapCreated,
            zoomControlsEnabled: false,
            initialCameraPosition: CameraPosition(
              target: _center,
              zoom: 11.0,
            ),
            markers: _markers, // Add markers to the map
          ),
          // Zoom in/out controls
          Positioned(
            top: MediaQuery.of(context).size.height * 0.75,
            right: 10,
            child: Column(
              children: [
                SizedBox(
                  width: 40,
                  height: 40,
                  child: FloatingActionButton(
                    onPressed: () {
                      mapController.animateCamera(CameraUpdate.zoomIn());
                    },
                    backgroundColor: isLightTheme
                        ? Colors.white
                        : Colors.grey[800] ?? Colors.grey,
                    child: Icon(Icons.add,
                        size: 20,
                        color: isLightTheme ? Colors.black : Colors.white),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: 40,
                  height: 40,
                  child: FloatingActionButton(
                    onPressed: () {
                      mapController.animateCamera(CameraUpdate.zoomOut());
                    },
                    backgroundColor: isLightTheme
                        ? Colors.white
                        : Colors.grey[800] ?? Colors.grey,
                    child: Icon(Icons.remove,
                        size: 20,
                        color: isLightTheme ? Colors.black : Colors.white),
                  ),
                ),
              ],
            ),
          ),
          // Draggable bottom sheet
          DraggableScrollableSheet(
            initialChildSize: 0.1,
            minChildSize: 0.1,
            maxChildSize: 0.7,
            controller: _scrollableController,
            builder: (BuildContext context, ScrollController scrollController) {
              return Container(
                decoration: BoxDecoration(
                  color: isLightTheme
                      ? Colors.white.withOpacity(0.9)
                      : Colors.grey[850]!.withOpacity(0.9),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: NotificationListener<DraggableScrollableNotification>(
                  onNotification: (notification) {
                    setState(() {
                      _isBottomNavVisible = notification.extent > 0.1;
                      _isExpanded = notification.extent != 0.7;
                    });
                    return true;
                  },
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: Column(
                      children: [
                        if (_isExpanded)
                          GestureDetector(
                            onTap: () {
                              setState(() {
                                _isExpanded = !_isExpanded;
                              });
                            },
                            child: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Container(
                                alignment: Alignment.center,
                                child: Icon(
                                  Icons.drag_handle,
                                  color: isLightTheme
                                      ? Colors.black
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Text(
                                _locationName,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.normal,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    '${_temperature.toStringAsFixed(1)} °C',
                                    style: const TextStyle(
                                      fontSize: 50,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  WeatherIconExample(
                                      conditionText: _conditionText),
                                ],
                              ),
                              const SizedBox(height: 5),
                              Text(
                                _conditionText,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontStyle: FontStyle.italic,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(left: 20.0),
                              child: Text(
                                "Daily",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                  color: isLightTheme
                                      ? Colors.black87
                                      : Colors.white70,
                                ),
                              ),
                            ),
                            DropdownButton<String>(
                              value: _selectedOption,
                              items: const [
                                DropdownMenuItem(
                                  value: 'Temperature',
                                  child: Row(
                                    children: [
                                      Icon(WeatherIcons.thermometer),
                                      SizedBox(width: 8),
                                      Text('Temperature'),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'Wind speed',
                                  child: Row(
                                    children: [
                                      Icon(WeatherIcons.strong_wind),
                                      SizedBox(width: 8),
                                      Text('Wind speed'),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'Humidity',
                                  child: Row(
                                    children: [
                                      Icon(WeatherIcons.humidity),
                                      SizedBox(width: 8),
                                      Text('Humidity'),
                                    ],
                                  ),
                                ),
                                DropdownMenuItem(
                                  value: 'Precipitation',
                                  child: Row(
                                    children: [
                                      Icon(WeatherIcons.rain),
                                      SizedBox(width: 8),
                                      Text('Precipitation'),
                                    ],
                                  ),
                                ),
                              ],
                              dropdownColor: isLightTheme
                                  ? Colors.white
                                  : Colors.grey[800],
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedOption = newValue ?? 'Temperature';
                                });
                              },
                              selectedItemBuilder: (BuildContext context) {
                                return [
                                  const Row(
                                    children: [
                                      Icon(WeatherIcons.thermometer),
                                      SizedBox(width: 8),
                                      Text('Temperature'),
                                    ],
                                  ),
                                  const Row(
                                    children: [
                                      Icon(WeatherIcons.strong_wind),
                                      SizedBox(width: 8),
                                      Text('Wind speed'),
                                    ],
                                  ),
                                  const Row(
                                    children: [
                                      Icon(WeatherIcons.humidity),
                                      SizedBox(width: 8),
                                      Text('Humidity'),
                                    ],
                                  ),
                                  const Row(
                                    children: [
                                      Icon(WeatherIcons.rain),
                                      SizedBox(width: 8),
                                      Text('Precipitations'),
                                    ],
                                  ),
                                ];
                              },
                              underline: const SizedBox.shrink(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: _forecastData == null ||
                                    _forecastData?['forecast'] == null ||
                                    _forecastData?['forecast']['forecastday'] ==
                                        null
                                ? [
                                    Padding(
                                      padding: const EdgeInsets.all(16.0),
                                      child: Text(
                                        "No availabe data",
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: isLightTheme
                                              ? Colors.black
                                              : Colors.white,
                                        ),
                                      ),
                                    ),
                                  ]
                                : List.generate(
                                    _forecastData?['forecast']['forecastday']
                                        .length,
                                    (index) {
                                      final dayData = _forecastData?['forecast']
                                          ['forecastday'][index];

                                      // Convertir la date string en DateTime
                                      final day =
                                          DateTime.parse(dayData["date"]);

                                      return Column(
                                        children: [
                                          ListTile(
                                            title: Row(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.start,
                                              children: [
                                                SizedBox(
                                                  width: 45,
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                      Text(
                                                        index == 0
                                                            ? "Today"
                                                            : _getDayAbbreviation(
                                                                day.weekday),
                                                        style: const TextStyle(
                                                          fontSize: 14,
                                                        ),
                                                      ),
                                                      Text(
                                                        '${day.day}',
                                                        style: const TextStyle(
                                                          fontSize: 12,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                const SizedBox(width: 5),
                                                // Réduire l'espacement
                                                Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  // Centre verticalement tout le contenu de la colonne
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.center,
                                                  // Centre horizontalement tout le contenu de la colonne
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      // Centre les icônes horizontalement
                                                      children: [
                                                        Column(
                                                          children: [
                                                            SizedBox(
                                                              width: 50,
                                                              // Largeur fixe pour l'icône
                                                              child:
                                                                  WeatherIconExample(
                                                                conditionText:
                                                                    dayData['day']
                                                                            [
                                                                            'condition']
                                                                        [
                                                                        'text'],
                                                              ),
                                                            ),
                                                            const SizedBox(
                                                                height: 5),
                                                            // Espacement entre l'icône et le texte
                                                            SizedBox(
                                                              width: 150,
                                                              // Largeur fixe pour le texte
                                                              child: Text(
                                                                dayData['day'][
                                                                        'condition']
                                                                    ['text'],
                                                                textAlign:
                                                                    TextAlign
                                                                        .center,
                                                                // Centre le texte
                                                                style:
                                                                    const TextStyle(
                                                                  fontSize:
                                                                      13, // Réduction de la taille du texte
                                                                ),
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                // Affiche des points de suspension si le texte déborde
                                                                maxLines:
                                                                    1, // Limite le texte à une seule ligne
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),

                                                const Spacer(),
                                                // Afficher les températures min et max
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.end,
                                                  children: [
                                                    if (_selectedOption ==
                                                        'Temperature') ...[
                                                      // Affichage des températures min et max
                                                      Container(
                                                        constraints:
                                                            const BoxConstraints(
                                                                maxWidth: 200),
                                                        // Set a max width to constrain the text
                                                        child: Text(
                                                          '${dayData['day']['mintemp_c']}/${dayData['day']['maxtemp_c']} °C',
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 14,
                                                          ),
                                                          textAlign:
                                                              TextAlign.end,
                                                          overflow: TextOverflow
                                                              .ellipsis, // Add ellipsis if overflow occurs
                                                        ),
                                                      ),
                                                    ] else if (_selectedOption ==
                                                        'Wind speed') ...[
                                                      // Affichage de la vitesse moyenne du vent
                                                      Container(
                                                        constraints:
                                                            const BoxConstraints(
                                                                maxWidth: 200),
                                                        child: Text(
                                                          'Wind: ${dayData['day']['maxwind_kph']} km/h',
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 12,
                                                          ),
                                                          textAlign:
                                                              TextAlign.end,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ] else if (_selectedOption ==
                                                        'Humidity') ...[
                                                      // Affichage de l'humidité moyenne
                                                      Container(
                                                        constraints:
                                                            const BoxConstraints(
                                                                maxWidth: 200),
                                                        child: Text(
                                                          'Humidity: ${dayData['day']['avghumidity']} %',
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 12,
                                                          ),
                                                          textAlign:
                                                              TextAlign.end,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ] else if (_selectedOption ==
                                                        'Precipitation') ...[
                                                      // Affichage des précipitations totales
                                                      Container(
                                                        constraints:
                                                            const BoxConstraints(
                                                                maxWidth: 200),
                                                        child: Text(
                                                          'Précip: ${dayData['day']['totalprecip_mm']} mm',
                                                          style:
                                                              const TextStyle(
                                                            fontSize: 12,
                                                          ),
                                                          textAlign:
                                                              TextAlign.end,
                                                          overflow: TextOverflow
                                                              .ellipsis,
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          const Divider(),
                                          // Ligne de séparation entre chaque jour
                                        ],
                                      );
                                    },
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          // Search button
          Positioned(
            top: 60,
            right: 10,
            child: SizedBox(
              width: 40,
              height: 40,
              child: FloatingActionButton(
                onPressed: _navigateToSearchPage,
                backgroundColor: isLightTheme
                    ? Colors.white
                    : Colors.grey[800] ?? Colors.grey,
                child: Icon(Icons.search,
                    color: isLightTheme ? Colors.black : Colors.white),
              ),
            ),
          ),
        ],
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: _isBottomNavVisible
          ? BottomNavigationBar(
              backgroundColor: isLightTheme
                  ? Colors.white
                  : Colors.grey[850]!.withOpacity(0.9),
              items: const <BottomNavigationBarItem>[
                BottomNavigationBarItem(
                  icon: Icon(Icons.settings),
                  label: 'Settings',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.map),
                  label: 'Map',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.info),
                  label: 'Info',
                ),
              ],
              currentIndex: _selectedIndex,
              selectedItemColor: Colors.blue,
              onTap: _onItemTapped,
            )
          : null,
    );
  }
}

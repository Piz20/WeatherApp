import 'package:climate_virtualization/ui/SearchPage.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.light(),
      darkTheme: ThemeData.dark(),
      themeMode: ThemeMode.system,
      home: const MapScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  late GoogleMapController mapController;
  LatLng _center = const LatLng(4.0511, 9.7085); // Initial map center
  bool _isExpanded = false; // Variable to manage the bottom sheet state
  int _selectedIndex = 0; // Track the selected tab index
  bool _isBottomNavVisible = false; // Variable to manage BottomNavigationBar visibility
  late DraggableScrollableController _scrollableController; // DraggableScrollableController

  // Variables to store location name, temperature, and weather conditions
  String _locationName = "Aucun lieu sélectionné";
  double _temperature = 0.0;
  String _conditionText = ""; // Example condition text
  Set<Marker> _markers = {}; // Set of markers to display on the map

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

  // Navigation to the search page, expand DraggableScrollableSheet upon return
  Future<void> _navigateToSearchPage() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => SearchPage()),
    );

    if (result != null) {
      setState(() {
        _locationName = result['location']; // Location name
        _temperature = result['temperature']; // Temperature
        _conditionText = result['conditionText'];

        LatLng coordinates = result['coordinates']; // Coordinates from result
        mapController.animateCamera(
          CameraUpdate.newLatLng(coordinates), // Center the map to the coordinates
        );

        // Automatically expand the DraggableScrollableSheet
        _scrollableController.animateTo(
          0.4, // Expand to the maximum size
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );

        // Add a marker at the selected location
        _addMarker(coordinates, _locationName);
      });
    }
  }

  // Handle navigation item taps
  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    // Add logic for different navigation items (Map, Info, Settings)
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
                    backgroundColor: isLightTheme ? Colors.white : Colors.grey[800] ?? Colors.grey,
                    child: Icon(Icons.add, size: 20, color: isLightTheme ? Colors.black : Colors.white),
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
                    backgroundColor: isLightTheme ? Colors.white : Colors.grey[800] ?? Colors.grey,
                    child: Icon(Icons.remove, size: 20, color: isLightTheme ? Colors.black : Colors.white),
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
                  child: ListView(
                    controller: scrollController,
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
                                color: isLightTheme ? Colors.black : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center, // Center the content
                          children: [
                            Text(
                              _locationName,
                              style: const TextStyle(
                                fontSize: 18, // Smaller font size for the location name
                                fontWeight: FontWeight.normal,
                              ),
                            ),
                            const SizedBox(height: 10), // Small space between location and temperature
                            Text(
                              '${_temperature.toStringAsFixed(1)} °C',
                              style: const TextStyle(
                                fontSize: 50, // Larger font size for the temperature
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center, // Center the temperature
                            ),
                            const SizedBox(height: 5), // Small space between temperature and conditions
                            Text(
                              _conditionText, // Weather condition text
                              style: const TextStyle(
                                fontSize: 16, // Smaller font size for the condition text
                                fontStyle: FontStyle.italic,
                              ),
                              textAlign: TextAlign.center, // Center the condition text
                            ),
                          ],
                        ),
                      ),
                    ],
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
                backgroundColor: isLightTheme ? Colors.white : Colors.grey[800] ?? Colors.grey,
                child: Icon(Icons.search, color: isLightTheme ? Colors.black : Colors.white),
              ),
            ),
          ),
        ],
      ),
      // Bottom Navigation Bar
      bottomNavigationBar: _isBottomNavVisible
          ? BottomNavigationBar(
        backgroundColor: isLightTheme ? Colors.white : Colors.grey[800] ?? Colors.grey,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info),
            label: 'Info',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: isLightTheme ? Colors.black : Colors.white,
        unselectedItemColor: isLightTheme ? Colors.grey[600] : Colors.grey[400],
        onTap: _onItemTapped,
      )
          : null,
    );
  }
}

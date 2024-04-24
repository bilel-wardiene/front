import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:front/constants/strings.dart';
import 'package:front/features/Reservation/data/models/itinerary_model.dart';
import 'package:front/features/Reservation/data/repositories/itinerary_repository.dart';
import 'package:front/features/Reservation/reservation_bloc/itinerary_bloc.dart';
import 'package:front/features/auth/data/user_model.dart';
import 'package:front/features/reservationBloc/ReservationBloc.dart';
import 'package:front/features/reservationBloc/ReservationEvent.dart';
import 'package:front/features/reservationBloc/data/models/ReservationModel.dart';
import 'package:intl/intl.dart';
import 'package:time_picker_spinner/time_picker_spinner.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlong;
import 'package:mapbox_gl/mapbox_gl.dart';
import 'package:flutter_dropdown/flutter_dropdown.dart';

import '../data/user_model.dart';

class Home extends StatefulWidget {
  const Home({Key? key});

  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> with SingleTickerProviderStateMixin {
  final ItineraryRepository itineraryRepository = ItineraryRepository();
  late final ItineraryBloc itineraryBloc;
  bool _isContainerVisible = false;
  final _formKey = GlobalKey<FormState>();
  DateTime? _selectedDate;
  DateTime? _selectedDateTime;
  String? _selectedToStation;
  List<String> _busOptions = [];
  String? _selectedBus;

  List<String> _itineraryOptions = [];

  String? _selectedItinerary;

  List<String> _markerOptions = [];
  List<String>? _selectedMarkers = [];

  void _toggleContainerVisibility() {
    setState(() {
      _isContainerVisible = !_isContainerVisible;
    });
  }

  List<ItineraryModel> itineraries = [
    ItineraryModel(
      name: 'Itinerary 1',
      stations: [
        MarkerModel(
          name: 'Station 1',
          description: 'Description 1',
          latitude: 36.69669142121775,
          longitude: 9.835583245180743,
        ),
        MarkerModel(
          name: 'Station 2',
          description: 'Description 2',
          latitude: 36.70223366538448,
          longitude: 9.840913978179202,
        ),
        MarkerModel(
          name: 'Station 3',
          description: 'Description 3',
          latitude: 36.71764712362926,
          longitude: 9.848389330980098,
        ),
        // Add more stations as needed
      ],
    ),
    // Add more itineraries as needed
  ];

  Dio dio = Dio();

  late User? userModel = User();

  @override
  void initState() {
    super.initState();

    fetchBusOptions();
    fetchItineraryOptions();
    fetchMarkerOptions();
    itineraryBloc = ItineraryBloc(itineraryRepository);
    itineraryBloc.getAllItineraries();
    // fetchItineraries();
  }

  @override
  void dispose() {
    itineraryBloc.close();
    super.dispose();
  }

  void _handleReservation() {
    if (_selectedDateTime == null ||
        _selectedBus == null ||
        _selectedItinerary == null ||
        _selectedMarkers == null) {
      // Show an error message if any of the required fields are not selected
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text(
              'Please select all required fields before making a reservation.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    } else {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Reservation Successful'),
          content: Text('Your reservation has been made successfully.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  String getEmployeeId() {
    return '648a1220d3a01e591dff490a';
  }

  

  Future<List<LatLng>> getRouteCoordinates(List<MarkerModel> stations) async {
    List<LatLng> coordinates = [];

    for (int i = 0; i < stations.length - 1; i++) {
      MarkerModel origin = stations[i];
      MarkerModel destination = stations[i + 1];

      final response = await dio.get(
        'https://api.mapbox.com/directions/v5/mapbox/driving/${origin.longitude},${origin.latitude};${destination.longitude},${destination.latitude}',
        queryParameters: {
          'access_token':
              'sk.eyJ1IjoiYmlsZWwtMDIiLCJhIjoiY2xseG5kbnFiMGU3aTNycDNuZnBzb2c4ayJ9.tFU84RyIJyfsrx1bVt8UZA',
          'steps': 'true', // Include detailed steps in the response
          'geometries': 'polyline', // Request polyline geometry
          'alternatives': 'true',
          'overview': 'full'
        },
      );

      final routes = response.data['routes'];
      if (routes.isNotEmpty) {
        final route = routes[0];
        final geometry = route['geometry'];

        // Decode the polyline geometry
        List<LatLng> routeCoordinates = decodeEncodedPolyline(geometry);

        coordinates.addAll(routeCoordinates);
      }
    }

    return coordinates;
  }

  List<LatLng> decodeEncodedPolyline(String encodedPolyline) {
    List<LatLng> polyPoints = decodeEncodedPolyline(encodedPolyline);

    return polyPoints;
  }

  Marker createStationMarker(MarkerModel station, String itineraryName) {
    return Marker(
      width: 80.0,
      height: 80.0,
      point: latlong.LatLng(station.latitude, station.longitude),
      builder: (ctx) => GestureDetector(
        onTap: () {
          showDialog(
            context: ctx,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text(itineraryName),
                content: Text('${station.name}: ${station.description}'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Close'),
                  ),
                ],
              );
            },
          );
        },
        child: Icon(
          Icons.location_on,
          color: Colors.red,
          size: 40.0,
        ),
      ),
    );
  }

  Future<void> fetchBusOptions() async {
    try {
      final response = await dio.get('$baseUrl/bus/getAllBus');
      final List<dynamic> busOptions = List<dynamic>.from(response.data);
      final List<String> formattedBusOptions =
          busOptions.map((option) => option['name'].toString()).toList();
      setState(() {
        _busOptions = formattedBusOptions;
      });
    } catch (error) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Failed to fetch bus options: $error'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> fetchItineraryOptions() async {
    try {
      final response = await dio.get('$baseUrl/itinerary/getAllItinerary');
      final List<dynamic> itineraryOptions = List<dynamic>.from(response.data);
      final List<String> formattedItineraryOptions =
          itineraryOptions.map((option) => option['name'].toString()).toList();
      setState(() {
        _itineraryOptions = formattedItineraryOptions;
      });
    } catch (error) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Failed to fetch itinerary options: $error'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  Future<void> fetchMarkerOptions() async {
    try {
      final response = await dio.get('$baseUrl/marker/getAllMarker');
      final List<dynamic> markerOptions = List<dynamic>.from(response.data);
      final List<String> formattedMarkerOptions =
          markerOptions.map((option) => option['name'].toString()).toList();
      setState(() {
        _markerOptions = formattedMarkerOptions;
      });
    } catch (error) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Error'),
          content: Text('Failed to fetch marker options: $error'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              center: latlong.LatLng(
                36.86821934095694,
                10.165226976479506,
              ),
              zoom: 15.0,
            ),
            children: [
              TileLayer(
                urlTemplate:
                    'https://api.mapbox.com/styles/v1/bilel-02/clesrzfu6006p01s5fgkqbk9c/tiles/256/{z}/{x}/{y}@2x?access_token=pk.eyJ1IjoiYmlsZWwtMDIiLCJhIjoiY2xlc2dsODF0MHduZzN5cDFna3UyMm9tMyJ9.lQXHWjkWEzBchhit1O4CWw',
                additionalOptions: {
                  'accessToken':
                      'sk.eyJ1IjoiYmlsZWwtMDIiLCJhIjoiY2xseG5kbnFiMGU3aTNycDNuZnBzb2c4ayJ9.tFU84RyIJyfsrx1bVt8UZA',
                  'id': 'mapbox.country-boundaries-v1',
                },
              ),
              PolylineLayer(
                polylines: [
                  for (var itinerary in itineraries)
                    Polyline(
                      points: [
                        // Add your list of LatLng points here representing the car's route
                        latlong.LatLng(36.69669142121775, 9.835583245180743),
                        latlong.LatLng(36.697633006320174, 9.837202686112818),
                        latlong.LatLng(36.69859736125025, 9.838841070776141),
                        latlong.LatLng(36.69959207677179, 9.840545745511292),
                        latlong.LatLng(36.69988061738313, 9.8411802633035),
                        latlong.LatLng(36.70025942902575, 9.842177250028783),
                        latlong.LatLng(36.701393433851564, 9.84084835267987),
                        latlong.LatLng(36.70159398183486, 9.841383191480702),
                        latlong.LatLng(36.70203322623513, 9.8408627316376),
                        latlong.LatLng(36.70214985470655, 9.84085526712579),
                        latlong.LatLng(36.70223366538448, 9.840913978179202),
                        latlong.LatLng(36.702475761987515, 9.840677625861133),
                        latlong.LatLng(36.70291869293136, 9.840133082121241),
                        latlong.LatLng(36.7030440662071, 9.840105408479815),
                        latlong.LatLng(36.70324911733174, 9.840382931743022),
                        latlong.LatLng(36.70525603428051, 9.837867576437674),
                        latlong.LatLng(36.70980701135912, 9.843206167113209),
                        latlong.LatLng(36.71117135352243, 9.844708185750278),
                        latlong.LatLng(36.71594993296111, 9.847413200593195),
                        latlong.LatLng(36.71764712362926, 9.848389330980098),

                        
                        // Add more points as needed
                      ],
                      color: Colors.blue,
                      strokeWidth: 4.0,
                    ),
                ],
              ),
              MarkerLayer(
                markers: [
                  for (var itinerary in itineraries)
                    for (var station in itinerary.stations)
                      createStationMarker(station, itinerary.name),
                ],
              ),
            ],
          ),
          if (_isContainerVisible) // Render the container only when visible
            Align(
              alignment: Alignment.bottomCenter,
              child: AnimatedContainer(
                key: _formKey,
                duration: Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                height: MediaQuery.of(context).size.height / 4,
                decoration: BoxDecoration(
                  color: const Color(0xff192028),
                  boxShadow: const [
                    BoxShadow(
                      color: Color.fromARGB(255, 11, 11, 22),
                      spreadRadius: 1,
                      blurRadius: 15,
                      offset: Offset(5, 5),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextButton(
                            onPressed: () async {
                              await _selectDateTime(context);
                            },
                            child: Text(
                              _selectedDateTime != null
                                  ? '${DateFormat('yyyy-MM-ddTHH:mm').format(_selectedDateTime!)}'
                                  : 'Select Date and Time',
                              style: TextStyle(
                                fontSize: 17,
                                color: Colors
                                    .blue, // Customize the color as needed
                              ),
                            ),
                          ),
                          SizedBox(
                            height: 10.0,
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width / 4,
                            child: DropdownButtonFormField<String>(
                              value: _selectedBus,
                              items: _busOptions.map((String bus) {
                                return DropdownMenuItem<String>(
                                  value: bus,
                                  child: Text(bus),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedBus = newValue;
                                });
                              },
                              decoration: InputDecoration(labelText: 'Bus'),
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select a bus';
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(
                            height: 10.0,
                          ),
                          Container(
                            width: MediaQuery.of(context).size.width / 4,
                            child: DropdownButtonFormField<String>(
                              value: _selectedItinerary,
                              items: _itineraryOptions.map((String itinerary) {
                                return DropdownMenuItem<String>(
                                  value: itinerary,
                                  child: Text(itinerary),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedItinerary = newValue;
                                });
                              },
                              decoration:
                                  InputDecoration(labelText: 'Itinerary'),
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select an itinerary';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      Column(
                        mainAxisAlignment: MainAxisAlignment.start,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: MediaQuery.of(context).size.width / 4,
                            child: DropdownButtonFormField<String>(
                              value: _selectedMarkers?.isNotEmpty ?? false
                                  ? _selectedMarkers![0]
                                  : null,
                              items: _markerOptions.map((String marker) {
                                return DropdownMenuItem<String>(
                                  value: marker,
                                  child: Text(marker),
                                );
                              }).toList(),
                              onChanged: (String? newValue) {
                                setState(() {
                                  _selectedMarkers =
                                      newValue != null ? [newValue] : null;
                                });
                              },
                              decoration: InputDecoration(labelText: 'Marker'),
                              validator: (value) {
                                if (value == null) {
                                  return 'Please select a marker';
                                }
                                return null;
                              },
                            ),
                          ),
                          SizedBox(
                            height: 10,
                          ),
                          ElevatedButton(
                            onPressed: () {
                              _handleReservation();
                            },
                            child: Text('Make Reservation'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              child: TableCalendar(
                focusedDay: DateTime.now(),
                firstDay: DateTime.utc(2023, 1, 1),
                lastDay: DateTime.utc(2040, 12, 31),
                calendarFormat: CalendarFormat.week,
                calendarStyle: CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.deepPurple,
                    shape: BoxShape.circle,
                  ),
                  selectedDecoration: BoxDecoration(
                    color: Theme.of(context).primaryColor,
                    shape: BoxShape.circle,
                  ),
                  todayTextStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.0,
                    color: Colors.white,
                  ),
                ),
                headerStyle: HeaderStyle(
                  titleCentered: true, // Center align the header title
                  formatButtonVisible: false,
                ),
                startingDayOfWeek: StartingDayOfWeek.sunday,
                calendarBuilders: CalendarBuilders(
                  selectedBuilder: (context, date, _) => Container(
                    margin: const EdgeInsets.fromLTRB(4.0, 0, 4.0, 0),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Theme.of(context).primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      date.day.toString(),
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                  todayBuilder: (context, date, _) => Container(
                    margin: const EdgeInsets.fromLTRB(4.0, 0, 4.0, 0),
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: Colors.deepPurple,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      date.day.toString(),
                      style: TextStyle(
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: FloatingActionButton(
                onPressed: _toggleContainerVisibility,
                backgroundColor: Color(0xff192028),
                child: Icon(Icons.add) ,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.utc(2023, 1, 1),
      lastDate: DateTime.utc(2040, 12, 31),
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectDateTime(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDateTime ?? DateTime.now(),
      firstDate: DateTime.utc(2023, 1, 1),
      lastDate: DateTime.utc(2040, 12, 31),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: Text('Select Time'),
            content: TimePickerSpinner(
              is24HourMode: true,
              spacing: 30,
              itemHeight: 40,
              time: _selectedDateTime ?? DateTime.now(),
              onTimeChange: (time) {
                setState(() {
                  _selectedDateTime = DateTime(
                    pickedDate.year,
                    pickedDate.month,
                    pickedDate.day,
                    time.hour,
                    time.minute,
                  );
                });
              },
            ),
            actions: <Widget>[
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text('OK'),
              ),
            ],
          );
        },
      );

      if (pickedTime != null) {
        setState(() {
          _selectedDateTime = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      }
    }
  }
}

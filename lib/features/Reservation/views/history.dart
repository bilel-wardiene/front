
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: CalendarPage(),
    );
  }
}

class CalendarPage extends StatefulWidget {
  @override
  _CalendarPageState createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  CalendarFormat _calendarFormat = CalendarFormat.month;
  DateTime _focusedDay = DateTime.now();
  dynamic _selectedEvent;
  DateTime? _selectedDay;
  Map<DateTime, List<dynamic>> _events = {};
  bool _isLoading = true; // Set initial loading state to true
  Color _reservedDayColor = Colors.green;
  bool _isDayReserved = false; // Track if the day is reserved

  TextEditingController _newDateController = TextEditingController();

  @override
  void initState() {
    super.initState();
    fetchReservations();
  }

  Future<void> fetchReservations() async {
    // Simulating API call delay
    await Future.delayed(Duration(seconds: 2));

    // Add your static reservation data here
    final staticReservationDate = DateTime(2023, 8, 17);
    final staticReservationDetails = {
      'Time': '17/08/2023',
      'Time': '24/08/2023',

      // Add more reservation details as needed
    };

    _events[staticReservationDate] = [staticReservationDetails];

    setState(() {
      _isLoading = false; // Set loading state to false after data is fetched
      _selectedDay = staticReservationDate;
      _selectedEvent = staticReservationDetails;
      _isDayReserved = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Color(0xff192028),
        child: _isLoading
            ? Center(child: CircularProgressIndicator())
            : TableCalendar(
                firstDay: DateTime.utc(2020, 10, 16),
                lastDay: DateTime.utc(2060, 3, 14),
                focusedDay: _focusedDay,
                calendarFormat: _calendarFormat,
                selectedDayPredicate: (day) {
                  return isSameDay(_selectedDay, day);
                },
                eventLoader: (day) {
                  return _events[day] ?? [];
                },
                calendarStyle: CalendarStyle(
                  selectedDecoration: BoxDecoration(
                    color:
                        _isDayReserved ? _reservedDayColor : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  selectedTextStyle: TextStyle(color: Colors.white),
                ),
                onDaySelected: (selectedDay, focusedDay) {
                  setState(() {
                    _selectedDay = selectedDay;
                    _focusedDay = focusedDay;
                    _selectedEvent = _events[selectedDay]?.first;
                    _isDayReserved = _selectedEvent != null;
                  });

                  if (_selectedEvent != null) {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Update Reservation Time'),
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Enter new time:'),
                            TextField(
                              controller: _newDateController,
                              keyboardType: TextInputType.text,
                            ),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () {
                              // Get the new time from the TextField
                              String newTime = _newDateController.text;

                              // Show the updated time message
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Updated time at $newTime'),
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

                              // Dismiss the dialog
                              _newDateController.clear();
                              Navigator.pop(context);
                            },
                            child: Text('OK'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text('Cancel'),
                          ),
                        ],
                      ),
                    );
                  } else {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: Text('Reservation Details'),
                        content: Text('Reserved at 06:00'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              // Handle update action
                              showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  title: Text('Update Reservation'),
                                  content: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text('Enter new time:'),
                                      TextField(
                                        controller: _newDateController,
                                        keyboardType: TextInputType.datetime,
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        // Get the new date from the TextField
                                        DateTime newDate = DateTime.parse(
                                            _newDateController.text);

                                        // Update the events map with the new date
                                        _events.remove(_selectedDay);
                                        _events[newDate] = [_selectedEvent];

                                        // Update the selected day and event
                                        _selectedDay = newDate;
                                        _selectedEvent =
                                            _events[newDate]?.first;

                                        // Clear the new date controller and dismiss the dialog
                                        _newDateController.clear();
                                        Navigator.pop(context);
                                        setState(() {}); // Update the UI
                                      },
                                      child: Text('OK'),
                                    ),
                                    TextButton(
                                      onPressed: () {
                                        Navigator.pop(context);
                                      },
                                      child: Text('Cancel'),
                                    ),
                                  ],
                                ),
                              );
                            },
                            child: Text(
                              'Update',
                              style: TextStyle(
                                color: Colors.green, // Set the color to red
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              // Handle delete action
                              _events.remove(_selectedDay);
                              _isDayReserved = false;
                              Navigator.pop(context);
                              setState(() {}); // Update the UI
                            },
                            child: Text(
                              'Delete',
                              style: TextStyle(
                                color: Colors.red, // Set the color to red
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            child: Text('Close'),
                          ),
                        ],
                      ),
                    );
                  }
                },
                onFormatChanged: (format) {
                  setState(() {
                    _calendarFormat = format;
                  });
                },
                onPageChanged: (focusedDay) {
                  _focusedDay = focusedDay;
                },
              ),
      ),
    );
  }
}

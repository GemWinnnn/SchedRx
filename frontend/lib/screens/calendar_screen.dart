import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// TODO: Import your backend API client here

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  // TODO: Replace with backend API call to fetch medicines
  // Example: final medicines = await BackendApi.getMedicines();
  List<dynamic> medicines = [];
  DateTime _selectedDate = DateTime.now();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Center today's date after the first frame is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToDate(DateTime.now());
    });
    // TODO: Fetch medicines from backend here
  }

  void _scrollToDate(DateTime date) {
    final today = DateTime.now();
    final dates = List.generate(30, (index) {
      return DateTime(today.year, today.month, today.day - 15 + index);
    });

    // Find the index of the date
    final selectedIndex = dates.indexWhere(
      (d) => d.year == date.year && d.month == date.month && d.day == date.day,
    );

    if (selectedIndex != -1) {
      final itemWidth = 96.0; // 80 (width) + 16 (margin)
      final screenWidth = MediaQuery.of(context).size.width;

      // Calculate the target offset to center the date
      final targetOffset =
          (selectedIndex * itemWidth) - (screenWidth / 2) + (itemWidth / 2);

      if (_scrollController.hasClients) {
        final maxScroll = _scrollController.position.maxScrollExtent;
        final minScroll = _scrollController.position.minScrollExtent;
        final clampedOffset = targetOffset.clamp(minScroll, maxScroll);

        _scrollController.animateTo(
          clampedOffset,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _onDateSelected(DateTime date) {
    setState(() {
      _selectedDate = DateTime(date.year, date.month, date.day);
    });
    _scrollToDate(date);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _getAppBarTitle() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final selectedDateStart = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
    );

    if (selectedDateStart.isAtSameMomentAs(startOfDay)) {
      return "Today, ${DateFormat('MMMM d').format(_selectedDate)}";
    } else {
      return DateFormat('EEEE, MMMM d').format(_selectedDate);
    }
  }

  Color _getDateBackgroundColor(
    DateTime date,
    bool isSelected,
    List<dynamic> medicines,
  ) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);
    final dateKey = DateFormat('yyyy-MM-dd').format(dateToCheck);

    print('Checking date: $dateKey');
    print('Total medicines: ${medicines.length}');

    // Compare dates without time component
    if (dateToCheck.isAfter(startOfDay)) {
      // Future date
      return Colors.grey[200]!;
    } else if (dateToCheck.isAtSameMomentAs(startOfDay)) {
      // Today
      return Colors.transparent;
    } else {
      // Past date
      final medicinesForDate = medicines.where((med) {
        final medStart = DateTime(
          med['startDate']['year'],
          med['startDate']['month'],
          med['startDate']['day'],
        );
        final medEnd = DateTime(
          med['endDate']['year'],
          med['endDate']['month'],
          med['endDate']['day'],
        );
        final isInRange =
            dateToCheck.isAfter(medStart.subtract(const Duration(days: 1))) &&
            dateToCheck.isBefore(medEnd.add(const Duration(days: 1)));

        print('Medicine: ${med['name']}');
        print('Start: ${medStart.toString()}');
        print('End: ${medEnd.toString()}');
        print('Is in range: $isInRange');
        print('Taken dates: ${med['takenDates']}');

        return isInRange;
      }).toList();

      print('Medicines for date: ${medicinesForDate.length}');

      if (medicinesForDate.isEmpty) {
        print('No medicines for date, using light blue');
        return Colors.blue.withOpacity(0.1);
      }

      final allMedicinesTaken = medicinesForDate.every((med) {
        final isTaken = med['takenDates'].contains(dateKey);
        print('Medicine ${med['name']} taken: $isTaken');
        return isTaken;
      });

      print('All medicines taken: $allMedicinesTaken');

      return allMedicinesTaken
          ? Colors.blue.withOpacity(
              0.8,
            ) // Bright blue when all medicines are taken
          : Colors.blue.withOpacity(
              0.1,
            ); // Light blue when not all medicines are taken
    }
  }

  BoxBorder? _getDateBorder(DateTime date) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final dateToCheck = DateTime(date.year, date.month, date.day);

    if (dateToCheck.isAtSameMomentAs(startOfDay)) {
      return Border.all(color: Colors.blue, width: 2);
    }
    return null;
  }

  Widget _buildDateItem(
    DateTime date,
    bool isSelected,
    List<dynamic> medicines,
  ) {
    final dayOfMonth = date.day.toString();
    final isToday = date.isAtSameMomentAs(DateTime.now());
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final isFutureDate = date.isAfter(startOfDay);

    return GestureDetector(
      onTap: () => _onDateSelected(date),
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: _getDateBackgroundColor(date, isSelected, medicines),
          borderRadius: BorderRadius.circular(5),
          border: _getDateBorder(date),
        ),
        child: Center(
          child: Text(
            dayOfMonth,
            style: TextStyle(
              color: isFutureDate ? Colors.grey[600] : Colors.black87,
              fontSize: 16,
              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDateScrollBar() {
    final today = DateTime.now();
    final dates = List.generate(30, (index) {
      // Start from 15 days before today
      return DateTime(today.year, today.month, today.day - 15 + index);
    });

    return FutureBuilder<List<dynamic>>(
      future: Future.value(medicines),
      builder: (context, snapshot) {
        final medicines = snapshot.data ?? [];
        return SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: BouncingScrollPhysics(),
          child: Column(
            children: [
              Container(
                height: 30,
                margin: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: dates.map((date) {
                    return Container(
                      width: 80,
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      child: Center(
                        child: Text(
                          DateFormat('EEE').format(date),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              Container(
                height: 80,
                child: Row(
                  children: dates.map((date) {
                    final isSelected =
                        date.year == _selectedDate.year &&
                        date.month == _selectedDate.month &&
                        date.day == _selectedDate.day;
                    return _buildDateItem(date, isSelected, medicines);
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Map<String, double> _calculateIntakeProgress(List<dynamic> medicines) {
    final progress = <String, double>{};
    final weekDates = List.generate(7, (i) {
      final startOfWeek = _selectedDate.subtract(
        Duration(days: _selectedDate.weekday - 1),
      );
      return startOfWeek.add(Duration(days: i));
    });

    for (final date in weekDates) {
      final dateKey = DateFormat('yyyy-MM-dd').format(date);
      final medicinesForDate = medicines.where((med) {
        final start = med['startDate'];
        final end = med['endDate'];
        return date.isAfter(start.subtract(const Duration(days: 1))) &&
            date.isBefore(end.add(const Duration(days: 1)));
      }).toList();

      if (medicinesForDate.isEmpty) {
        progress[dateKey] = 0.0;
        continue;
      }

      final takenCount = medicinesForDate.where((med) {
        return med['takenDates'].contains(dateKey);
      }).length;

      progress[dateKey] = takenCount / medicinesForDate.length;
    }

    return progress;
  }

  List<dynamic> _filterMedicinesForDate(
    List<dynamic> medicines,
    DateTime date,
  ) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return medicines.where((med) {
      return (med['startDate']['isBefore'](endOfDay) ||
              med['startDate']['isAtSameMomentAs'](startOfDay)) &&
          (med['endDate']['isAfter'](startOfDay) ||
              med['endDate']['isAtSameMomentAs'](startOfDay));
    }).toList();
  }

  Future<void> _toggleMedicineTaken(dynamic medicine, String dateKey) async {
    print('Toggling medicine: ${medicine['name']} for date: $dateKey');
    print('Current taken dates: ${medicine['takenDates']}');

    // TODO: Implement backend API call to toggle medicine taken
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Calendar"),
        centerTitle: true,
        backgroundColor: Color(0xFFFDFDFD),
        elevation: 0,
      ),
      backgroundColor: Color(0xFFFDFDFD),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.only(top: 4, bottom: 4),
            child: Column(
              children: [
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _selectedDate = DateTime.now();
                    });
                    _scrollToDate(DateTime.now());
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _getAppBarTitle(),
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(width: 4),
                      Icon(Icons.refresh, size: 16, color: Colors.grey[600]),
                    ],
                  ),
                ),
                SizedBox(height: 12),
                SizedBox(
                  height: 22,
                  child: Stack(
                    alignment: Alignment.topCenter,
                    children: [
                      Positioned(
                        top: 8,
                        left: 0,
                        right: 0,
                        child: Container(height: 1, color: Colors.grey[300]),
                      ),
                      Positioned(
                        top: 9,
                        child: CustomPaint(
                          size: const Size(16, 8),
                          painter: _DownTrianglePainter(),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _buildDateScrollBar(),
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Text(
                  "Medicine for Today",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Spacer(),
                GestureDetector(
                  onTap: () => Navigator.of(context).pushNamed('/add'),
                  child: Text("+ Add", style: TextStyle(color: Colors.blue)),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<dynamic>>(
              future: Future.value(medicines),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Text(
                      'No medicines for ${DateFormat.yMMMMd().format(_selectedDate)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  );
                }
                final allMedicines = snapshot.data!;
                final medicinesForSelectedDate = _filterMedicinesForDate(
                  allMedicines,
                  _selectedDate,
                );
                if (medicinesForSelectedDate.isEmpty) {
                  return Center(
                    child: Text(
                      'No medicines for ${DateFormat.yMMMMd().format(_selectedDate)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: medicinesForSelectedDate.length,
                  itemBuilder: (context, index) {
                    final medicine = medicinesForSelectedDate[index];
                    final dateKey = DateFormat(
                      'yyyy-MM-dd',
                    ).format(_selectedDate);
                    final isTaken = medicine['takenDates'].contains(dateKey);

                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                        side: BorderSide(color: Color(0xFFD9D9D9), width: 0.5),
                      ),
                      color: Colors.white,
                      shadowColor: Colors.black.withOpacity(0.09),
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.09),
                              blurRadius: 7.6,
                              offset: Offset(0, 3),
                              spreadRadius: -4,
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                DateFormat(
                                  'hh:mm a',
                                ).format(medicine['startDate']),
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    width: 60,
                                    height: 60,
                                    color: Colors.grey[300],
                                  ),
                                  SizedBox(width: 16),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        medicine['name'],
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(medicine['dosage']),
                                    ],
                                  ),
                                ],
                              ),
                              SizedBox(height: 16),
                              isTaken
                                  ? OutlinedButton(
                                      onPressed: () => _toggleMedicineTaken(
                                        medicine,
                                        dateKey,
                                      ),
                                      child: Text("Untake"),
                                    )
                                  : ElevatedButton(
                                      onPressed: () => _toggleMedicineTaken(
                                        medicine,
                                        dateKey,
                                      ),
                                      child: Text("Taken"),
                                    ),
                            ],
                          ),
                        ),
                      ),
                    );
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

class _DownTrianglePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.grey[600]!
      ..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  List<dynamic> medicines = [];
  DateTime _selectedDate = DateTime.now();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToDate(DateTime.now());
    });
    _fetchMedicines();
  }

  Future<void> _fetchMedicines() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('medicines')
        .get();
    final data = snapshot.docs.map((doc) {
      final medicine = doc.data();
      medicine['id'] = doc.id;
      return medicine;
    }).toList();
    setState(() {
      medicines = data;
    });
  }

  void _scrollToDate(DateTime date) {
    final today = DateTime.now();
    final dates = List.generate(30, (index) {
      return DateTime(today.year, today.month, today.day - 15 + index);
    });

    final selectedIndex = dates.indexWhere(
      (d) => d.year == date.year && d.month == date.month && d.day == date.day,
    );

    if (selectedIndex != -1) {
      final itemWidth = 96.0;
      final screenWidth = MediaQuery.of(context).size.width;
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
    final dateToCheck = DateTime(date.year, date.month, date.day);
    final dateKey = DateFormat('yyyy-MM-dd').format(dateToCheck);

    if (dateToCheck.isAfter(startOfDay)) {
      return Colors.grey[200]!;
    } else if (dateToCheck.isAtSameMomentAs(startOfDay)) {
      return Colors.transparent;
    } else {
      final medicinesForDate = medicines.where((med) {
        final medStart = (med['startDate'] as Timestamp).toDate();
        final medEnd = (med['endDate'] as Timestamp).toDate();
        final isInRange =
            dateToCheck.isAfter(medStart.subtract(Duration(days: 1))) &&
            dateToCheck.isBefore(medEnd.add(Duration(days: 1)));
        return isInRange;
      }).toList();

      if (medicinesForDate.isEmpty) {
        return Colors.blue.withOpacity(0.1);
      }

      final allMedicinesTaken = medicinesForDate.every((med) {
        final takenDates = List<String>.from(med['takenDates'] ?? []);
        return takenDates.contains(dateKey);
      });

      return allMedicinesTaken
          ? Colors.blue.withOpacity(0.8)
          : Colors.blue.withOpacity(0.1);
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
      return DateTime(today.year, today.month, today.day - 15 + index);
    });

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
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
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
  }

  Future<void> _toggleMedicineTaken(dynamic medicine, String dateKey) async {
    final takenDates = List<String>.from(medicine['takenDates'] ?? []);
    final docId = medicine['id'];

    if (takenDates.contains(dateKey)) {
      takenDates.remove(dateKey);
    } else {
      takenDates.add(dateKey);
    }

    await FirebaseFirestore.instance.collection('medicines').doc(docId).update({
      'takenDates': takenDates,
    });

    await _fetchMedicines();
  }

  List<dynamic> _filterMedicinesForDate(
    List<dynamic> medicines,
    DateTime date,
  ) {
    return medicines.where((med) {
      final start = (med['startDate'] as Timestamp).toDate();
      final end = (med['endDate'] as Timestamp).toDate();
      return date.isAfter(start.subtract(const Duration(days: 1))) &&
          date.isBefore(end.add(const Duration(days: 1)));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final medicinesForSelectedDate = _filterMedicinesForDate(
      medicines,
      _selectedDate,
    );

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
            child: medicinesForSelectedDate.isEmpty
                ? Center(
                    child: Text(
                      'No medicines for ${DateFormat.yMMMMd().format(_selectedDate)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  )
                : ListView.builder(
                    itemCount: medicinesForSelectedDate.length,
                    itemBuilder: (context, index) {
                      final medicine = medicinesForSelectedDate[index];
                      final isTaken = List<String>.from(
                        medicine['takenDates'] ?? [],
                      ).contains(dateKey);

                      return Card(
                        margin: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: Color(0xFFD9D9D9),
                            width: 0.5,
                          ),
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
                                  DateFormat('hh:mm a').format(
                                    (medicine['startDate'] as Timestamp)
                                        .toDate(),
                                  ),
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
                                        Text(medicine['dosage'].toString()),
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

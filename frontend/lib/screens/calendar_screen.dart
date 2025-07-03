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
    print("Fetched medicines: $data");
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

  // Helper method to determine completion status for a date
  Map<String, dynamic> _getCompletionStatus(
    DateTime date,
    List<dynamic> medicines,
  ) {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final dateToCheck = DateTime(date.year, date.month, date.day);
    final dateKey = DateFormat('yyyy-MM-dd').format(dateToCheck);
    final isCurrentDay = dateToCheck.isAtSameMomentAs(startOfDay);

    if (dateToCheck.isAfter(startOfDay)) {
      return {
        'isFuture': true,
        'isCurrentDay': false,
        'hasMedicines': false,
        'totalMedicines': 0,
        'takenMedicines': 0,
        'completionRatio': 0.0,
        'hasNoMedicines': false,
        'hasMedicinesButNoneTaken': false,
      };
    }

    final medicinesForDate = medicines.where((med) {
      final medStart = (med['startDate'] as Timestamp).toDate();
      final medEnd = (med['endDate'] as Timestamp).toDate();
      final isInRange =
          dateToCheck.isAfter(medStart.subtract(Duration(days: 1))) &&
          dateToCheck.isBefore(medEnd.add(Duration(days: 1)));
      return isInRange;
    }).toList();

    if (medicinesForDate.isEmpty) {
      return {
        'isFuture': false,
        'isCurrentDay': isCurrentDay,
        'hasMedicines': false,
        'totalMedicines': 0,
        'takenMedicines': 0,
        'completionRatio': 0.0,
        'hasNoMedicines': true,
        'hasMedicinesButNoneTaken': false,
      };
    }

    final totalTimes = medicinesForDate.fold<int>(0, (sum, med) {
      final timesField = med['times'];
      List timesList = [];
      if (timesField is List) {
        timesList = timesField;
      } else if (timesField is Map) {
        timesList = timesField.values.toList();
      }
      return sum + timesList.length;
    });

    int takenCount = 0;
    for (final med in medicinesForDate) {
      final takenDatesMap = med['takenDates'] ?? {};
      if (takenDatesMap is Map && takenDatesMap[dateKey] is Map) {
        takenCount += (takenDatesMap[dateKey] as Map).length;
      }
    }

    final completionRatio = totalTimes == 0 ? 0.0 : takenCount / totalTimes;
    final hasMedicinesButNoneTaken =
        !isCurrentDay && takenCount == 0 && totalTimes > 0;

    return {
      'isFuture': false,
      'isCurrentDay': isCurrentDay,
      'hasMedicines': true,
      'totalMedicines': totalTimes,
      'takenMedicines': takenCount,
      'completionRatio': completionRatio,
      'hasNoMedicines': false,
      'hasMedicinesButNoneTaken': hasMedicinesButNoneTaken,
    };
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
    final completionStatus = _getCompletionStatus(date, medicines);

    // Determine background color
    Color backgroundColor = Colors.transparent; // Default for current day
    if (completionStatus['isFuture']) {
      backgroundColor = Colors.grey[200]!;
    } else if (completionStatus['hasNoMedicines']) {
      backgroundColor = Color(
        0xFFDFEDFF,
      ); // Light blue for days with no medicines assigned
    } else if (completionStatus['hasMedicinesButNoneTaken']) {
      backgroundColor = Color(
        0xFFFFEB4F,
      ); // Yellow for past days with medicines but none taken
    }

    return GestureDetector(
      onTap: () => _onDateSelected(date),
      child: Container(
        width: 80,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(5),
          border: _getDateBorder(date),
        ),
        child: Stack(
          children: [
            // Background fill for completion status (only for days with medicines and some taken)
            if (!completionStatus['isFuture'] &&
                completionStatus['hasMedicines'] &&
                completionStatus['takenMedicines'] > 0)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: CustomPaint(
                    painter: _CompletionFillPainter(
                      completionRatio: completionStatus['completionRatio'],
                      color: const Color(0xFF0077FE),
                    ),
                  ),
                ),
              ),
            // Date text
            Center(
              child: Text(
                dayOfMonth,
                style: TextStyle(
                  color: isFutureDate ? Colors.grey[600] : Colors.black87,
                  fontSize: 16,
                  fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
          ],
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

  Future<void> _toggleMedicineTaken(
    dynamic medicine,
    String dateKey,
    String time,
  ) async {
    // takenDates is a Map<String, Map<String, String>>
    Map<String, dynamic> takenDatesMap = {};
    if (medicine['takenDates'] != null) {
      takenDatesMap = Map<String, dynamic>.from(medicine['takenDates']);
    }
    Map<String, String> timesTaken = {};
    if (takenDatesMap[dateKey] is Map) {
      timesTaken = Map<String, String>.from(takenDatesMap[dateKey]);
    }

    final docId = medicine['id'];
    final isCurrentlyTaken = timesTaken.containsKey(time);

    final action = isCurrentlyTaken ? 'untaken' : 'taken';

    if (isCurrentlyTaken) {
      timesTaken.remove(time);
    } else {
      // Store the actual time taken (current time)
      final now = TimeOfDay.now();
      final nowString =
          now.hour.toString().padLeft(2, '0') +
          ':' +
          now.minute.toString().padLeft(2, '0');
      timesTaken[time] = nowString;
    }
    takenDatesMap[dateKey] = timesTaken;

    // Update the medicine document
    await FirebaseFirestore.instance.collection('medicines').doc(docId).update({
      'takenDates': takenDatesMap,
    });

    // Log the action for analytics/tracking
    await FirebaseFirestore.instance.collection('medicine_logs').add({
      'medicineId': docId,
      'medicineName': medicine['name'],
      'action': action,
      'date': dateKey,
      'time': time,
      'actualTime': isCurrentlyTaken ? null : timesTaken[time],
      'timestamp': FieldValue.serverTimestamp(),
      'userId': 'current_user', // You can replace this with actual user ID
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

  List<Map<String, dynamic>> _getMedicineTimePairsForDate(
    List<dynamic> medicines,
    DateTime date,
  ) {
    final dateKey = DateFormat('yyyy-MM-dd').format(date);
    List<Map<String, dynamic>> pairs = [];
    for (var med in medicines) {
      final start = (med['startDate'] as Timestamp).toDate();
      final end = (med['endDate'] as Timestamp).toDate();
      if (date.isAfter(start.subtract(const Duration(days: 1))) &&
          date.isBefore(end.add(const Duration(days: 1)))) {
        final timesField = med['times'];
        List timesList = [];
        if (timesField is List) {
          timesList = timesField;
        } else if (timesField is Map) {
          timesList = timesField.values.toList();
        }
        final intakeTimes = timesList.map<String>((t) {
          if (t is Timestamp) {
            final dt = t.toDate();
            return dt.hour.toString().padLeft(2, '0') +
                ':' +
                dt.minute.toString().padLeft(2, '0');
          }
          return t.toString();
        }).toList();
        print("Medicine: ${med['name']}, IntakeTimes: $intakeTimes");
        for (var time in intakeTimes) {
          pairs.add({
            'medicine': med,
            'time': time,
            'isTaken':
                (med['takenDates'] != null &&
                med['takenDates'][dateKey] != null &&
                med['takenDates'][dateKey] is Map &&
                (med['takenDates'][dateKey] as Map).containsKey(time)),
          });
        }
      }
    }
    return pairs;
  }

  // Add this helper function to parse both 24-hour and 12-hour time strings
  TimeOfDay parseTimeOfDay(String time) {
    try {
      final parts = time.split(':');
      if (parts.length == 2 &&
          !time.toLowerCase().contains('am') &&
          !time.toLowerCase().contains('pm')) {
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
      // Try 12-hour format with AM/PM
      final date = DateFormat.jm().parse(time);
      return TimeOfDay.fromDateTime(date);
    } catch (e) {
      return TimeOfDay.now();
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateKey = DateFormat('yyyy-MM-dd').format(_selectedDate);
    var medicineTimePairs = _getMedicineTimePairsForDate(
      medicines,
      _selectedDate,
    );

    // Sort medicineTimePairs by time (morning first, then afternoon, then evening)
    medicineTimePairs.sort((a, b) {
      final timeA = parseTimeOfDay(a['time']);
      final timeB = parseTimeOfDay(b['time']);
      final minutesA = timeA.hour * 60 + timeA.minute;
      final minutesB = timeB.hour * 60 + timeB.minute;
      return minutesA.compareTo(minutesB);
    });

    return Scaffold(
      appBar: AppBar(
        title: Text("Calendar"),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
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
              ],
            ),
          ),
          Expanded(
            child: medicineTimePairs.isEmpty
                ? Center(
                    child: Text(
                      'No medicines for ${DateFormat.yMMMMd().format(_selectedDate)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  )
                : ListView.builder(
                    itemCount: medicineTimePairs.length,
                    itemBuilder: (context, index) {
                      final med = medicineTimePairs[index]['medicine'];
                      final time = medicineTimePairs[index]['time'];
                      final isTaken = medicineTimePairs[index]['isTaken'];

                      // Format time robustly (24h or 12h)
                      final timeOfDay = parseTimeOfDay(time);
                      final formattedTime = timeOfDay.format(context);

                      return Card(
                        margin: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(5),
                          side: BorderSide(color: Color(0xFFF8F8F8), width: 1),
                        ),
                        color: Colors.white,
                        shadowColor: Colors.transparent,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: Color(0xFFF8F8F8),
                              width: 1,
                            ),
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
                                  formattedTime,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF0077FE),
                                  ),
                                ),
                                Text(
                                  med['name'],
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 22,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF04080E),
                                  ),
                                ),
                                Text(
                                  'Intake ${med['dosage']} tablet',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    color: Color(0xFF04080E),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                SizedBox(height: 8),
                                isTaken
                                    ? Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          ElevatedButton(
                                            onPressed: () =>
                                                _toggleMedicineTaken(
                                                  med,
                                                  dateKey,
                                                  time,
                                                ),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.white,
                                              foregroundColor: Color(
                                                0xFF117CF5,
                                              ),
                                              elevation: 0,
                                              side: const BorderSide(
                                                color: Color(0xFF117CF5),
                                                width: 1,
                                              ),
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 14,
                                                  ),
                                              textStyle: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(5),
                                              ),
                                            ),
                                            child: const Text("Untake"),
                                          ),
                                          const SizedBox(height: 8),
                                          Text(
                                            'Taken at ' +
                                                (med['takenDates']?[dateKey]?[time] ??
                                                    formattedTime),
                                            style: const TextStyle(
                                              color: Colors.green,
                                              fontSize: 14,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ],
                                      )
                                    : SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () => _toggleMedicineTaken(
                                            med,
                                            dateKey,
                                            time,
                                          ),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Color(0xFF117CF5),
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14,
                                            ),
                                            textStyle: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(5),
                                            ),
                                          ),
                                          child: const Text("Taken"),
                                        ),
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

class _CompletionFillPainter extends CustomPainter {
  final double completionRatio;
  final Color color;

  const _CompletionFillPainter({
    required this.completionRatio,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Create a rectangle that fills from bottom up based on completion ratio
    final fillHeight = size.height * completionRatio;
    final rect = Rect.fromLTWH(
      0,
      size.height - fillHeight,
      size.width,
      fillHeight,
    );
    canvas.drawRect(rect, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) =>
      completionRatio !=
      (oldDelegate as _CompletionFillPainter).completionRatio;
}

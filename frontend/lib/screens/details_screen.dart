import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class DetailsScreen extends StatefulWidget {
  final String docId;
  final Map<String, dynamic> medicine;
  const DetailsScreen({Key? key, required this.docId, required this.medicine})
    : super(key: key);

  @override
  State<DetailsScreen> createState() => _DetailsScreenState();
}

class _DetailsScreenState extends State<DetailsScreen> {
  late Map<String, dynamic> _edited;
  bool _editing = false;
  bool _saving = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _edited = Map<String, dynamic>.from(widget.medicine);
  }

  void _onFieldChanged(String key, dynamic value) {
    setState(() {
      _edited[key] = value;
      _editing = true;
    });
  }

  void _onCancel() {
    setState(() {
      _edited = Map<String, dynamic>.from(widget.medicine);
      _editing = false;
    });
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
    });

    // Prepare data for saving - convert string numbers back to proper types
    Map<String, dynamic> dataToSave = Map<String, dynamic>.from(_edited);

    // Convert quantity to int if it's a string
    if (dataToSave['quantity'] is String) {
      dataToSave['quantity'] = int.tryParse(dataToSave['quantity']) ?? 0;
    }

    await FirebaseFirestore.instance
        .collection('medicines')
        .doc(widget.docId)
        .update(dataToSave);

    setState(() {
      _editing = false;
      _saving = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Changes saved.')));
    }
  }

  Future<void> _onDelete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medicine'),
        content: const Text('Are you sure you want to delete this medicine?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirm == true) {
      await FirebaseFirestore.instance
          .collection('medicines')
          .doc(widget.docId)
          .delete();
      if (mounted) Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final quantity = _edited['quantity'] is int
        ? _edited['quantity']
        : int.tryParse(_edited['quantity']?.toString() ?? '') ?? 0;

    final dosage = _edited['dosage']?.toString() ?? '';

    // Handle times field which might contain strings or Timestamps
    List<Timestamp> rawTimes = [];
    if (_edited['times'] != null) {
      final timesData = _edited['times'] as List;
      rawTimes = _convertToTimestamps(timesData);
    }

    final times = rawTimes
        .map((t) => TimeOfDay.fromDateTime(t.toDate()).format(context))
        .toList();

    // Calculate taken count from takenDates
    final takenDates = List<String>.from(_edited['takenDates'] ?? []);
    final takenCount = takenDates.length;

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          title: Text(_edited['name'] ?? 'Medicine'),
          backgroundColor: Colors.white,
          elevation: 0,
          actions: [
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.red),
              onPressed: _onDelete,
              tooltip: 'Delete',
            ),
          ],
          flexibleSpace: Container(
            alignment: Alignment.bottomCenter,
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Color(0xFFEEEEEE), width: 1),
              ),
            ),
          ),
        ),
      ),
      backgroundColor: const Color(0xFFFCFCFC),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _statBox(
                  'You have been\ntaking this medicine',
                  '$takenCount times',
                ),
                _statBox('Days left:', _daysLeft(_edited)),
              ],
            ),
            const SizedBox(height: 24),
            // Name
            _buildTextField('Name', 'name', _edited['name']),
            const SizedBox(height: 16),
            // Instructions
            _buildTextField(
              'Instructions',
              'instructions',
              _edited['instructions'],
            ),
            const SizedBox(height: 16),
            // One row: Dosage, Strength, Quantity
            Row(
              children: [
                Expanded(child: _buildTextField('Dosage', 'dosage', dosage)),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTextField(
                    'Strength',
                    'strength',
                    _edited['strength'],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildNumberField('Quantity', 'quantity', quantity),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Duration
            const Text(
              'Duration',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            // Start date and End date
            Row(
              children: [
                Expanded(
                  child: _buildDateField(
                    'Start Date',
                    'startDate',
                    _edited['startDate'],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildDateField(
                    'End Date',
                    'endDate',
                    _edited['endDate'],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // At what time?
            const Text(
              'At what time?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            // Time here
            ...List.generate(
              times.length,
              (i) => Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: Colors.red),
                    onPressed: () {
                      final updated = _convertToTimestamps(_edited['times']);
                      if (i < updated.length) {
                        updated.removeAt(i);
                        _onFieldChanged('times', updated);
                      }
                    },
                  ),
                  Text(times[i]),
                ],
              ),
            ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_circle, color: Colors.green),
                  onPressed: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay.now(),
                    );
                    if (picked != null) {
                      final now = DateTime.now();
                      final selected = DateTime(
                        now.year,
                        now.month,
                        now.day,
                        picked.hour,
                        picked.minute,
                      );
                      final updated = _convertToTimestamps(_edited['times']);
                      updated.add(Timestamp.fromDate(selected));
                      _onFieldChanged('times', updated);
                    }
                  },
                ),
                const Text('Add a time'),
              ],
            ),
            const SizedBox(height: 32),
            if (_editing)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _saving ? null : _onCancel,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: const BorderSide(color: Colors.grey),
                        textStyle: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving ? null : _onSave,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Theme.of(context).primaryColor,
                        foregroundColor: Colors.white,
                        textStyle: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      child: _saving
                          ? const SizedBox(
                              height: 18,
                              width: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Save'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, String key, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        initialValue: value?.toString() ?? '',
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: (val) => _onFieldChanged(key, val),
        validator: (val) =>
            (val == null || val.trim().isEmpty) ? '$label is required' : null,
      ),
    );
  }

  Widget _buildNumberField(
    String label,
    String key,
    dynamic value, {
    bool isDouble = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        initialValue: value?.toString() ?? '',
        keyboardType: TextInputType.numberWithOptions(decimal: isDouble),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: (val) {
          if (isDouble) {
            final doubleVal = double.tryParse(val) ?? 0.0;
            _onFieldChanged(key, doubleVal);
          } else {
            final intVal = int.tryParse(val) ?? 0;
            _onFieldChanged(key, intVal);
          }
        },
        validator: (val) {
          if (val == null || val.trim().isEmpty) {
            return '$label is required';
          }
          if (isDouble) {
            if (double.tryParse(val) == null) {
              return '$label must be a valid number';
            }
          } else {
            if (int.tryParse(val) == null) {
              return '$label must be a valid integer';
            }
          }
          return null;
        },
      ),
    );
  }

  Widget _buildDateField(String label, String key, dynamic value) {
    DateTime? date = _toDate(value);
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime(2100),
        );
        if (picked != null) {
          _onFieldChanged(key, Timestamp.fromDate(picked));
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today, size: 18),
            const SizedBox(width: 8),
            Text(
              date != null ? DateFormat('yyyy-MM-dd').format(date) : 'Select',
            ),
          ],
        ),
      ),
    );
  }

  Widget _statBox(String label, String value) {
    return Container(
      width: 173,
      height: 152,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFCDE4FF),
        borderRadius: BorderRadius.circular(9),
        border: Border.all(color: const Color(0xFF1A8CE3), width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.blue,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _daysLeft(Map<String, dynamic> med) {
    try {
      final end = med['endDate'];
      final endDate = _toDate(end);
      if (endDate == null) return '-';

      final now = DateTime.now();
      final startOfToday = DateTime(now.year, now.month, now.day);
      final endOfToday = DateTime(now.year, now.month, now.day, 23, 59, 59);

      // If end date is today or in the past, return 0
      if (endDate.isBefore(endOfToday)) {
        return '0';
      }

      // Calculate days left (including today)
      final diff = endDate.difference(startOfToday).inDays;
      return diff >= 0 ? diff.toString() : '0';
    } catch (_) {
      return '-';
    }
  }

  DateTime? _toDate(dynamic ts) {
    if (ts == null) return null;
    if (ts is DateTime) return ts;
    if (ts is String) return DateTime.tryParse(ts);
    if (ts is Timestamp) return ts.toDate();
    return null;
  }

  // Helper function to safely convert times data to List<Timestamp>
  List<Timestamp> _convertToTimestamps(List? timesData) {
    if (timesData == null) return [];

    return timesData.map((item) {
      if (item is Timestamp) {
        return item;
      } else if (item is String) {
        // Handle TimeOfDay format strings (like "2:30 PM")
        try {
          // First try to parse as ISO format
          final dateTime = DateTime.parse(item);
          return Timestamp.fromDate(dateTime);
        } catch (e) {
          // If that fails, try to parse as TimeOfDay format
          try {
            // Extract time from string like "2:30 PM"
            final timeStr = item.trim();
            final isPM = timeStr.toLowerCase().contains('pm');
            final timeOnly = timeStr.replaceAll(
              RegExp(r'\s*(am|pm)\s*', caseSensitive: false),
              '',
            );
            final parts = timeOnly.split(':');

            if (parts.length == 2) {
              int hour = int.parse(parts[0]);
              int minute = int.parse(parts[1]);

              // Convert to 24-hour format
              if (isPM && hour != 12) hour += 12;
              if (!isPM && hour == 12) hour = 0;

              // Create DateTime for today with the specified time
              final now = DateTime.now();
              final dateTime = DateTime(
                now.year,
                now.month,
                now.day,
                hour,
                minute,
              );
              return Timestamp.fromDate(dateTime);
            }
          } catch (e2) {
            // If all parsing fails, return current time as fallback
            return Timestamp.now();
          }
          return Timestamp.now();
        }
      } else {
        // Fallback for any other type
        return Timestamp.now();
      }
    }).toList();
  }
}

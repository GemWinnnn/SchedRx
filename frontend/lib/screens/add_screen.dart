import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';

class AddScreen extends StatefulWidget {
  const AddScreen({super.key});

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> with TickerProviderStateMixin {
  File? _selectedImage;
  bool _isLoading = false;
  String? _error;
  List<Map<String, dynamic>> _detectedMedicines = [];
  TabController? _tabController;
  List<TextEditingController> _nameControllers = [];
  Map<int, Map<String, String>> _fieldErrors = {};
  bool _submitted = false;

  DateTime? _toDate(dynamic ts) {
    if (ts == null) return null;
    if (ts is DateTime) return ts;
    if (ts is String) return DateTime.tryParse(ts);
    if (ts is Timestamp) return ts.toDate();
    return null;
  }

  // Step 1: Pick image
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _error = null;
      });
      await _uploadAndParseImage(_selectedImage!);
    }
  }

  // Step 2: Upload image and get detected medicines
  Future<void> _uploadAndParseImage(File imageFile) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(
          'http://127.0.0.1:8000/parse-prescription',
        ), // Change to your backend URL
      );
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );
      var response = await request.send();
      if (response.statusCode == 200) {
        final respStr = await response.stream.bytesToString();
        final result = jsonDecode(respStr);
        final items = (result['prescription_items'] ?? []) as List;
        _nameControllers.forEach((c) => c.dispose());
        _nameControllers = [];
        _detectedMedicines = [];
        for (var med in items) {
          _detectedMedicines.add({
            'medicine': med['medicine'] ?? '',
            'dosage': (med['dosage'] is List)
                ? (med['dosage'] as List).join(', ')
                : (med['dosage'] ?? ''),
            'strength': (med['strength'] is List)
                ? (med['strength'] as List).join(', ')
                : (med['strength'] ?? ''),
            'instructions': (med['instructions'] is List)
                ? (med['instructions'] as List).join(', ')
                : (med['instructions'] ?? ''),
            'quantity': (med['quantity'] is List)
                ? (med['quantity'] as List).join(', ')
                : (med['quantity'] ?? ''),
            'duration_start': null,
            'duration_end': null,
            'form': '',
            'times': <TimeOfDay>[],
          });
          _nameControllers.add(
            TextEditingController(text: med['medicine'] ?? ''),
          );
        }
        _tabController?.dispose();
        _tabController = TabController(
          length: _detectedMedicines.length + 1, // +1 for the + tab
          vsync: this,
        );
        setState(() {});
      } else {
        setState(() {
          _error =
              'Failed to parse prescription (status ${response.statusCode})';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Error: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Step 3: Build detected medicine forms
  List<Widget> _buildMedicineForms() {
    return List.generate(_detectedMedicines.length, (i) {
      final med = _detectedMedicines[i];
      final nameController = _nameControllers[i];
      final dosageController = TextEditingController(text: med['dosage'] ?? '');
      final strengthController = TextEditingController(
        text: med['strength'] ?? '',
      );
      final instructionsController = TextEditingController(
        text: med['instructions'] ?? '',
      );
      final quantityController = TextEditingController(
        text: med['quantity'] ?? '',
      );
      final startDate = med['duration_start'] as DateTime?;
      final endDate = med['duration_end'] as DateTime?;
      final times = (med['times'] as List<TimeOfDay>? ?? []);
      final errors = _fieldErrors[i] ?? {};

      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Name
              const Text('Name'),
              const SizedBox(height: 4),
              TextField(
                controller: nameController,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(),
                  isDense: true,
                  errorText: _submitted && (errors['name']?.isNotEmpty ?? false)
                      ? errors['name']
                      : null,
                ),
                onChanged: (val) {
                  setState(() {
                    _detectedMedicines[i]['medicine'] = val;
                    if (_submitted) _fieldErrors[i]?.remove('name');
                  });
                },
              ),
              const SizedBox(height: 16),
              // Instructions
              const Text('Instructions'),
              const SizedBox(height: 4),
              TextField(
                controller: instructionsController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (val) {
                  _detectedMedicines[i]['instructions'] = val;
                },
              ),
              const SizedBox(height: 16),
              // Dosage, Strength, Quantity in one row
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Dosage'),
                        const SizedBox(height: 4),
                        TextField(
                          controller: dosageController,
                          decoration: InputDecoration(
                            border: const OutlineInputBorder(),
                            isDense: true,
                            errorText:
                                _submitted &&
                                    (errors['dosage']?.isNotEmpty ?? false)
                                ? errors['dosage']
                                : null,
                          ),
                          onChanged: (val) {
                            _detectedMedicines[i]['dosage'] = val;
                            if (_submitted) _fieldErrors[i]?.remove('dosage');
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Strength'),
                        const SizedBox(height: 4),
                        TextField(
                          controller: strengthController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (val) {
                            _detectedMedicines[i]['strength'] = val;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Quantity'),
                        const SizedBox(height: 4),
                        TextField(
                          controller: quantityController,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          onChanged: (val) {
                            _detectedMedicines[i]['quantity'] = val;
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Duration
              const Text('Duration'),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Start Date'),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: startDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() {
                                _detectedMedicines[i]['duration_start'] =
                                    picked;
                                if (_submitted)
                                  _fieldErrors[i]?.remove('startDate');
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              isDense: true,
                              errorText:
                                  _submitted &&
                                      (errors['startDate']?.isNotEmpty ?? false)
                                  ? errors['startDate']
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  startDate != null
                                      ? '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}'
                                      : 'Select',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('End Date'),
                        const SizedBox(height: 4),
                        InkWell(
                          onTap: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: endDate ?? DateTime.now(),
                              firstDate: DateTime(2000),
                              lastDate: DateTime(2100),
                            );
                            if (picked != null) {
                              setState(() {
                                _detectedMedicines[i]['duration_end'] = picked;
                                if (_submitted)
                                  _fieldErrors[i]?.remove('endDate');
                              });
                            }
                          },
                          child: InputDecorator(
                            decoration: InputDecoration(
                              border: const OutlineInputBorder(),
                              isDense: true,
                              errorText:
                                  _submitted &&
                                      (errors['endDate']?.isNotEmpty ?? false)
                                  ? errors['endDate']
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_today, size: 18),
                                const SizedBox(width: 8),
                                Text(
                                  endDate != null
                                      ? '${endDate.year}-${endDate.month.toString().padLeft(2, '0')}-${endDate.day.toString().padLeft(2, '0')}'
                                      : 'Select',
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // At what time?
              const Text('At what time?'),
              const SizedBox(height: 4),
              Column(
                children: [
                  ...List.generate(times.length, (tIdx) {
                    final t = times[tIdx];
                    return Row(
                      children: [
                        IconButton(
                          icon: const Icon(
                            Icons.remove_circle,
                            color: Colors.red,
                          ),
                          onPressed: () {
                            setState(() {
                              times.removeAt(tIdx);
                              _detectedMedicines[i]['times'] =
                                  List<TimeOfDay>.from(times);
                              if (_submitted && times.isNotEmpty)
                                _fieldErrors[i]?.remove('times');
                            });
                          },
                        ),
                        Text('${t.format(context)}'),
                      ],
                    );
                  }),
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
                            setState(() {
                              times.add(picked);
                              _detectedMedicines[i]['times'] =
                                  List<TimeOfDay>.from(times);
                              if (_submitted && times.isNotEmpty)
                                _fieldErrors[i]?.remove('times');
                            });
                          }
                        },
                      ),
                      const Text('Add a time'),
                    ],
                  ),
                  if (_submitted && (errors['times']?.isNotEmpty ?? false))
                    Padding(
                      padding: const EdgeInsets.only(top: 4, left: 8),
                      child: Text(
                        errors['times']!,
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 24),
              // Schedule All Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1976F6),
                    foregroundColor: Colors.white,
                    textStyle: const TextStyle(
                      fontFamily: 'Roboto',
                      fontWeight: FontWeight.w700,
                      fontSize: 16,
                      height: 1.2,
                    ),
                  ),
                  onPressed: () async {
                    _submitted = true;
                    _fieldErrors.clear();
                    bool hasError = false;
                    for (int i = 0; i < _detectedMedicines.length; i++) {
                      final med = _detectedMedicines[i];
                      final errors = <String, String>{};
                      if ((med['medicine'] as String?)?.trim().isEmpty ??
                          true) {
                        errors['name'] = 'Name is required.';
                        hasError = true;
                      }
                      if ((med['dosage'] as String?)?.trim().isEmpty ?? true) {
                        errors['dosage'] = 'Dosage is required.';
                        hasError = true;
                      }
                      if (med['duration_start'] == null) {
                        errors['startDate'] = 'Start date is required.';
                        hasError = true;
                      }
                      if (med['duration_end'] == null) {
                        errors['endDate'] = 'End date is required.';
                        hasError = true;
                      }
                      if ((med['times'] as List).isEmpty) {
                        errors['times'] = 'At least one time is required.';
                        hasError = true;
                      }
                      if (errors.isNotEmpty) {
                        _fieldErrors[i] = errors;
                      }
                    }
                    setState(() {});
                    if (hasError) return;
                    try {
                      for (var med in _detectedMedicines) {
                        // Convert TimeOfDay to string for Firestore
                        final times = (med['times'] as List<TimeOfDay>)
                            .map((t) => t.format(context))
                            .toList();
                        await FirebaseFirestore.instance
                            .collection('medicines')
                            .add({
                              'name': med['medicine'],
                              'dosage':
                                  double.tryParse(med['dosage'].toString()) ??
                                  0,
                              'strength': med['strength'],
                              'instructions': med['instructions'],
                              'quantity':
                                  int.tryParse(med['quantity'].toString()) ?? 0,
                              'startDate': med['duration_start'] != null
                                  ? Timestamp.fromDate(med['duration_start'])
                                  : null,
                              'endDate': med['duration_end'] != null
                                  ? Timestamp.fromDate(med['duration_end'])
                                  : null,
                              'form': med['form'],
                              'times': times,
                              'progress': {},
                            });
                      }
                      // Show confirmation
                      if (mounted) {
                        await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Success'),
                            content: const Text(
                              'Medicines have been scheduled.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(context).pop(),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                        Navigator.pushNamed(context, '/list');
                      }
                    } catch (e) {
                      setState(() {
                        _error = 'Failed to schedule medicines: $e';
                      });
                    }
                  },
                  child: const Text('Schedule All'),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  void _deleteMedicine(int index) {
    setState(() {
      _detectedMedicines.removeAt(index);
      _nameControllers[index].dispose();
      _nameControllers.removeAt(index);
      _tabController?.dispose();
      if (_detectedMedicines.isNotEmpty) {
        _tabController = TabController(
          length: _detectedMedicines.length + 1, // +1 for the + tab
          vsync: this,
        );
      } else {
        _tabController = null;
      }
    });
  }

  void _resetToImagePicker() {
    setState(() {
      _detectedMedicines.clear();
      _nameControllers.forEach((c) => c.dispose());
      _nameControllers.clear();
      _tabController?.dispose();
      _tabController = null;
    });
  }

  @override
  void dispose() {
    _tabController?.dispose();
    _nameControllers.forEach((c) => c.dispose());
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Listen for tab changes to handle the + tab
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _tabController?.addListener(_handleTabChange);
    });
  }

  void _handleTabChange() {
    // No-op: add tab logic now handled by AppBar button only
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_detectedMedicines.isNotEmpty && _tabController != null) {
      return Scaffold(
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _resetToImagePicker,
          ),
          title: const Text('Medicines'),
          actions: [
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                setState(() {
                  _detectedMedicines.add({
                    'medicine': '',
                    'dosage': '',
                    'strength': '',
                    'instructions': '',
                    'quantity': '',
                    'duration_start': null,
                    'duration_end': null,
                    'form': '',
                    'times': <TimeOfDay>[],
                  });
                  _nameControllers.add(TextEditingController());
                  _tabController?.dispose();
                  _tabController = TabController(
                    length: _detectedMedicines.length,
                    vsync: this,
                  );
                  _tabController!.animateTo(_detectedMedicines.length - 1);
                  _tabController!.addListener(_handleTabChange);
                });
              },
            ),
          ],
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.only(
                  left: 8,
                ), // align with back button
                child: TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  tabs: List.generate(_detectedMedicines.length, (i) {
                    return Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              _nameControllers[i].text.isNotEmpty
                                  ? _nameControllers[i].text
                                  : 'Medicine',
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Color(0xFF04080E),
                                fontFamily: 'Roboto',
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                height: 1.5, // 24/16
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          GestureDetector(
                            onTap: () {
                              _deleteMedicine(i);
                            },
                            child: const Icon(
                              Icons.close,
                              size: 18,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            ..._buildMedicineForms(),
            // The + tab content (empty, but triggers add on tab change)
            const SizedBox.shrink(),
          ],
        ),
      );
    }
    // Step 1: Image picker UI
    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: AppBar(
          title: const Text('Add medicine'),
          backgroundColor: Colors.white,
          elevation: 0,
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
      backgroundColor: const Color(0xFFFDFDFD),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 24.0,
              horizontal: 8.0,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 360,
                  height: 360,
                  padding: const EdgeInsets.fromLTRB(68, 106, 68, 111),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD8EAFF),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(
                      color: const Color(0xFF0077FE),
                      width: 1,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 56, color: Colors.black87),
                      const SizedBox(height: 16),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Text(
                          'Submit your prescription here',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF1573DF),
                            fontFamily: 'Roboto',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            height: 20 / 14,
                            letterSpacing: 0.25,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'We will try to process this in a few seconds.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF000101),
                          fontFamily: 'Roboto',
                          fontWeight: FontWeight.w400,
                          fontSize: 12,
                          height: 16 / 12,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: 358,
                  height: 39,
                  child: ElevatedButton(
                    onPressed: () {}, // Always enabled
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF117CF5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(5),
                        side: const BorderSide(
                          color: Color(0xFF0077FE),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.symmetric(
                        vertical: 4,
                        horizontal: 142,
                      ),
                      textStyle: const TextStyle(
                        fontFamily: 'Roboto',
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                        height: 1.2,
                      ),
                    ),
                    child: const Text('Continue'),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

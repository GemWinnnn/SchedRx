import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AddScreen extends StatefulWidget {
  const AddScreen({super.key});

  @override
  State<AddScreen> createState() => _AddScreenState();
}

class _AddScreenState extends State<AddScreen> with TickerProviderStateMixin {
  File? _selectedImage;
  bool _isLoading = false;
  String? _error;
  List<dynamic> _detectedMedicines = [];
  TabController? _tabController;

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
        setState(() {
          _detectedMedicines = result['prescription_items'] ?? [];
          _tabController = TabController(
            length: _detectedMedicines.length,
            vsync: this,
          );
        });
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
    return _detectedMedicines.map((med) {
      final nameController = TextEditingController(text: med['medicine'] ?? '');
      final dosageController = TextEditingController(
        text: (med['dosage'] as List?)?.join(', ') ?? '',
      );
      final instructionsController = TextEditingController(
        text: (med['frequency'] as List?)?.join(', ') ?? '',
      );
      final durationController = TextEditingController(
        text: (med['duration'] as List?)?.join(', ') ?? '',
      );
      final formController = TextEditingController(
        text: (med['form'] as List?)?.join(', ') ?? '',
      );
      final quantityController = TextEditingController(
        text: (med['quantity'] as List?)?.join(', ') ?? '',
      );
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Medicine Name'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dosageController,
                decoration: const InputDecoration(labelText: 'Dosage'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: instructionsController,
                decoration: const InputDecoration(
                  labelText: 'Instructions / Frequency',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: durationController,
                decoration: const InputDecoration(labelText: 'Duration'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: formController,
                decoration: const InputDecoration(labelText: 'Form'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: quantityController,
                decoration: const InputDecoration(labelText: 'Quantity'),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  // TODO: Save or submit this medicine
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Medicine saved!')),
                  );
                },
                child: const Text('Save Medicine'),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    if (_detectedMedicines.isNotEmpty && _tabController != null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Detected Medicines'),
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabs: List.generate(
              _detectedMedicines.length,
              (i) => Tab(text: 'Medicine ${i + 1}'),
            ),
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: _buildMedicineForms(),
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

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
      appBar: AppBar(title: const Text('Add Medicine')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_selectedImage != null)
                Image.file(_selectedImage!, height: 200),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _pickImage,
                icon: const Icon(Icons.camera_alt),
                label: const Text('Pick Prescription Image'),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(_error!, style: const TextStyle(color: Colors.red)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

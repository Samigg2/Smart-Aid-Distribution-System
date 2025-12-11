import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../models/beneficiary_model.dart';
import '../providers/beneficiary_provider.dart';
import 'beneficiary_list_screen.dart';

class BeneficiaryRegistrationScreen extends ConsumerStatefulWidget {
  const BeneficiaryRegistrationScreen({super.key});

  @override
  ConsumerState<BeneficiaryRegistrationScreen> createState() =>
      _BeneficiaryRegistrationScreenState();
}

class _BeneficiaryRegistrationScreenState
    extends ConsumerState<BeneficiaryRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  bool _isLoading = false;

  // Section 1: Personal Information
  final _fullNameController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();
  String _gender = 'female';

  // Section 2: Vulnerable Categories (Multi-select)
  final Set<String> _selectedCategories = {};

  // Pregnant Woman specific
  bool _isPregnant = false;
  int? _pregnancyTrimester;

  // Child Under 5 specific
  int _childrenUnder5Count = 0;
  final List<TextEditingController> _childrenAgeControllers = [];

  // Elderly specific (60+)
  bool _isLivingAlone = false;
  bool _hasCaregiver = false;
  String _mobilityLevel = 'can_walk';

  // Disabled specific
  String _disabilityType = 'physical';
  String _disabilitySeverity = 'moderate';
  bool _usesAssistiveDevice = false;
  bool _needsPersonalAssistance = false;

  // Chronically Ill specific
  String _chronicIllnessType = 'other';
  bool _isOnMedication = false;
  bool _needsRegularMedicalCare = false;

  // Section 3: Family & Vulnerability
  final _familySizeController = TextEditingController(text: '1');
  bool _isFemaleHeadedHousehold = false;
  String _incomeLevel = 'less_than_1000';
  bool _currentlyReceivingOtherAid = false;

  // Section 4: Location
  String _region = 'Addis Ababa';
  final _zoneController = TextEditingController();
  final _woredaController = TextEditingController();
  double? _latitude;
  double? _longitude;

  // Section 5: Photo (OPTIONAL)
  File? _photoFile;
  String? _photoUrl;

  // Ethiopian regions
  final List<String> _regions = [
    'Addis Ababa',
    'Afar',
    'Amhara',
    'Benishangul-Gumuz',
    'Dire Dawa',
    'Gambela',
    'Harari',
    'Oromia',
    'Sidama',
    'SNNPR',
    'Somali',
    'South West Ethiopia',
    'Tigray',
  ];

  @override
  void dispose() {
    _fullNameController.dispose();
    _nationalIdController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    _zoneController.dispose();
    _woredaController.dispose();
    _familySizeController.dispose();
    for (var controller in _childrenAgeControllers) {
      controller.dispose();
    }
    _scrollController.dispose();
    super.dispose();
  }

  void _updateChildrenAgeControllers() {
    while (_childrenAgeControllers.length > _childrenUnder5Count) {
      _childrenAgeControllers.removeLast().dispose();
    }
    while (_childrenAgeControllers.length < _childrenUnder5Count) {
      _childrenAgeControllers.add(TextEditingController());
    }
    setState(() {});
  }

  Future<void> _capturePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
        preferredCameraDevice: CameraDevice.front,
      );

      if (photo != null) {
        final tempDir = await getTemporaryDirectory();
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final fileName = 'beneficiary_photo_$timestamp.jpg';
        final permanentFile = File(path.join(tempDir.path, fileName));

        final originalFile = File(photo.path);
        if (await originalFile.exists()) {
          await originalFile.copy(permanentFile.path);
        } else {
          final bytes = await photo.readAsBytes();
          await permanentFile.writeAsBytes(bytes);
        }

        setState(() {
          _photoFile = permanentFile;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error capturing photo: $e')),
      );
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permission denied')),
          );
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission permanently denied')),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Location: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error getting location: $e')),
      );
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    if (_selectedCategories.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one vulnerable category')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Upload photo to Cloudinary if provided (OPTIONAL)
      if (_photoFile != null) {
        final cloudinaryService = ref.read(cloudinaryServiceProvider);
        _photoUrl = await cloudinaryService.uploadBeneficiaryPhoto(_photoFile!);
      }

      // Collect children ages
      final childrenAges = _childrenAgeControllers
          .map((controller) => int.tryParse(controller.text) ?? 0)
          .where((age) => age > 0)
          .toList();

      // Calculate urgency score with ALL factors
      final urgencyScore = BeneficiaryModel.calculateUrgencyScore(
        vulnerableCategories: _selectedCategories.toList(),
        isPregnant: _isPregnant,
        pregnancyTrimester: _pregnancyTrimester,
        childrenUnder5Count: _childrenUnder5Count,
        childrenAges: childrenAges,
        isFemaleHeadedHousehold: _isFemaleHeadedHousehold,
        incomeLevel: _incomeLevel,
        currentlyReceivingOtherAid: _currentlyReceivingOtherAid,
        isLivingAlone: _isLivingAlone,
        mobilityLevel: _mobilityLevel,
        disabilitySeverity: _disabilitySeverity,
        needsPersonalAssistance: _needsPersonalAssistance,
        needsRegularMedicalCare: _needsRegularMedicalCare,
      );

      // Create beneficiary model
      final beneficiary = BeneficiaryModel(
        beneficiaryId: '',
        fullName: _fullNameController.text.trim(),
        nationalId: _nationalIdController.text.trim(),
        phoneNumber: _phoneController.text.trim().isEmpty
            ? null
            : _phoneController.text.trim(),
        age: int.tryParse(_ageController.text),
        gender: _gender,
        vulnerableCategories: _selectedCategories.toList(),
        beneficiaryType: _selectedCategories.isNotEmpty
            ? _selectedCategories.first
            : null,
        isPregnant: _isPregnant,
        pregnancyTrimester: _isPregnant ? _pregnancyTrimester : null,
        childrenUnder5Count: _childrenUnder5Count,
        childrenAges: childrenAges,
        isLivingAlone: _isLivingAlone,
        hasCaregiver: _hasCaregiver,
        mobilityLevel: _selectedCategories.contains('elderly') ? _mobilityLevel : null,
        disabilityType: _selectedCategories.contains('disabled') ? _disabilityType : null,
        disabilitySeverity: _selectedCategories.contains('disabled') ? _disabilitySeverity : null,
        usesAssistiveDevice: _usesAssistiveDevice,
        needsPersonalAssistance: _needsPersonalAssistance,
        chronicIllnessType: _selectedCategories.contains('chronically_ill') ? _chronicIllnessType : null,
        isOnMedication: _isOnMedication,
        needsRegularMedicalCare: _needsRegularMedicalCare,
        totalFamilySize: int.tryParse(_familySizeController.text) ?? 1,
        isFemaleHeadedHousehold: _isFemaleHeadedHousehold,
        incomeLevel: _incomeLevel,
        currentlyReceivingOtherAid: _currentlyReceivingOtherAid,
        region: _region,
        zone: _zoneController.text.trim().isEmpty ? null : _zoneController.text.trim(),
        woreda: _woredaController.text.trim().isEmpty ? null : _woredaController.text.trim(),
        latitude: _latitude,
        longitude: _longitude,
        photoUrl: _photoUrl,
        registeredBy: currentUser.uid,
        createdAt: DateTime.now(),
        urgencyScore: urgencyScore,
      );

      // Save to Firestore
      final beneficiaryService = ref.read(beneficiaryServiceProvider);
      final beneficiaryId = await beneficiaryService.createBeneficiary(beneficiary);

      if (beneficiaryId != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const BeneficiaryListScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Register Beneficiary'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Personal Information
                    _buildSectionHeader('Personal Information', Icons.person),
                    _buildTextField(
                      controller: _fullNameController,
                      label: 'Full Name *',
                      icon: Icons.badge,
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _nationalIdController,
                      label: 'National ID Number *',
                      icon: Icons.credit_card,
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _phoneController,
                      label: 'Phone Number',
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildTextField(
                            controller: _ageController,
                            label: 'Age',
                            icon: Icons.cake,
                            keyboardType: TextInputType.number,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildDropdown<String>(
                            value: _gender,
                            label: 'Gender *',
                            items: const [
                              DropdownMenuItem(value: 'female', child: Text('Female')),
                              DropdownMenuItem(value: 'male', child: Text('Male')),
                            ],
                            onChanged: (value) => setState(() => _gender = value!),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // Section 2: Vulnerable Categories (Multi-select)
                    _buildSectionHeader('Vulnerable Category *', Icons.warning_amber),
                    const Text(
                      'Select all that apply:',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 8),
                    _buildCategoryCheckboxes(),
                    const SizedBox(height: 16),

                    // Dynamic fields based on selected categories
                    if (_selectedCategories.contains('pregnant_woman'))
                      _buildPregnantWomanFields(),

                    if (_selectedCategories.contains('child_under_5'))
                      _buildChildUnder5Fields(),

                    if (_selectedCategories.contains('elderly'))
                      _buildElderlyFields(),

                    if (_selectedCategories.contains('disabled'))
                      _buildDisabledFields(),

                    if (_selectedCategories.contains('chronically_ill'))
                      _buildChronicallyIllFields(),

                    // Section 3: Family & Vulnerability
                    _buildSectionHeader('Family & Vulnerability', Icons.home),
                    _buildTextField(
                      controller: _familySizeController,
                      label: 'Total Family Size *',
                      icon: Icons.people,
                      keyboardType: TextInputType.number,
                      validator: (value) => value?.isEmpty ?? true ? 'Required' : null,
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Is Female-Headed Household?'),
                      value: _isFemaleHeadedHousehold,
                      onChanged: (value) => setState(() => _isFemaleHeadedHousehold = value),
                    ),
                    const SizedBox(height: 12),
                    _buildDropdown<String>(
                      value: _incomeLevel,
                      label: 'Monthly Family Income *',
                      items: IncomeLevel.values.map((level) {
                        return DropdownMenuItem(value: level.value, child: Text(level.label));
                      }).toList(),
                      onChanged: (value) => setState(() => _incomeLevel = value!),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      title: const Text('Currently Receiving Other Aid?'),
                      value: _currentlyReceivingOtherAid,
                      onChanged: (value) => setState(() => _currentlyReceivingOtherAid = value),
                    ),
                    const SizedBox(height: 24),

                    // Section 4: Location
                    _buildSectionHeader('Location', Icons.location_on),
                    _buildDropdown<String>(
                      value: _region,
                      label: 'Region *',
                      items: _regions.map((region) {
                        return DropdownMenuItem(value: region, child: Text(region));
                      }).toList(),
                      onChanged: (value) => setState(() => _region = value!),
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _zoneController,
                      label: 'Zone',
                      icon: Icons.map,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _woredaController,
                      label: 'Woreda',
                      icon: Icons.location_city,
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _getCurrentLocation,
                      icon: const Icon(Icons.gps_fixed),
                      label: Text(
                        _latitude != null && _longitude != null
                            ? 'GPS: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}'
                            : 'Capture GPS Coordinates',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Section 5: Photo (OPTIONAL)
                    _buildSectionHeader('Photo (Optional)', Icons.camera_alt),
                    const Text(
                      'Photo is optional but recommended for identification',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    const SizedBox(height: 12),
                    if (_photoFile != null)
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(_photoFile!, fit: BoxFit.cover),
                        ),
                      )
                    else
                      Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey[200],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[300]!),
                        ),
                        child: const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt, size: 48, color: Colors.grey),
                              SizedBox(height: 8),
                              Text('No photo captured', style: TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: _capturePhoto,
                      icon: const Icon(Icons.camera),
                      label: Text(_photoFile == null ? 'Capture Photo' : 'Retake Photo'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
            // Submit Button
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitForm,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[700],
                    foregroundColor: Colors.white,
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Register Beneficiary',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Multi-select category checkboxes
  Widget _buildCategoryCheckboxes() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: VulnerableCategory.values.map((category) {
            return CheckboxListTile(
              title: Text(category.label),
              subtitle: _getCategoryDescription(category),
              value: _selectedCategories.contains(category.value),
              onChanged: (bool? value) {
                setState(() {
                  if (value == true) {
                    _selectedCategories.add(category.value);
                    // Auto-set pregnant flag
                    if (category == VulnerableCategory.pregnantWoman) {
                      _isPregnant = true;
                    }
                  } else {
                    _selectedCategories.remove(category.value);
                    if (category == VulnerableCategory.pregnantWoman) {
                      _isPregnant = false;
                      _pregnancyTrimester = null;
                    }
                  }
                });
              },
              activeColor: Colors.blue[700],
              dense: true,
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget? _getCategoryDescription(VulnerableCategory category) {
    switch (category) {
      case VulnerableCategory.pregnantWoman:
        return const Text('Currently pregnant', style: TextStyle(fontSize: 12));
      case VulnerableCategory.lactatingMother:
        return const Text('Breastfeeding mother', style: TextStyle(fontSize: 12));
      case VulnerableCategory.childUnder5:
        return const Text('Has children under 5 years', style: TextStyle(fontSize: 12));
      case VulnerableCategory.elderly:
        return const Text('Age 60 years or older', style: TextStyle(fontSize: 12));
      case VulnerableCategory.disabled:
        return const Text('Physical, visual, hearing, or intellectual disability', style: TextStyle(fontSize: 12));
      case VulnerableCategory.chronicallyIll:
        return const Text('HIV/AIDS, TB, diabetes, heart disease, etc.', style: TextStyle(fontSize: 12));
    }
  }

  // Pregnant Woman specific fields
  Widget _buildPregnantWomanFields() {
    return Card(
      color: Colors.pink[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pregnant_woman, color: Colors.pink[700]),
                const SizedBox(width: 8),
                Text('Pregnancy Details', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink[700])),
              ],
            ),
            const SizedBox(height: 12),
            _buildDropdown<int>(
              value: _pregnancyTrimester,
              label: 'Pregnancy Trimester *',
              items: [1, 2, 3].map((t) => DropdownMenuItem(value: t, child: Text('Trimester $t'))).toList(),
              onChanged: (value) => setState(() => _pregnancyTrimester = value),
            ),
          ],
        ),
      ),
    );
  }

  // Child Under 5 specific fields
  Widget _buildChildUnder5Fields() {
    return Card(
      color: Colors.orange[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.child_care, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Text('Children Under 5', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[700])),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: TextEditingController(text: _childrenUnder5Count.toString()),
              label: 'Number of Children Under 5',
              icon: Icons.child_friendly,
              keyboardType: TextInputType.number,
              onChanged: (value) {
                final count = int.tryParse(value) ?? 0;
                setState(() => _childrenUnder5Count = count.clamp(0, 10));
                _updateChildrenAgeControllers();
              },
            ),
            if (_childrenUnder5Count > 0) ...[
              const SizedBox(height: 12),
              const Text('Enter each child\'s age in months:', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              ...List.generate(_childrenUnder5Count, (index) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: _buildTextField(
                    controller: _childrenAgeControllers[index],
                    label: 'Child ${index + 1} Age (months)',
                    icon: Icons.child_friendly,
                    keyboardType: TextInputType.number,
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  // Elderly specific fields
  Widget _buildElderlyFields() {
    return Card(
      color: Colors.purple[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.elderly, color: Colors.purple[700]),
                const SizedBox(width: 8),
                Text('Elderly (60+) Details', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple[700])),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Living Alone?'),
              subtitle: const Text('No family members in household'),
              value: _isLivingAlone,
              onChanged: (value) => setState(() => _isLivingAlone = value),
              dense: true,
            ),
            SwitchListTile(
              title: const Text('Has Caregiver?'),
              subtitle: const Text('Someone regularly helps with daily activities'),
              value: _hasCaregiver,
              onChanged: (value) => setState(() => _hasCaregiver = value),
              dense: true,
            ),
            const SizedBox(height: 12),
            _buildDropdown<String>(
              value: _mobilityLevel,
              label: 'Mobility Level *',
              items: MobilityLevel.values.map((m) {
                return DropdownMenuItem(value: m.value, child: Text(m.label));
              }).toList(),
              onChanged: (value) => setState(() => _mobilityLevel = value!),
            ),
          ],
        ),
      ),
    );
  }

  // Disabled specific fields
  Widget _buildDisabledFields() {
    return Card(
      color: Colors.teal[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.accessible, color: Colors.teal[700]),
                const SizedBox(width: 8),
                Text('Disability Details', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal[700])),
              ],
            ),
            const SizedBox(height: 12),
            _buildDropdown<String>(
              value: _disabilityType,
              label: 'Disability Type *',
              items: DisabilityType.values.map((d) {
                return DropdownMenuItem(value: d.value, child: Text(d.label));
              }).toList(),
              onChanged: (value) => setState(() => _disabilityType = value!),
            ),
            const SizedBox(height: 12),
            _buildDropdown<String>(
              value: _disabilitySeverity,
              label: 'Disability Severity *',
              items: DisabilitySeverity.values.map((d) {
                return DropdownMenuItem(value: d.value, child: Text(d.label));
              }).toList(),
              onChanged: (value) => setState(() => _disabilitySeverity = value!),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Uses Assistive Device?'),
              subtitle: const Text('Wheelchair, crutches, hearing aid, etc.'),
              value: _usesAssistiveDevice,
              onChanged: (value) => setState(() => _usesAssistiveDevice = value),
              dense: true,
            ),
            SwitchListTile(
              title: const Text('Needs Personal Assistance?'),
              subtitle: const Text('Requires help with daily activities'),
              value: _needsPersonalAssistance,
              onChanged: (value) => setState(() => _needsPersonalAssistance = value),
              dense: true,
            ),
          ],
        ),
      ),
    );
  }

  // Chronically Ill specific fields
  Widget _buildChronicallyIllFields() {
    return Card(
      color: Colors.red[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medical_services, color: Colors.red[700]),
                const SizedBox(width: 8),
                Text('Chronic Illness Details', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[700])),
              ],
            ),
            const SizedBox(height: 12),
            _buildDropdown<String>(
              value: _chronicIllnessType,
              label: 'Illness Type *',
              items: ChronicIllnessType.values.map((c) {
                return DropdownMenuItem(value: c.value, child: Text(c.label));
              }).toList(),
              onChanged: (value) => setState(() => _chronicIllnessType = value!),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Currently On Medication?'),
              subtitle: const Text('Taking prescribed medication regularly'),
              value: _isOnMedication,
              onChanged: (value) => setState(() => _isOnMedication = value),
              dense: true,
            ),
            SwitchListTile(
              title: const Text('Needs Regular Medical Care?'),
              subtitle: const Text('Requires frequent hospital/clinic visits'),
              value: _needsRegularMedicalCare,
              onChanged: (value) => setState(() => _needsRegularMedicalCare = value),
              dense: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue[700]),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[800]),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String label,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    String? Function(T?)? validator,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        filled: true,
        fillColor: Colors.white,
      ),
      items: items,
      onChanged: onChanged,
      validator: validator,
    );
  }
}

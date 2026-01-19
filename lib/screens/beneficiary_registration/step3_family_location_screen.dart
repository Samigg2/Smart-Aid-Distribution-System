import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;
import '../../models/beneficiary_model.dart';
import '../../models/beneficiary_registration_data.dart';
import '../../providers/beneficiary_provider.dart';
import '../../providers/priority_model_ai_provider.dart';
import '../../utils/logger.dart';
import '../beneficiary_list_screen.dart';

class Step3FamilyLocationScreen extends ConsumerStatefulWidget {
  final BeneficiaryRegistrationData data;
  final VoidCallback onBack;

  const Step3FamilyLocationScreen({
    super.key,
    required this.data,
    required this.onBack,
  });

  @override
  ConsumerState<Step3FamilyLocationScreen> createState() =>
      _Step3FamilyLocationScreenState();
}

class _Step3FamilyLocationScreenState
    extends ConsumerState<Step3FamilyLocationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _familySizeController = TextEditingController();
  final _zoneController = TextEditingController();
  final _woredaController = TextEditingController();
  bool _isLoading = false;

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
  void initState() {
    super.initState();
    _familySizeController.text = widget.data.totalFamilySize.toString();
    _zoneController.text = widget.data.zone ?? '';
    _woredaController.text = widget.data.woreda ?? '';
  }

  @override
  void dispose() {
    _familySizeController.dispose();
    _zoneController.dispose();
    super.dispose();
  }

  Future<void> _capturePhoto() async {
    try {
      if (kIsWeb) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Photo capture is not supported in the web version. Please use the mobile app for photos.',
            ),
          ),
        );
        return;
      }

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
          widget.data.photoFile = permanentFile;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error capturing photo: $e')));
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
          const SnackBar(
            content: Text('Location permission permanently denied'),
          ),
        );
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        widget.data.latitude = position.latitude;
        widget.data.longitude = position.longitude;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Location: ${widget.data.latitude!.toStringAsFixed(6)}, ${widget.data.longitude!.toStringAsFixed(6)}',
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all required fields')),
      );
      return;
    }

    final errors = widget.data.validateStep3();
    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errors.first), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not logged in');
      }

      // Update data from controllers
      widget.data.totalFamilySize =
          int.tryParse(_familySizeController.text) ?? 1;
      widget.data.zone = _zoneController.text.trim().isEmpty
          ? null
          : _zoneController.text.trim();
      widget.data.woreda = _woredaController.text.trim().isEmpty
          ? null
          : _woredaController.text.trim();

      // Upload photo to Cloudinary if provided (OPTIONAL)
      if (widget.data.photoFile != null) {
        final cloudinaryService = ref.read(cloudinaryServiceProvider);
        widget.data.photoUrl = await cloudinaryService.uploadBeneficiaryPhoto(
          widget.data.photoFile!,
        );
      }

      // Calculate rule-based urgency score (always works)
      final double ruleUrgencyScore = BeneficiaryModel.calculateUrgencyScore(
        vulnerableCategories: widget.data.selectedCategories.toList(),
        isPregnant: widget.data.isPregnant,
        pregnancyTrimester: widget.data.pregnancyTrimester,
        childrenUnder5Count: widget.data.childrenUnder5Count,
        childrenAges: widget.data.childrenAges,
        isFemaleHeadedHousehold: widget.data.isFemaleHeadedHousehold,
        incomeLevel: widget.data.incomeLevel,
        currentlyReceivingOtherAid: widget.data.currentlyReceivingOtherAid,
        isLivingAlone: widget.data.isLivingAlone,
        mobilityLevel: widget.data.mobilityLevel,
        disabilitySeverity: widget.data.disabilitySeverity,
        needsPersonalAssistance: widget.data.needsPersonalAssistance,
        needsRegularMedicalCare: widget.data.needsRegularMedicalCare,
      );

      // Optional AI scoring (safe fallback if API is not configured/reachable)
      double finalUrgencyScore =
          ruleUrgencyScore; // Default = rule-based (safe fallback)
      String? aiPriorityLabel; // Store for display/logging
      double? aiConfidence;

      try {
        final priorityModelAiService = ref.read(priorityModelAiServiceProvider);
        final aiPrediction = await priorityModelAiService.predictPriority(
          age: widget.data.age ?? 0,
          gender: widget.data.gender,
          income: widget.data.incomeLevel,
          disability: widget.data.selectedCategories.contains('disabled')
              ? 'Yes'
              : 'No',
          dependents: widget.data.childrenUnder5Count,
          description:
              '${widget.data.fullName ?? ''} ${widget.data.selectedCategories.join(", ")} ${widget.data.region}',
        );

        if (aiPrediction != null) {
          // Convert AI priority string ("high"/"medium"/"low") to urgency score number
          final double aiUrgencyScore = switch (aiPrediction.priority
              .toLowerCase()) {
            'high' => 0.85,
            'low' => 0.20,
            'medium' => 0.55,
            _ => 0.55, // Default to medium if unexpected value
          };

          // Blend: 70% rule-based score + 30% AI score
          finalUrgencyScore = (0.70 * ruleUrgencyScore + 0.30 * aiUrgencyScore)
              .clamp(0.0, 1.0);

          // Store for potential display/logging
          aiPriorityLabel = aiPrediction.priority
              .toUpperCase(); // "HIGH", "MEDIUM", "LOW"
          aiConfidence = aiPrediction.confidence;

          Logger.info(
            'AI Priority: ${aiPriorityLabel} (confidence: ${(aiConfidence * 100).toStringAsFixed(1)}%), '
            'Rule Score: ${(ruleUrgencyScore * 100).toStringAsFixed(1)}%, '
            'Final Score: ${(finalUrgencyScore * 100).toStringAsFixed(1)}%',
            tag: 'BeneficiaryRegistration',
          );
        } else {
          Logger.warning(
            'AI prediction returned null - using rule-based score only',
            tag: 'BeneficiaryRegistration',
          );
        }
      } catch (e) {
        // AI call failed - silently fallback to rule-based (no error shown to user)
        Logger.warning(
          'AI priority prediction failed, using rule-based score: $e',
          tag: 'BeneficiaryRegistration',
        );
        // finalUrgencyScore already = ruleUrgencyScore (safe fallback)
      }

      // Create beneficiary model
      final beneficiary = BeneficiaryModel(
        beneficiaryId: '',
        fullName: widget.data.fullName!,
        nationalId: widget.data.nationalId!,
        phoneNumber: widget.data.phoneNumber,
        age: widget.data.age,
        gender: widget.data.gender,
        vulnerableCategories: widget.data.selectedCategories.toList(),
        beneficiaryType: widget.data.selectedCategories.isNotEmpty
            ? widget.data.selectedCategories.first
            : null,
        isPregnant: widget.data.isPregnant,
        pregnancyTrimester: widget.data.isPregnant
            ? widget.data.pregnancyTrimester
            : null,
        childrenUnder5Count: widget.data.childrenUnder5Count,
        childrenAges: widget.data.childrenAges,
        isLivingAlone: widget.data.isLivingAlone,
        hasCaregiver: widget.data.hasCaregiver,
        mobilityLevel: widget.data.selectedCategories.contains('elderly')
            ? widget.data.mobilityLevel
            : null,
        disabilityType: widget.data.selectedCategories.contains('disabled')
            ? widget.data.disabilityType
            : null,
        disabilitySeverity: widget.data.selectedCategories.contains('disabled')
            ? widget.data.disabilitySeverity
            : null,
        usesAssistiveDevice: widget.data.usesAssistiveDevice,
        needsPersonalAssistance: widget.data.needsPersonalAssistance,
        chronicIllnessType:
            widget.data.selectedCategories.contains('chronically_ill')
            ? widget.data.chronicIllnessType
            : null,
        isOnMedication: widget.data.isOnMedication,
        needsRegularMedicalCare: widget.data.needsRegularMedicalCare,
        totalFamilySize: widget.data.totalFamilySize,
        isFemaleHeadedHousehold: widget.data.isFemaleHeadedHousehold,
        incomeLevel: widget.data.incomeLevel,
        currentlyReceivingOtherAid: widget.data.currentlyReceivingOtherAid,
        region: widget.data.region,
        zone: widget.data.zone,
        woreda: widget.data.woreda,
        latitude: widget.data.latitude,
        longitude: widget.data.longitude,
        photoUrl: widget.data.photoUrl,
        registeredBy: currentUser.uid,
        createdAt: DateTime.now(),
        urgencyScore:
            finalUrgencyScore, // Uses blended score (AI + rule) or rule-only if AI fails
      );

      // Save to Firestore
      final beneficiaryService = ref.read(beneficiaryServiceProvider);
      final beneficiaryId = await beneficiaryService.createBeneficiary(
        beneficiary,
      );

      if (beneficiaryId != null && mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const BeneficiaryListScreen(),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader('Family & Vulnerability', Icons.home),
                  _buildTextField(
                    controller: _familySizeController,
                    label: 'Total Family Size *',
                    icon: Icons.people,
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Is Female-Headed Household?'),
                    value: widget.data.isFemaleHeadedHousehold,
                    onChanged: (value) => setState(
                      () => widget.data.isFemaleHeadedHousehold = value,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildDropdown<String>(
                    value: widget.data.incomeLevel,
                    label: 'Monthly Family Income *',
                    items: IncomeLevel.values.map((level) {
                      return DropdownMenuItem(
                        value: level.value,
                        child: Text(level.label),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => widget.data.incomeLevel = value!),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Currently Receiving Other Aid?'),
                    value: widget.data.currentlyReceivingOtherAid,
                    onChanged: (value) => setState(
                      () => widget.data.currentlyReceivingOtherAid = value,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Location', Icons.location_on),
                  _buildDropdown<String>(
                    value: widget.data.region,
                    label: 'Region *',
                    items: _regions.map((region) {
                      return DropdownMenuItem(
                        value: region,
                        child: Text(region),
                      );
                    }).toList(),
                    onChanged: (value) =>
                        setState(() => widget.data.region = value!),
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
                      widget.data.latitude != null &&
                              widget.data.longitude != null
                          ? 'GPS: ${widget.data.latitude!.toStringAsFixed(4)}, ${widget.data.longitude!.toStringAsFixed(4)}'
                          : 'Capture GPS Coordinates',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader('Photo (Optional)', Icons.camera_alt),
                  const Text(
                    'Photo is optional but recommended for identification',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  if (widget.data.photoFile != null)
                    Container(
                      height: 200,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          widget.data.photoFile!,
                          fit: BoxFit.cover,
                        ),
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
                            Icon(
                              Icons.camera_alt,
                              size: 48,
                              color: Colors.grey,
                            ),
                            SizedBox(height: 8),
                            Text(
                              'No photo captured',
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: _capturePhoto,
                    icon: const Icon(Icons.camera),
                    label: Text(
                      widget.data.photoFile == null
                          ? 'Capture Photo'
                          : 'Retake Photo',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue[700],
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 50),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: widget.onBack,
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitForm,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green[700],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Register Beneficiary',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
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
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[800],
            ),
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
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
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
    );
  }
}

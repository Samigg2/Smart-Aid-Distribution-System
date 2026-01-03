import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/beneficiary_model.dart';
import '../../models/beneficiary_registration_data.dart';

class Step2CategoryDetailsScreen extends ConsumerStatefulWidget {
  final BeneficiaryRegistrationData data;
  final VoidCallback onNext;
  final VoidCallback onBack;

  const Step2CategoryDetailsScreen({
    super.key,
    required this.data,
    required this.onNext,
    required this.onBack,
  });

  @override
  ConsumerState<Step2CategoryDetailsScreen> createState() => _Step2CategoryDetailsScreenState();
}

class _Step2CategoryDetailsScreenState extends ConsumerState<Step2CategoryDetailsScreen> {
  final List<TextEditingController> _childrenAgeControllers = [];
  late TextEditingController _childrenCountController;

  @override
  void initState() {
    super.initState();
    _childrenCountController = TextEditingController(
      text: widget.data.childrenUnder5Count.toString(),
    );
    _updateChildrenAgeControllers();
  }

  @override
  void dispose() {
    _childrenCountController.dispose();
    for (var controller in _childrenAgeControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _updateChildrenAgeControllers() {
    while (_childrenAgeControllers.length > widget.data.childrenUnder5Count) {
      _childrenAgeControllers.removeLast().dispose();
    }
    while (_childrenAgeControllers.length < widget.data.childrenUnder5Count) {
      _childrenAgeControllers.add(TextEditingController());
    }
    setState(() {});
  }

  void _handleNext() {
    final errors = widget.data.validateStep2();
    if (errors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errors.first),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Collect children ages
    widget.data.childrenAges.clear();
    for (var controller in _childrenAgeControllers) {
      final age = int.tryParse(controller.text);
      if (age != null && age > 0) {
        widget.data.childrenAges.add(age);
      }
    }

    widget.onNext();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader('Category-Specific Details', Icons.info),
                const Text(
                  'Please provide details for the selected categories:',
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
                const SizedBox(height: 16),
                if (widget.data.selectedCategories.contains('pregnant_woman'))
                  _buildPregnantWomanFields(),
                if (widget.data.selectedCategories.contains('child_under_5'))
                  _buildChildUnder5Fields(),
                if (widget.data.selectedCategories.contains('elderly'))
                  _buildElderlyFields(),
                if (widget.data.selectedCategories.contains('disabled'))
                  _buildDisabledFields(),
                if (widget.data.selectedCategories.contains('chronically_ill'))
                  _buildChronicallyIllFields(),
                if (widget.data.selectedCategories.isEmpty)
                  const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text('No categories selected. Please go back and select at least one category.'),
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
                  onPressed: _handleNext,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('Next: Family & Location'),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPregnantWomanFields() {
    return Card(
      color: Colors.pink[50],
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pregnant_woman, color: Colors.pink[700]),
                const SizedBox(width: 8),
                Text(
                  'Pregnancy Details',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink[700]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDropdown<int>(
              value: widget.data.pregnancyTrimester,
              label: 'Pregnancy Trimester *',
              items: [1, 2, 3].map((t) => DropdownMenuItem(value: t, child: Text('Trimester $t'))).toList(),
              onChanged: (value) => setState(() => widget.data.pregnancyTrimester = value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChildUnder5Fields() {
    return Card(
      color: Colors.orange[50],
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.child_care, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Text(
                  'Children Under 5',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange[700]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildTextField(
              controller: _childrenCountController,
              label: 'Number of Children Under 5',
              icon: Icons.child_friendly,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              onChanged: (value) {
                final count = int.tryParse(value) ?? 0;
                final clampedCount = count.clamp(0, 10);
                if (widget.data.childrenUnder5Count != clampedCount) {
                  setState(() {
                    widget.data.childrenUnder5Count = clampedCount;
                    _updateChildrenAgeControllers();
                  });
                }
              },
            ),
            if (widget.data.childrenUnder5Count > 0) ...[
              const SizedBox(height: 12),
              const Text('Enter each child\'s age in months:', style: TextStyle(fontSize: 12)),
              const SizedBox(height: 8),
              ...List.generate(widget.data.childrenUnder5Count, (index) {
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

  Widget _buildElderlyFields() {
    return Card(
      color: Colors.purple[50],
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.elderly, color: Colors.purple[700]),
                const SizedBox(width: 8),
                Text(
                  'Elderly (60+) Details',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.purple[700]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Living Alone?'),
              subtitle: const Text('No family members in household'),
              value: widget.data.isLivingAlone,
              onChanged: (value) => setState(() => widget.data.isLivingAlone = value),
              dense: true,
            ),
            SwitchListTile(
              title: const Text('Has Caregiver?'),
              subtitle: const Text('Someone regularly helps with daily activities'),
              value: widget.data.hasCaregiver,
              onChanged: (value) => setState(() => widget.data.hasCaregiver = value),
              dense: true,
            ),
            const SizedBox(height: 12),
            _buildDropdown<String>(
              value: widget.data.mobilityLevel,
              label: 'Mobility Level *',
              items: MobilityLevel.values.map((m) {
                return DropdownMenuItem(value: m.value, child: Text(m.label));
              }).toList(),
              onChanged: (value) => setState(() => widget.data.mobilityLevel = value!),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDisabledFields() {
    return Card(
      color: Colors.teal[50],
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.accessible, color: Colors.teal[700]),
                const SizedBox(width: 8),
                Text(
                  'Disability Details',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal[700]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDropdown<String>(
              value: widget.data.disabilityType,
              label: 'Disability Type *',
              items: DisabilityType.values.map((d) {
                return DropdownMenuItem(value: d.value, child: Text(d.label));
              }).toList(),
              onChanged: (value) => setState(() => widget.data.disabilityType = value!),
            ),
            const SizedBox(height: 12),
            _buildDropdown<String>(
              value: widget.data.disabilitySeverity,
              label: 'Disability Severity *',
              items: DisabilitySeverity.values.map((d) {
                return DropdownMenuItem(value: d.value, child: Text(d.label));
              }).toList(),
              onChanged: (value) => setState(() => widget.data.disabilitySeverity = value!),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Uses Assistive Device?'),
              subtitle: const Text('Wheelchair, crutches, hearing aid, etc.'),
              value: widget.data.usesAssistiveDevice,
              onChanged: (value) => setState(() => widget.data.usesAssistiveDevice = value),
              dense: true,
            ),
            SwitchListTile(
              title: const Text('Needs Personal Assistance?'),
              subtitle: const Text('Requires help with daily activities'),
              value: widget.data.needsPersonalAssistance,
              onChanged: (value) => setState(() => widget.data.needsPersonalAssistance = value),
              dense: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChronicallyIllFields() {
    return Card(
      color: Colors.red[50],
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.medical_services, color: Colors.red[700]),
                const SizedBox(width: 8),
                Text(
                  'Chronic Illness Details',
                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red[700]),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildDropdown<String>(
              value: widget.data.chronicIllnessType,
              label: 'Illness Type *',
              items: ChronicIllnessType.values.map((c) {
                return DropdownMenuItem(value: c.value, child: Text(c.label));
              }).toList(),
              onChanged: (value) => setState(() => widget.data.chronicIllnessType = value!),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('Currently On Medication?'),
              subtitle: const Text('Taking prescribed medication regularly'),
              value: widget.data.isOnMedication,
              onChanged: (value) => setState(() => widget.data.isOnMedication = value),
              dense: true,
            ),
            SwitchListTile(
              title: const Text('Needs Regular Medical Care?'),
              subtitle: const Text('Requires frequent hospital/clinic visits'),
              value: widget.data.needsRegularMedicalCare,
              onChanged: (value) => setState(() => widget.data.needsRegularMedicalCare = value),
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
    void Function(String)? onChanged,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: onChanged,
      inputFormatters: inputFormatters,
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


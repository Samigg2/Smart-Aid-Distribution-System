import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/beneficiary_model.dart';
import '../../models/beneficiary_registration_data.dart';
import '../../utils/beneficiary_validator.dart';

class Step1PersonalInfoScreen extends ConsumerStatefulWidget {
  final BeneficiaryRegistrationData data;
  final VoidCallback onNext;

  const Step1PersonalInfoScreen({
    super.key,
    required this.data,
    required this.onNext,
  });

  @override
  ConsumerState<Step1PersonalInfoScreen> createState() =>
      _Step1PersonalInfoScreenState();
}

class _Step1PersonalInfoScreenState
    extends ConsumerState<Step1PersonalInfoScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _nationalIdController = TextEditingController();
  final _phoneController = TextEditingController();
  final _ageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fullNameController.text = widget.data.fullName ?? '';
    _nationalIdController.text = widget.data.nationalId ?? '';
    _phoneController.text = widget.data.phoneNumber ?? '';
    _ageController.text = widget.data.age?.toString() ?? '';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _nationalIdController.dispose();
    _phoneController.dispose();
    _ageController.dispose();
    super.dispose();
  }

  void _handleNext() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Update data
    widget.data.fullName = _fullNameController.text.trim();
    widget.data.nationalId = _nationalIdController.text.trim();
    widget.data.phoneNumber = _phoneController.text.trim().isEmpty
        ? null
        : _phoneController.text.trim();
    widget.data.age = int.tryParse(_ageController.text);

    // Validate categories
    final categoryErrors = BeneficiaryValidator.validateAllCategories(
      widget.data.selectedCategories,
      widget.data.age,
    );

    if (categoryErrors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(categoryErrors.first),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate step 1
    final stepErrors = widget.data.validateStep1();
    if (stepErrors.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(stepErrors.first), backgroundColor: Colors.red),
      );
      return;
    }

    widget.onNext();
  }

  void _toggleCategory(VulnerableCategory category) {
    setState(() {
      final categoryValue = category.value;
      if (widget.data.selectedCategories.contains(categoryValue)) {
        widget.data.selectedCategories.remove(categoryValue);
        if (category == VulnerableCategory.pregnantWoman) {
          widget.data.isPregnant = false;
          widget.data.pregnancyTrimester = null;
        }
      } else {
        // Check for conflicts before adding
        final conflictError = BeneficiaryValidator.validateCategorySelection(
          categoryValue,
          widget.data.selectedCategories,
          widget.data.age,
        );

        if (conflictError != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(conflictError), backgroundColor: Colors.red),
          );
          return;
        }

        widget.data.selectedCategories.add(categoryValue);
        if (category == VulnerableCategory.pregnantWoman) {
          widget.data.isPregnant = true;
        }
      }
    });
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
                  _buildSectionHeader('Personal Information', Icons.person),
                  _buildTextField(
                    controller: _fullNameController,
                    label: 'Full Name *',
                    icon: Icons.badge,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
                  ),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _nationalIdController,
                    label: 'National ID Number *',
                    icon: Icons.credit_card,
                    validator: (value) =>
                        value?.isEmpty ?? true ? 'Required' : null,
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
                          onChanged: (value) {
                            final age = int.tryParse(value);
                            if (age != null) {
                              // Re-validate categories when age changes
                              final errors =
                                  BeneficiaryValidator.validateAllCategories(
                                    widget.data.selectedCategories,
                                    age,
                                  );
                              if (errors.isNotEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(errors.first),
                                    backgroundColor: Colors.orange,
                                  ),
                                );
                              }
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildDropdown<String>(
                          value: widget.data.gender,
                          label: 'Gender *',
                          items: const [
                            DropdownMenuItem(
                              value: 'female',
                              child: Text('Female'),
                            ),
                            DropdownMenuItem(
                              value: 'male',
                              child: Text('Male'),
                            ),
                          ],
                          onChanged: (value) =>
                              setState(() => widget.data.gender = value!),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _buildSectionHeader(
                    'Vulnerable Category *',
                    Icons.warning_amber,
                  ),
                  const Text(
                    'Select all that apply:',
                    style: TextStyle(color: Colors.grey, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  _buildCategoryCheckboxes(),
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
                onPressed: _handleNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                ),
                child: const Text(
                  'Next: Category Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryCheckboxes() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: VulnerableCategory.values.map((category) {
            final isSelected = widget.data.selectedCategories.contains(
              category.value,
            );
            final conflictingCategories =
                BeneficiaryValidator.getConflictingCategories(category.value);
            final hasConflict = widget.data.selectedCategories.any(
              (selected) => conflictingCategories.contains(selected),
            );

            return CheckboxListTile(
              title: Text(category.label),
              subtitle: _getCategoryDescription(category),
              value: isSelected,
              onChanged: (bool? value) => _toggleCategory(category),
              activeColor: Colors.blue[700],
              dense: true,
              enabled: !hasConflict || isSelected,
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
        return const Text(
          'Breastfeeding mother',
          style: TextStyle(fontSize: 12),
        );
      case VulnerableCategory.childUnder5:
        return const Text(
          'Has children under 5 years',
          style: TextStyle(fontSize: 12),
        );
      case VulnerableCategory.elderly:
        return const Text(
          'Age 60 years or older',
          style: TextStyle(fontSize: 12),
        );
      case VulnerableCategory.disabled:
        return const Text(
          'Physical, visual, hearing, or intellectual disability',
          style: TextStyle(fontSize: 12),
        );
      case VulnerableCategory.chronicallyIll:
        return const Text(
          'HIV/AIDS, TB, diabetes, heart disease, etc.',
          style: TextStyle(fontSize: 12),
        );
    }
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

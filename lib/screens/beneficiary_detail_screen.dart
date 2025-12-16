import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/beneficiary_model.dart';
import '../providers/beneficiary_provider.dart';
import '../widgets/qr_code_widget.dart';

class BeneficiaryDetailScreen extends ConsumerWidget {
  final String beneficiaryId;

  const BeneficiaryDetailScreen({super.key, required this.beneficiaryId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final beneficiaryAsync = ref.watch(beneficiaryByIdProvider(beneficiaryId));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Beneficiary Details'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: beneficiaryAsync.when(
        data: (beneficiary) {
          if (beneficiary == null) {
            return const Center(child: Text('Beneficiary not found'));
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Photo and Basic Info Card
                _buildHeaderCard(beneficiary),
                const SizedBox(height: 16),

                // Vulnerable Categories
                _buildCategoriesCard(beneficiary),

                // Personal Information
                _buildSectionCard('Personal Information', Icons.person, [
                  _buildInfoRow('Full Name', beneficiary.fullName),
                  _buildInfoRow('National ID', beneficiary.nationalId),
                  if (beneficiary.phoneNumber != null)
                    _buildInfoRow('Phone', beneficiary.phoneNumber!),
                  if (beneficiary.age != null)
                    _buildInfoRow('Age', '${beneficiary.age} years'),
                  _buildInfoRow('Gender', beneficiary.gender.toUpperCase()),
                ]),

                // Category-specific sections
                if (beneficiary.hasCategory(VulnerableCategory.pregnantWoman))
                  _buildPregnancyCard(beneficiary),

                if (beneficiary.hasCategory(VulnerableCategory.childUnder5) ||
                    beneficiary.childrenUnder5Count > 0)
                  _buildChildrenCard(beneficiary),

                if (beneficiary.hasCategory(VulnerableCategory.elderly))
                  _buildElderlyCard(beneficiary),

                if (beneficiary.hasCategory(VulnerableCategory.disabled))
                  _buildDisabilityCard(beneficiary),

                if (beneficiary.hasCategory(VulnerableCategory.chronicallyIll))
                  _buildChronicIllnessCard(beneficiary),

                // Family & Vulnerability
                _buildSectionCard('Family & Vulnerability', Icons.home, [
                  _buildInfoRow(
                    'Family Size',
                    beneficiary.totalFamilySize.toString(),
                  ),
                  _buildInfoRow(
                    'Female-Headed Household',
                    beneficiary.isFemaleHeadedHousehold ? 'Yes' : 'No',
                  ),
                  _buildInfoRow(
                    'Monthly Income',
                    IncomeLevel.fromValue(beneficiary.incomeLevel).label,
                  ),
                  _buildInfoRow(
                    'Receiving Other Aid',
                    beneficiary.currentlyReceivingOtherAid ? 'Yes' : 'No',
                  ),
                ]),

                // Location
                _buildSectionCard('Location', Icons.location_on, [
                  _buildInfoRow('Region', beneficiary.region),
                  if (beneficiary.zone != null)
                    _buildInfoRow('Zone', beneficiary.zone!),
                  if (beneficiary.woreda != null)
                    _buildInfoRow('Woreda', beneficiary.woreda!),
                  if (beneficiary.latitude != null &&
                      beneficiary.longitude != null)
                    _buildInfoRow(
                      'GPS Coordinates',
                      '${beneficiary.latitude!.toStringAsFixed(6)}, ${beneficiary.longitude!.toStringAsFixed(6)}',
                    ),
                ]),

                // Registration Info
                _buildSectionCard('Registration Information', Icons.info, [
                  _buildInfoRow('Beneficiary ID', beneficiary.beneficiaryId),
                  _buildInfoRow(
                    'Registered On',
                    DateFormat(
                      'MMM dd, yyyy HH:mm',
                    ).format(beneficiary.createdAt),
                  ),
                  if (beneficiary.updatedAt != null)
                    _buildInfoRow(
                      'Last Updated',
                      DateFormat(
                        'MMM dd, yyyy HH:mm',
                      ).format(beneficiary.updatedAt!),
                    ),
                  _buildInfoRow('Registered By', beneficiary.registeredBy),
                ]),
                const SizedBox(height: 16),

                // QR Code
                QRCodeWidget(
                  beneficiaryId: beneficiary.beneficiaryId,
                  nationalId: beneficiary.nationalId,
                  fullName: beneficiary.fullName,
                ),
              ],
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
              const SizedBox(height: 16),
              Text(
                'Error loading beneficiary',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BeneficiaryModel beneficiary) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child:
                  beneficiary.photoUrl != null &&
                      beneficiary.photoUrl!.isNotEmpty
                  ? Image.network(
                      beneficiary.photoUrl!,
                      width: 150,
                      height: 150,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return _buildNoPhotoPlaceholder();
                      },
                    )
                  : _buildNoPhotoPlaceholder(),
            ),
            const SizedBox(height: 16),
            Text(
              beneficiary.fullName,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'ID: ${beneficiary.nationalId}',
              style: TextStyle(fontSize: 16, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),
            _buildUrgencyBadge(beneficiary.urgencyScore),
          ],
        ),
      ),
    );
  }

  Widget _buildNoPhotoPlaceholder() {
    return Container(
      width: 150,
      height: 150,
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.person, size: 60, color: Colors.grey[600]),
          const SizedBox(height: 8),
          Text('No Photo', style: TextStyle(color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildUrgencyBadge(double urgencyScore) {
    Color bgColor;
    Color textColor;
    String label;

    if (urgencyScore > 0.7) {
      bgColor = Colors.red[100]!;
      textColor = Colors.red[700]!;
      label = 'HIGH PRIORITY';
    } else if (urgencyScore > 0.4) {
      bgColor = Colors.orange[100]!;
      textColor = Colors.orange[700]!;
      label = 'MEDIUM PRIORITY';
    } else {
      bgColor = Colors.green[100]!;
      textColor = Colors.green[700]!;
      label = 'STANDARD';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          Text(
            'Score: ${(urgencyScore * 100).toInt()}%',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesCard(BeneficiaryModel beneficiary) {
    if (beneficiary.vulnerableCategories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.category, color: Colors.blue[700]),
                const SizedBox(width: 8),
                const Text(
                  'Vulnerable Categories',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: beneficiary.categoriesAsEnum.map((category) {
                return _buildCategoryChip(category);
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryChip(VulnerableCategory category) {
    Color chipColor;
    IconData icon;

    switch (category) {
      case VulnerableCategory.pregnantWoman:
        chipColor = Colors.pink;
        icon = Icons.pregnant_woman;
        break;
      case VulnerableCategory.lactatingMother:
        chipColor = Colors.purple;
        icon = Icons.woman;
        break;
      case VulnerableCategory.childUnder5:
        chipColor = Colors.orange;
        icon = Icons.child_care;
        break;
      case VulnerableCategory.elderly:
        chipColor = Colors.indigo;
        icon = Icons.elderly;
        break;
      case VulnerableCategory.disabled:
        chipColor = Colors.teal;
        icon = Icons.accessible;
        break;
      case VulnerableCategory.chronicallyIll:
        chipColor = Colors.red;
        icon = Icons.medical_services;
        break;
    }

    return Chip(
      avatar: Icon(icon, size: 18, color: Colors.white),
      label: Text(category.label, style: const TextStyle(color: Colors.white)),
      backgroundColor: chipColor,
    );
  }

  Widget _buildPregnancyCard(BeneficiaryModel beneficiary) {
    return _buildSectionCard('Pregnancy Details', Icons.pregnant_woman, [
      _buildInfoRow('Is Pregnant', beneficiary.isPregnant ? 'Yes' : 'No'),
      if (beneficiary.isPregnant && beneficiary.pregnancyTrimester != null)
        _buildInfoRow(
          'Trimester',
          'Trimester ${beneficiary.pregnancyTrimester}',
        ),
    ], headerColor: Colors.pink[700]);
  }

  Widget _buildChildrenCard(BeneficiaryModel beneficiary) {
    return _buildSectionCard('Children Under 5', Icons.child_care, [
      _buildInfoRow(
        'Number of Children',
        beneficiary.childrenUnder5Count.toString(),
      ),
      if (beneficiary.childrenAges.isNotEmpty)
        _buildInfoRow(
          'Children Ages',
          beneficiary.childrenAges.map((age) => '$age months').join(', '),
        ),
      if (beneficiary.childrenAges.isNotEmpty)
        _buildInfoRow(
          'Youngest Child',
          '${beneficiary.youngestChildAge} months',
        ),
    ], headerColor: Colors.orange[700]);
  }

  Widget _buildElderlyCard(BeneficiaryModel beneficiary) {
    return _buildSectionCard('Elderly (60+) Details', Icons.elderly, [
      _buildInfoRow('Living Alone', beneficiary.isLivingAlone ? 'Yes' : 'No'),
      _buildInfoRow('Has Caregiver', beneficiary.hasCaregiver ? 'Yes' : 'No'),
      if (beneficiary.mobilityLevel != null)
        _buildInfoRow(
          'Mobility Level',
          MobilityLevel.fromValue(beneficiary.mobilityLevel!).label,
        ),
    ], headerColor: Colors.purple[700]);
  }

  Widget _buildDisabilityCard(BeneficiaryModel beneficiary) {
    return _buildSectionCard('Disability Details', Icons.accessible, [
      if (beneficiary.disabilityType != null)
        _buildInfoRow(
          'Disability Type',
          DisabilityType.fromValue(beneficiary.disabilityType!).label,
        ),
      if (beneficiary.disabilitySeverity != null)
        _buildInfoRow(
          'Severity',
          DisabilitySeverity.fromValue(beneficiary.disabilitySeverity!).label,
        ),
      _buildInfoRow(
        'Uses Assistive Device',
        beneficiary.usesAssistiveDevice ? 'Yes' : 'No',
      ),
      _buildInfoRow(
        'Needs Personal Assistance',
        beneficiary.needsPersonalAssistance ? 'Yes' : 'No',
      ),
    ], headerColor: Colors.teal[700]);
  }

  Widget _buildChronicIllnessCard(BeneficiaryModel beneficiary) {
    return _buildSectionCard(
      'Chronic Illness Details',
      Icons.medical_services,
      [
        if (beneficiary.chronicIllnessType != null)
          _buildInfoRow(
            'Illness Type',
            ChronicIllnessType.fromValue(beneficiary.chronicIllnessType!).label,
          ),
        _buildInfoRow(
          'On Medication',
          beneficiary.isOnMedication ? 'Yes' : 'No',
        ),
        _buildInfoRow(
          'Needs Regular Medical Care',
          beneficiary.needsRegularMedicalCare ? 'Yes' : 'No',
        ),
      ],
      headerColor: Colors.red[700],
    );
  }

  Widget _buildSectionCard(
    String title,
    IconData icon,
    List<Widget> children, {
    Color? headerColor,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: headerColor ?? Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: headerColor,
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 160,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

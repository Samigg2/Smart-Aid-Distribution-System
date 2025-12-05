import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/beneficiary_model.dart';
import '../providers/beneficiary_provider.dart';

class BeneficiaryDetailScreen extends ConsumerWidget {
  final String beneficiaryId;

  const BeneficiaryDetailScreen({
    super.key,
    required this.beneficiaryId,
  });

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
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: beneficiary.photoUrl.isNotEmpty
                              ? Image.network(
                                  beneficiary.photoUrl,
                                  width: 150,
                                  height: 150,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      width: 150,
                                      height: 150,
                                      color: Colors.grey[300],
                                      child: const Icon(Icons.person, size: 60),
                                    );
                                  },
                                )
                              : Container(
                                  width: 150,
                                  height: 150,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.person, size: 60),
                                ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          beneficiary.fullName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ID: ${beneficiary.nationalId}',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: beneficiary.urgencyScore > 0.7
                                ? Colors.red[100]
                                : beneficiary.urgencyScore > 0.4
                                    ? Colors.orange[100]
                                    : Colors.green[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Urgency Score: ${(beneficiary.urgencyScore * 100).toInt()}%',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: beneficiary.urgencyScore > 0.7
                                  ? Colors.red[700]
                                  : beneficiary.urgencyScore > 0.4
                                      ? Colors.orange[700]
                                      : Colors.green[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Personal Information
                _buildSectionCard(
                  'Personal Information',
                  Icons.person,
                  [
                    _buildInfoRow('Full Name', beneficiary.fullName),
                    _buildInfoRow('National ID', beneficiary.nationalId),
                    if (beneficiary.phoneNumber != null)
                      _buildInfoRow('Phone', beneficiary.phoneNumber!),
                    if (beneficiary.age != null)
                      _buildInfoRow('Age', beneficiary.age.toString()),
                    _buildInfoRow('Gender', beneficiary.gender),
                  ],
                ),

                // Mother & Child Status
                _buildSectionCard(
                  'Mother & Child Status',
                  Icons.family_restroom,
                  [
                    _buildInfoRow(
                      'Beneficiary Type',
                      BeneficiaryType.values
                          .firstWhere((t) => t.value == beneficiary.beneficiaryType)
                          .label,
                    ),
                    _buildInfoRow(
                      'Is Pregnant',
                      beneficiary.isPregnant ? 'Yes' : 'No',
                    ),
                    if (beneficiary.isPregnant && beneficiary.pregnancyTrimester != null)
                      _buildInfoRow(
                        'Trimester',
                        'Trimester ${beneficiary.pregnancyTrimester}',
                      ),
                    _buildInfoRow(
                      'Children Under 5',
                      beneficiary.childrenUnder5Count.toString(),
                    ),
                    if (beneficiary.childrenAges.isNotEmpty)
                      _buildInfoRow(
                        'Children Ages',
                        beneficiary.childrenAges
                            .map((age) => '$age months')
                            .join(', '),
                      ),
                    _buildInfoRow(
                      'Youngest Child',
                      '${beneficiary.youngestChildAge} months',
                    ),
                  ],
                ),

                // Family & Vulnerability
                _buildSectionCard(
                  'Family & Vulnerability',
                  Icons.home,
                  [
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
                      IncomeLevel.values
                          .firstWhere((l) => l.value == beneficiary.incomeLevel)
                          .label,
                    ),
                    _buildInfoRow(
                      'Receiving Other Aid',
                      beneficiary.currentlyReceivingOtherAid ? 'Yes' : 'No',
                    ),
                  ],
                ),

                // Location
                _buildSectionCard(
                  'Location',
                  Icons.location_on,
                  [
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
                  ],
                ),

                // Registration Info
                _buildSectionCard(
                  'Registration Information',
                  Icons.info,
                  [
                    _buildInfoRow(
                      'Registered On',
                      DateFormat('MMM dd, yyyy HH:mm')
                          .format(beneficiary.createdAt),
                    ),
                    if (beneficiary.updatedAt != null)
                      _buildInfoRow(
                        'Last Updated',
                        DateFormat('MMM dd, yyyy HH:mm')
                            .format(beneficiary.updatedAt!),
                      ),
                  ],
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

  Widget _buildSectionCard(String title, IconData icon, List<Widget> children) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blue[700]),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
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
            width: 140,
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
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}




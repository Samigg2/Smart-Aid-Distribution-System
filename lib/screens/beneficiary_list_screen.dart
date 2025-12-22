import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/beneficiary_model.dart';
import '../providers/beneficiary_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/logger.dart';
import 'beneficiary_registration/registration_flow_screen.dart';
import 'beneficiary_detail_screen.dart';

class BeneficiaryListScreen extends ConsumerStatefulWidget {
  const BeneficiaryListScreen({super.key});

  @override
  ConsumerState<BeneficiaryListScreen> createState() =>
      _BeneficiaryListScreenState();
}

class _BeneficiaryListScreenState extends ConsumerState<BeneficiaryListScreen> {
  String _searchQuery = '';
  String? _filterRegion;
  String? _filterType;

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;
    final userDataAsync = ref.watch(currentUserDataStreamProvider);
    
    // Determine which provider to use based on user role
    final isAdminUser = userDataAsync.value?.isAdmin ?? false;
    final beneficiariesAsync = isAdminUser
        ? ref.watch(allBeneficiariesProvider) // Admin sees all
        : currentUser != null
            ? ref.watch(beneficiariesByStaffProvider(currentUser.uid)) // Staff sees own
            : ref.watch(allBeneficiariesProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Beneficiaries'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RegistrationFlowScreen(),
                ),
              );
            },
            tooltip: 'Register New',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search and Filters
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search by name or national ID...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[100],
                  ),
                  onChanged: (value) {
                    setState(() => _searchQuery = value.toLowerCase());
                  },
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filterRegion,
                        decoration: InputDecoration(
                          labelText: 'Filter by Region',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Regions'),
                          ),
                          ...[
                            'Addis Ababa',
                            'Oromia',
                            'Amhara',
                            'Tigray',
                            'SNNPR',
                          ].map(
                            (region) => DropdownMenuItem(
                              value: region,
                              child: Text(region),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _filterRegion = value),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filterType,
                        decoration: InputDecoration(
                          labelText: 'Filter by Type',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.grey[100],
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('All Types'),
                          ),
                          ...VulnerableCategory.values.map((type) {
                            return DropdownMenuItem(
                              value: type.value,
                              child: Text(type.label),
                            );
                          }),
                        ],
                        onChanged: (value) =>
                            setState(() => _filterType = value),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Beneficiaries List
          Expanded(
            child: beneficiariesAsync.when(
              data: (beneficiaries) {
                // Apply filters
                var filtered = beneficiaries;
                if (_searchQuery.isNotEmpty) {
                  filtered = filtered.where((b) {
                    return b.fullName.toLowerCase().contains(_searchQuery) ||
                        b.nationalId.contains(_searchQuery);
                  }).toList();
                }
                if (_filterRegion != null) {
                  filtered = filtered
                      .where((b) => b.region == _filterRegion)
                      .toList();
                }
                if (_filterType != null) {
                  filtered = filtered
                      .where((b) => b.vulnerableCategories.contains(_filterType))
                      .toList();
                }

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 60,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No beneficiaries found',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Sort by urgency score (highest first)
                filtered.sort(
                  (a, b) => b.urgencyScore.compareTo(a.urgencyScore),
                );

                return RefreshIndicator(
                  onRefresh: () async {
                    final userData = ref.read(currentUserDataStreamProvider).value;
                    final isAdminCheck = userData?.isAdmin ?? false;
                    if (isAdminCheck) {
                      ref.invalidate(allBeneficiariesProvider);
                    } else if (currentUser != null) {
                      ref.invalidate(
                        beneficiariesByStaffProvider(currentUser.uid),
                      );
                    }
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16.0),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      return _buildBeneficiaryCard(filtered[index]);
                    },
                  ),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (error, stack) {
                Logger.error('Error loading beneficiaries', error: error, stackTrace: stack, tag: 'BeneficiaryListScreen');
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 60, color: Colors.red[300]),
                        const SizedBox(height: 16),
                        Text(
                          'Error loading beneficiaries',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          error.toString(),
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            final userData = ref.read(currentUserDataStreamProvider).value;
                            final isAdminUser = userData?.isAdmin ?? false;
                            if (isAdminUser) {
                              ref.invalidate(allBeneficiariesProvider);
                            } else if (currentUser != null) {
                              ref.invalidate(
                                beneficiariesByStaffProvider(currentUser.uid),
                              );
                            } else {
                              ref.invalidate(allBeneficiariesProvider);
                            }
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBeneficiaryCard(BeneficiaryModel beneficiary) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => BeneficiaryDetailScreen(
                beneficiaryId: beneficiary.beneficiaryId,
              ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              // Photo
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: beneficiary.photoUrl != null && beneficiary.photoUrl!.isNotEmpty
                    ? Image.network(
                        beneficiary.photoUrl!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 60,
                            height: 60,
                            color: Colors.grey[300],
                            child: const Icon(Icons.person),
                          );
                        },
                      )
                    : Container(
                        width: 60,
                        height: 60,
                        color: Colors.grey[300],
                        child: const Icon(Icons.person),
                      ),
              ),
              const SizedBox(width: 12),
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      beneficiary.fullName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: ${beneficiary.nationalId}',
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          beneficiary.region,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Urgency Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: beneficiary.urgencyScore > 0.7
                      ? Colors.red[100]
                      : beneficiary.urgencyScore > 0.4
                      ? Colors.orange[100]
                      : Colors.green[100],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${(beneficiary.urgencyScore * 100).toInt()}%',
                  style: TextStyle(
                    fontSize: 12,
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
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/distribution_model.dart';
import '../../models/beneficiary_model.dart';
import '../../providers/distribution_provider.dart';
import '../../providers/auth_provider.dart';
import 'distribute_aid_screen.dart';

class ProgramDetailScreen extends ConsumerStatefulWidget {
  final String programId;

  const ProgramDetailScreen({super.key, required this.programId});

  @override
  ConsumerState<ProgramDetailScreen> createState() => _ProgramDetailScreenState();
}

class _ProgramDetailScreenState extends ConsumerState<ProgramDetailScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final programAsync = ref.watch(programByIdProvider(widget.programId));
    final userDataAsync = ref.watch(currentUserDataStreamProvider);
    final isAdmin = userDataAsync.value?.isAdmin ?? false;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Program Details'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Eligible', icon: Icon(Icons.people, size: 20)),
            Tab(text: 'Distributed', icon: Icon(Icons.check_circle, size: 20)),
          ],
        ),
        actions: [
          if (isAdmin)
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(value),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'pause', child: Text('Pause Program')),
                const PopupMenuItem(value: 'complete', child: Text('Mark Completed')),
                const PopupMenuItem(value: 'cancel', child: Text('Cancel Program')),
              ],
            ),
        ],
      ),
      body: programAsync.when(
        data: (program) {
          if (program == null) {
            return const Center(child: Text('Program not found'));
          }
          return Column(
            children: [
              // Program Info Header
              _buildProgramHeader(program),
              // Tabs Content
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildEligibleTab(program),
                    _buildDistributedTab(program),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildProgramHeader(DistributionProgram program) {
    final aidType = AidType.fromValue(program.aidType);
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green[50],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_getAidTypeIcon(aidType), color: Colors.green[700], size: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      program.programName,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(aidType.label, style: TextStyle(color: Colors.grey[600])),
                  ],
                ),
              ),
              _buildStatusBadge(program.status),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStat('${program.distributedCount}', 'Distributed'),
              _buildStat('${program.quantityPerBeneficiary} ${program.unit}', 'Per Person'),
              _buildStat(
                DateFormat('MMM dd').format(program.startDate),
                'Started',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildStatusBadge(String status) {
    Color color;
    switch (status) {
      case 'active':
        color = Colors.green;
        break;
      case 'paused':
        color = Colors.orange;
        break;
      case 'completed':
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buildEligibleTab(DistributionProgram program) {
    final eligibleAsync = ref.watch(eligibleBeneficiariesProvider(program));

    return eligibleAsync.when(
      data: (beneficiaries) {
        if (beneficiaries.isEmpty) {
          return const Center(
            child: Text('No eligible beneficiaries found'),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: beneficiaries.length,
          itemBuilder: (context, index) {
            return _buildBeneficiaryCard(beneficiaries[index], program);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildBeneficiaryCard(BeneficiaryModel beneficiary, DistributionProgram program) {
    final hasReceivedAsync = ref.watch(
      hasAlreadyReceivedProvider((
        programId: program.programId,
        beneficiaryId: beneficiary.beneficiaryId,
      )),
    );

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green[100],
          child: Text(beneficiary.fullName[0].toUpperCase()),
        ),
        title: Text(beneficiary.fullName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${beneficiary.nationalId}'),
            Wrap(
              spacing: 4,
              children: beneficiary.vulnerableCategories.take(2).map((cat) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _getCategoryLabel(cat),
                    style: TextStyle(fontSize: 10, color: Colors.blue[700]),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
        trailing: hasReceivedAsync.when(
          data: (hasReceived) {
            if (hasReceived) {
              return Chip(
                label: const Text('Received'),
                backgroundColor: Colors.green[100],
                labelStyle: TextStyle(color: Colors.green[700], fontSize: 12),
              );
            }
            return ElevatedButton(
              onPressed: program.isActive
                  ? () => _navigateToDistribute(beneficiary, program)
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
              ),
              child: const Text('Distribute'),
            );
          },
          loading: () => const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          error: (_, __) => const Icon(Icons.error, color: Colors.red),
        ),
        isThreeLine: true,
      ),
    );
  }

  Widget _buildDistributedTab(DistributionProgram program) {
    final distributionsAsync = ref.watch(distributionsByProgramProvider(program.programId));

    return distributionsAsync.when(
      data: (distributions) {
        if (distributions.isEmpty) {
          return const Center(
            child: Text('No distributions yet'),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: distributions.length,
          itemBuilder: (context, index) {
            return _buildDistributionCard(distributions[index]);
          },
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, s) => Center(child: Text('Error: $e')),
    );
  }

  Widget _buildDistributionCard(DistributionRecord record) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Colors.green,
          child: Icon(Icons.check, color: Colors.white),
        ),
        title: Text(record.beneficiaryName),
        subtitle: Text(
          '${record.quantity} ${record.unit} • ${DateFormat('MMM dd, HH:mm').format(record.distributedAt)}',
        ),
        trailing: Text(
          record.beneficiaryNationalId,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ),
    );
  }

  void _navigateToDistribute(BeneficiaryModel beneficiary, DistributionProgram program) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DistributeAidScreen(
          beneficiary: beneficiary,
          program: program,
        ),
      ),
    ).then((_) {
      // Refresh data
      ref.invalidate(programByIdProvider(widget.programId));
      ref.invalidate(eligibleBeneficiariesProvider(program));
      ref.invalidate(distributionsByProgramProvider(widget.programId));
    });
  }

  void _handleMenuAction(String action) async {
    String newStatus;
    switch (action) {
      case 'pause':
        newStatus = 'paused';
        break;
      case 'complete':
        newStatus = 'completed';
        break;
      case 'cancel':
        newStatus = 'cancelled';
        break;
      default:
        return;
    }

    final service = ref.read(distributionServiceProvider);
    await service.updateProgramStatus(widget.programId, newStatus);
    ref.invalidate(programByIdProvider(widget.programId));
  }

  IconData _getAidTypeIcon(AidType type) {
    switch (type) {
      case AidType.food:
        return Icons.fastfood;
      case AidType.medicine:
        return Icons.medical_services;
      case AidType.cash:
        return Icons.payments;
      case AidType.clothing:
        return Icons.checkroom;
      case AidType.shelter:
        return Icons.home;
      case AidType.water:
        return Icons.water_drop;
      case AidType.nutrition:
        return Icons.egg;
      case AidType.education:
        return Icons.school;
      default:
        return Icons.category;
    }
  }

  String _getCategoryLabel(String value) {
    switch (value) {
      case 'pregnant_woman':
        return 'Pregnant';
      case 'lactating_mother':
        return 'Lactating';
      case 'child_under_5':
        return 'Child <5';
      case 'elderly':
        return 'Elderly';
      case 'disabled':
        return 'Disabled';
      case 'chronically_ill':
        return 'Chronic Ill';
      default:
        return value;
    }
  }
}


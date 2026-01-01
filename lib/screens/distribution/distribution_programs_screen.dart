import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/distribution_model.dart';
import '../../providers/distribution_provider.dart';
import '../../providers/auth_provider.dart';
import 'create_program_screen.dart';
import 'program_detail_screen.dart';

class DistributionProgramsScreen extends ConsumerWidget {
  const DistributionProgramsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final programsAsync = ref.watch(allProgramsProvider);
    final userDataAsync = ref.watch(currentUserDataStreamProvider);
    final isAdmin = userDataAsync.value?.isAdmin ?? false;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Distribution Programs'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const CreateProgramScreen(),
                  ),
                );
              },
              backgroundColor: Colors.green[700],
              icon: const Icon(Icons.add),
              label: const Text('New Program'),
            )
          : null,
      body: programsAsync.when(
        data: (programs) {
          if (programs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No distribution programs yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  if (isAdmin) ...[
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CreateProgramScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Create First Program'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[700],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(allProgramsProvider);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: programs.length,
              itemBuilder: (context, index) {
                return _buildProgramCard(context, programs[index], isAdmin);
              },
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
              Text('Error: ${error.toString()}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(allProgramsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgramCard(
    BuildContext context,
    DistributionProgram program,
    bool isAdmin,
  ) {
    final statusColor = _getStatusColor(program.status);
    final aidType = AidType.fromValue(program.aidType);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  ProgramDetailScreen(programId: program.programId),
            ),
          );
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header Row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getAidTypeIcon(aidType),
                      color: Colors.green[700],
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          program.programName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          aidType.label,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      program.status.toUpperCase(),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Description
              if (program.description != null &&
                  program.description!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    program.description!,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              // Target Categories
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: program.targetCategories.take(3).map((cat) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getCategoryLabel(cat),
                      style: TextStyle(fontSize: 11, color: Colors.blue[700]),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Stats Row
              Row(
                children: [
                  _buildStatItem(
                    Icons.people,
                    '${program.distributedCount}',
                    'Distributed',
                  ),
                  const SizedBox(width: 24),
                  _buildStatItem(
                    Icons.inventory,
                    '${program.quantityPerBeneficiary} ${program.unit}',
                    'Per Person',
                  ),
                  const Spacer(),
                  Text(
                    DateFormat('MMM dd, yyyy').format(program.startDate),
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem(IconData icon, String value, String label) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[600]),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey[600]),
            ),
          ],
        ),
      ],
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'paused':
        return Colors.orange;
      case 'completed':
        return Colors.blue;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getAidTypeIcon(AidType type) {
    switch (type) {
      case AidType.food:
        return Icons.fastfood;
      case AidType.medicine:
        return Icons.medical_services;
      case AidType.cash:
        return Icons.payments;
      case AidType.nutrition:
        return Icons.egg;
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

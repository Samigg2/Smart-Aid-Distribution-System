import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/distribution_model.dart';
import '../../models/beneficiary_model.dart';
import '../../providers/distribution_provider.dart';
import '../../providers/beneficiary_provider.dart';
import '../../providers/firestore_provider.dart';
import '../../services/export_service.dart';

class ReportsDashboardScreen extends ConsumerWidget {
  const ReportsDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final distributionStatsAsync = ref.watch(distributionStatisticsProvider);
    final beneficiaryStatsAsync = ref.watch(beneficiaryStatisticsProvider);
    final userStatsAsync = ref.watch(userStatisticsProvider);
    final recentDistributionsAsync = ref.watch(recentDistributionsProvider);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Reports & Analytics'),
        backgroundColor: Colors.indigo[700],
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.download),
            tooltip: 'Export Data',
            onSelected: (value) => _handleExport(context, ref, value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'beneficiaries_csv',
                child: ListTile(
                  leading: Icon(Icons.people),
                  title: Text('Export Beneficiaries'),
                  subtitle: Text('CSV format'),
                ),
              ),
              const PopupMenuItem(
                value: 'distributions_csv',
                child: ListTile(
                  leading: Icon(Icons.inventory),
                  title: Text('Export Distributions'),
                  subtitle: Text('CSV format'),
                ),
              ),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(distributionStatisticsProvider);
          ref.invalidate(beneficiaryStatisticsProvider);
          ref.invalidate(userStatisticsProvider);
          ref.invalidate(recentDistributionsProvider);
        },
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Cards
              _buildSummarySection(
                distributionStatsAsync,
                beneficiaryStatsAsync,
                userStatsAsync,
              ),
              const SizedBox(height: 24),

              // Beneficiary by Category Chart
              _buildCategoryBreakdown(ref),
              const SizedBox(height: 24),

              // Distribution by Aid Type
              distributionStatsAsync.when(
                data: (stats) => _buildAidTypeBreakdown(stats),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
              ),
              const SizedBox(height: 24),

              // Recent Activity
              _buildRecentActivity(recentDistributionsAsync),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection(
    AsyncValue<Map<String, dynamic>> distributionStats,
    AsyncValue<Map<String, int>> beneficiaryStats,
    AsyncValue<Map<String, int>> userStats,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Overview',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.3,
          children: [
            _buildStatCard(
              'Total Beneficiaries',
              beneficiaryStats.when(
                data: (s) => '${s['total'] ?? 0}',
                loading: () => '...',
                error: (_, __) => '-',
              ),
              Icons.people,
              Colors.blue,
            ),
            _buildStatCard(
              'Total Distributions',
              distributionStats.when(
                data: (s) => '${s['totalDistributions'] ?? 0}',
                loading: () => '...',
                error: (_, __) => '-',
              ),
              Icons.inventory,
              Colors.green,
            ),
            _buildStatCard(
              'Active Programs',
              distributionStats.when(
                data: (s) => '${s['activePrograms'] ?? 0}',
                loading: () => '...',
                error: (_, __) => '-',
              ),
              Icons.campaign,
              Colors.orange,
            ),
            _buildStatCard(
              'Beneficiaries Reached',
              distributionStats.when(
                data: (s) => '${s['uniqueBeneficiariesReached'] ?? 0}',
                loading: () => '...',
                error: (_, __) => '-',
              ),
              Icons.check_circle,
              Colors.purple,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Icon(icon, color: color, size: 24),
                Flexible(
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                title,
                style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryBreakdown(WidgetRef ref) {
    final beneficiariesAsync = ref.watch(allBeneficiariesProvider);

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.pie_chart, color: Colors.indigo[700]),
                const SizedBox(width: 8),
                const Text(
                  'Beneficiaries by Category',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            beneficiariesAsync.when(
              data: (beneficiaries) {
                // Count by category
                Map<String, int> counts = {};
                for (var b in beneficiaries) {
                  for (var cat in b.vulnerableCategories) {
                    counts[cat] = (counts[cat] ?? 0) + 1;
                  }
                }

                if (counts.isEmpty) {
                  return const Center(child: Text('No data available'));
                }

                return Column(
                  children: VulnerableCategory.values.map((cat) {
                    final count = counts[cat.value] ?? 0;
                    final percentage = beneficiaries.isEmpty
                        ? 0.0
                        : (count / beneficiaries.length * 100);
                    return _buildProgressRow(
                      cat.label,
                      count,
                      percentage,
                      _getCategoryColor(cat),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Error loading data'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressRow(String label, int count, double percentage, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label, style: const TextStyle(fontSize: 14)),
              Text(
                '$count (${percentage.toStringAsFixed(1)}%)',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: percentage / 100,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildAidTypeBreakdown(Map<String, dynamic> stats) {
    final byAidType = stats['byAidType'] as Map<String, int>? ?? {};

    if (byAidType.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.bar_chart, color: Colors.indigo[700]),
                const SizedBox(width: 8),
                const Text(
                  'Distributions by Aid Type',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            ...byAidType.entries.map((entry) {
              final aidType = AidType.fromValue(entry.key);
              final total = byAidType.values.fold<int>(0, (a, b) => a + b);
              final percentage = total > 0 ? (entry.value / total * 100) : 0.0;
              return _buildProgressRow(
                aidType.label,
                entry.value,
                percentage,
                Colors.green,
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity(AsyncValue<List<DistributionRecord>> recentAsync) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.history, color: Colors.indigo[700]),
                const SizedBox(width: 8),
                const Text(
                  'Recent Distributions',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const Divider(height: 24),
            recentAsync.when(
              data: (distributions) {
                if (distributions.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Text('No distributions yet'),
                    ),
                  );
                }
                return Column(
                  children: distributions.take(10).map((d) {
                    return ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: Colors.green[100],
                        child: Icon(Icons.check, size: 16, color: Colors.green[700]),
                      ),
                      title: Text(d.beneficiaryName),
                      subtitle: Text(
                        '${d.quantity} ${d.unit} - ${d.programName}',
                      ),
                      trailing: Text(
                        DateFormat('MMM dd').format(d.distributedAt),
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    );
                  }).toList(),
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => const Text('Error loading data'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(VulnerableCategory category) {
    switch (category) {
      case VulnerableCategory.pregnantWoman:
        return Colors.pink;
      case VulnerableCategory.lactatingMother:
        return Colors.purple;
      case VulnerableCategory.childUnder5:
        return Colors.orange;
      case VulnerableCategory.elderly:
        return Colors.indigo;
      case VulnerableCategory.disabled:
        return Colors.teal;
      case VulnerableCategory.chronicallyIll:
        return Colors.red;
    }
  }

  Future<void> _handleExport(BuildContext context, WidgetRef ref, String type) async {
    final exportService = ExportService();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: Row(
          children: [
            CircularProgressIndicator(),
            SizedBox(width: 16),
            Text('Exporting data...'),
          ],
        ),
      ),
    );

    try {
      String? filePath;

      if (type == 'beneficiaries_csv') {
        final beneficiaryService = ref.read(beneficiaryServiceProvider);
        final beneficiaries = await beneficiaryService.getAllBeneficiariesForExport();
        filePath = await exportService.exportBeneficiariesToCsv(beneficiaries);
      } else if (type == 'distributions_csv') {
        final distributionService = ref.read(distributionServiceProvider);
        final distributions = await distributionService.getAllDistributionsForExport();
        filePath = await exportService.exportDistributionsToCsv(distributions);
      }

      Navigator.pop(context); // Close loading dialog

      if (filePath != null) {
        final exportPath = filePath;
        final fileName = exportPath.split('/').last;
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 28),
                SizedBox(width: 8),
                Text('Export Successful'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'File exported successfully!',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text('File: $fileName'),
                const SizedBox(height: 8),
                Text(
                  'Location:',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
                Text(
                  exportPath,
                  style: TextStyle(fontSize: 11, color: Colors.grey[700]),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  'Look in: Downloads folder or App Documents',
                  style: TextStyle(fontSize: 11, color: Colors.blue[700], fontStyle: FontStyle.italic),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                ),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Export failed: $e')),
      );
    }
  }
}


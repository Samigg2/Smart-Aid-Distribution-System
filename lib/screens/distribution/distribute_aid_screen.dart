import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import '../../models/distribution_model.dart';
import '../../models/beneficiary_model.dart';
import '../../providers/distribution_provider.dart';
import '../../providers/auth_provider.dart';

class DistributeAidScreen extends ConsumerStatefulWidget {
  final BeneficiaryModel beneficiary;
  final DistributionProgram program;

  const DistributeAidScreen({
    super.key,
    required this.beneficiary,
    required this.program,
  });

  @override
  ConsumerState<DistributeAidScreen> createState() => _DistributeAidScreenState();
}

class _DistributeAidScreenState extends ConsumerState<DistributeAidScreen> {
  final _notesController = TextEditingController();
  bool _isLoading = false;
  bool _isCheckingDuplicate = true;
  bool _hasAlreadyReceived = false;
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _checkDuplicateDistribution();
  }

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _checkDuplicateDistribution() async {
    final service = ref.read(distributionServiceProvider);
    final hasReceived = await service.hasAlreadyReceived(
      widget.program.programId,
      widget.beneficiary.beneficiaryId,
    );
    if (mounted) {
      setState(() {
        _hasAlreadyReceived = hasReceived;
        _isCheckingDuplicate = false;
      });
    }
  }

  Future<void> _captureLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location permission denied')),
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
        SnackBar(content: Text('Location captured: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  Future<void> _confirmDistribution() async {
    // Double-check before distributing
    if (_hasAlreadyReceived) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ This beneficiary already received aid from this program!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Distribution'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Distribute to: ${widget.beneficiary.fullName}'),
            const SizedBox(height: 8),
            Text('ID: ${widget.beneficiary.nationalId}'),
            const SizedBox(height: 8),
            Text('Amount: ${widget.program.quantityPerBeneficiary} ${widget.program.unit}'),
            const SizedBox(height: 8),
            Text('Program: ${widget.program.programName}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isLoading = true);

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      final userData = ref.read(currentUserDataStreamProvider).value;

      if (currentUser == null) throw Exception('Not logged in');

      final record = DistributionRecord(
        recordId: '',
        programId: widget.program.programId,
        programName: widget.program.programName,
        beneficiaryId: widget.beneficiary.beneficiaryId,
        beneficiaryName: widget.beneficiary.fullName,
        beneficiaryNationalId: widget.beneficiary.nationalId,
        aidType: widget.program.aidType,
        quantity: widget.program.quantityPerBeneficiary,
        unit: widget.program.unit,
        distributedBy: currentUser.uid,
        distributedByName: userData?.fullName,
        distributedAt: DateTime.now(),
        latitude: _latitude,
        longitude: _longitude,
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );

      final service = ref.read(distributionServiceProvider);
      final result = await service.recordDistribution(record);

      if (result != null && mounted) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green[700], size: 32),
                const SizedBox(width: 12),
                const Text('Success!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${widget.program.quantityPerBeneficiary} ${widget.program.unit} distributed to:'),
                const SizedBox(height: 8),
                Text(
                  widget.beneficiary.fullName,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ],
            ),
            actions: [
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Done'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
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
    final aidType = AidType.fromValue(widget.program.aidType);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Distribute Aid'),
        backgroundColor: Colors.green[700],
        foregroundColor: Colors.white,
      ),
      body: _isCheckingDuplicate
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Already Received Warning
                  if (_hasAlreadyReceived)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning, color: Colors.red[700], size: 32),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ALREADY RECEIVED',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.red[700],
                                    fontSize: 16,
                                  ),
                                ),
                                Text(
                                  'This beneficiary has already received aid from this program.',
                                  style: TextStyle(color: Colors.red[700]),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Beneficiary Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 40,
                            backgroundColor: Colors.green[100],
                            backgroundImage: widget.beneficiary.photoUrl != null
                                ? NetworkImage(widget.beneficiary.photoUrl!)
                                : null,
                            child: widget.beneficiary.photoUrl == null
                                ? Text(
                                    widget.beneficiary.fullName[0].toUpperCase(),
                                    style: TextStyle(fontSize: 32, color: Colors.green[700]),
                                  )
                                : null,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            widget.beneficiary.fullName,
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'ID: ${widget.beneficiary.nationalId}',
                            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            children: widget.beneficiary.vulnerableCategories.map((cat) {
                              return Chip(
                                label: Text(_getCategoryLabel(cat)),
                                backgroundColor: Colors.blue[50],
                                labelStyle: TextStyle(color: Colors.blue[700], fontSize: 12),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Program Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.inventory, color: Colors.green[700]),
                              const SizedBox(width: 8),
                              const Text(
                                'Distribution Details',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          _buildDetailRow('Program', widget.program.programName),
                          _buildDetailRow('Aid Type', aidType.label),
                          _buildDetailRow(
                            'Quantity',
                            '${widget.program.quantityPerBeneficiary} ${widget.program.unit}',
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Location & Notes Card
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.location_on, color: Colors.green[700]),
                              const SizedBox(width: 8),
                              const Text(
                                'Location & Notes',
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          ElevatedButton.icon(
                            onPressed: _captureLocation,
                            icon: const Icon(Icons.gps_fixed),
                            label: Text(
                              _latitude != null
                                  ? 'GPS: ${_latitude!.toStringAsFixed(4)}, ${_longitude!.toStringAsFixed(4)}'
                                  : 'Capture Location',
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[600],
                              foregroundColor: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          TextField(
                            controller: _notesController,
                            decoration: const InputDecoration(
                              labelText: 'Notes (optional)',
                              hintText: 'Any additional notes...',
                              border: OutlineInputBorder(),
                            ),
                            maxLines: 3,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Distribute Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton.icon(
                      onPressed: (_isLoading || _hasAlreadyReceived)
                          ? null
                          : _confirmDistribution,
                      icon: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle, size: 28),
                      label: Text(
                        _hasAlreadyReceived
                            ? 'ALREADY RECEIVED'
                            : 'CONFIRM DISTRIBUTION',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _hasAlreadyReceived ? Colors.grey : Colors.green[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey[600])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
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


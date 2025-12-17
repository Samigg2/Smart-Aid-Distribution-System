import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/beneficiary_registration_data.dart';
import 'step1_personal_info_screen.dart';
import 'step2_category_details_screen.dart';
import 'step3_family_location_screen.dart';

class RegistrationFlowScreen extends ConsumerStatefulWidget {
  const RegistrationFlowScreen({super.key});

  @override
  ConsumerState<RegistrationFlowScreen> createState() =>
      _RegistrationFlowScreenState();
}

class _RegistrationFlowScreenState
    extends ConsumerState<RegistrationFlowScreen> {
  final PageController _pageController = PageController();
  final BeneficiaryRegistrationData _registrationData =
      BeneficiaryRegistrationData();
  int _currentStep = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep++);
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
      setState(() => _currentStep--);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Register Beneficiary'),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Container(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildStepIndicator(0, 'Personal Info'),
                _buildStepIndicator(1, 'Category Details'),
                _buildStepIndicator(2, 'Family & Location'),
              ],
            ),
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          Step1PersonalInfoScreen(data: _registrationData, onNext: _nextStep),
          Step2CategoryDetailsScreen(
            data: _registrationData,
            onNext: _nextStep,
            onBack: _previousStep,
          ),
          Step3FamilyLocationScreen(
            data: _registrationData,
            onBack: _previousStep,
          ),
        ],
      ),
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;
    return Expanded(
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: isActive || isCompleted
                      ? Colors.blue[700]
                      : Colors.grey[300],
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: isCompleted
                      ? const Icon(Icons.check, color: Colors.white, size: 18)
                      : Text(
                          '${step + 1}',
                          style: TextStyle(
                            color: isActive || isCompleted
                                ? Colors.white
                                : Colors.grey[600],
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              Expanded(
                child: Container(
                  height: 2,
                  color: isCompleted ? Colors.blue[700] : Colors.grey[300],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isActive || isCompleted
                  ? Colors.blue[700]
                  : Colors.grey[600],
              fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}

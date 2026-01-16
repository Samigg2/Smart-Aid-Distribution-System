import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import '../models/beneficiary_model.dart';
import '../models/distribution_model.dart';
import '../utils/logger.dart';
import 'export_web_helper_stub.dart'
    if (dart.library.html) 'export_web_helper.dart';

class ExportService {
  /// Export beneficiaries to CSV file
  Future<String?> exportBeneficiariesToCsv(List<BeneficiaryModel> beneficiaries) async {
    try {
      // Build CSV content
      final buffer = StringBuffer();

      // Header row
      buffer.writeln([
        'Beneficiary ID',
        'Full Name',
        'National ID',
        'Phone Number',
        'Age',
        'Gender',
        'Categories',
        'Is Pregnant',
        'Pregnancy Trimester',
        'Children Under 5',
        'Children Ages',
        'Family Size',
        'Female-Headed Household',
        'Income Level',
        'Receiving Other Aid',
        'Region',
        'Zone',
        'Woreda',
        'Latitude',
        'Longitude',
        'Urgency Score',
        'Registered At',
        'Registered By',
      ].map(_escapeCsv).join(','));

      // Data rows
      for (var b in beneficiaries) {
        buffer.writeln([
          b.beneficiaryId,
          b.fullName,
          b.nationalId,
          b.phoneNumber ?? '',
          b.age?.toString() ?? '',
          b.gender,
          b.vulnerableCategories.join('; '),
          b.isPregnant ? 'Yes' : 'No',
          b.pregnancyTrimester?.toString() ?? '',
          b.childrenUnder5Count.toString(),
          b.childrenAges.map((a) => '$a months').join('; '),
          b.totalFamilySize.toString(),
          b.isFemaleHeadedHousehold ? 'Yes' : 'No',
          b.incomeLevel,
          b.currentlyReceivingOtherAid ? 'Yes' : 'No',
          b.region,
          b.zone ?? '',
          b.woreda ?? '',
          b.latitude?.toString() ?? '',
          b.longitude?.toString() ?? '',
          b.urgencyScore.toStringAsFixed(2),
          DateFormat('yyyy-MM-dd HH:mm').format(b.createdAt),
          b.registeredBy,
        ].map(_escapeCsv).join(','));
      }

      // Save to file
      final filePath = await _saveToFile(
        'beneficiaries_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv',
        buffer.toString(),
      );

      return filePath;
    } catch (e, stackTrace) {
      Logger.error('Error exporting beneficiaries', error: e, stackTrace: stackTrace, tag: 'ExportService');
      return null;
    }
  }

  /// Export distributions to CSV file
  Future<String?> exportDistributionsToCsv(List<DistributionRecord> distributions) async {
    try {
      // Build CSV content
      final buffer = StringBuffer();

      // Header row
      buffer.writeln([
        'Record ID',
        'Program ID',
        'Program Name',
        'Beneficiary ID',
        'Beneficiary Name',
        'Beneficiary National ID',
        'Aid Type',
        'Quantity',
        'Unit',
        'Distributed By',
        'Distributed By Name',
        'Distributed At',
        'Latitude',
        'Longitude',
        'Notes',
      ].map(_escapeCsv).join(','));

      // Data rows
      for (var d in distributions) {
        buffer.writeln([
          d.recordId,
          d.programId,
          d.programName,
          d.beneficiaryId,
          d.beneficiaryName,
          d.beneficiaryNationalId,
          d.aidType,
          d.quantity.toString(),
          d.unit,
          d.distributedBy,
          d.distributedByName ?? '',
          DateFormat('yyyy-MM-dd HH:mm').format(d.distributedAt),
          d.latitude?.toString() ?? '',
          d.longitude?.toString() ?? '',
          d.notes ?? '',
        ].map(_escapeCsv).join(','));
      }

      // Save to file
      final filePath = await _saveToFile(
        'distributions_${DateFormat('yyyyMMdd_HHmmss').format(DateTime.now())}.csv',
        buffer.toString(),
      );

      return filePath;
    } catch (e, stackTrace) {
      Logger.error('Error exporting distributions', error: e, stackTrace: stackTrace, tag: 'ExportService');
      return null;
    }
  }

  /// Export program summary
  Future<String?> exportProgramSummary(
    DistributionProgram program,
    List<DistributionRecord> distributions,
  ) async {
    try {
      final buffer = StringBuffer();

      // Program info
      buffer.writeln('PROGRAM SUMMARY');
      buffer.writeln('');
      buffer.writeln('Program Name,${_escapeCsv(program.programName)}');
      buffer.writeln('Aid Type,${_escapeCsv(AidType.fromValue(program.aidType).label)}');
      buffer.writeln('Status,${_escapeCsv(program.status)}');
      buffer.writeln('Target Categories,${_escapeCsv(program.targetCategories.join("; "))}');
      buffer.writeln('Quantity Per Person,${program.quantityPerBeneficiary} ${program.unit}');
      buffer.writeln('Total Distributed,${program.distributedCount}');
      buffer.writeln('Start Date,${DateFormat('yyyy-MM-dd').format(program.startDate)}');
      if (program.endDate != null) {
        buffer.writeln('End Date,${DateFormat('yyyy-MM-dd').format(program.endDate!)}');
      }
      buffer.writeln('');
      buffer.writeln('');

      // Distribution details
      buffer.writeln('DISTRIBUTION RECORDS');
      buffer.writeln('');
      buffer.writeln([
        'Beneficiary Name',
        'National ID',
        'Quantity',
        'Unit',
        'Date',
        'Distributed By',
        'Location',
      ].map(_escapeCsv).join(','));

      for (var d in distributions) {
        buffer.writeln([
          d.beneficiaryName,
          d.beneficiaryNationalId,
          d.quantity.toString(),
          d.unit,
          DateFormat('yyyy-MM-dd HH:mm').format(d.distributedAt),
          d.distributedByName ?? d.distributedBy,
          d.latitude != null ? '${d.latitude}, ${d.longitude}' : '',
        ].map(_escapeCsv).join(','));
      }

      // Save to file
      final filePath = await _saveToFile(
        'program_${program.programId}_${DateFormat('yyyyMMdd').format(DateTime.now())}.csv',
        buffer.toString(),
      );

      return filePath;
    } catch (e, stackTrace) {
      Logger.error('Error exporting program summary', error: e, stackTrace: stackTrace, tag: 'ExportService');
      return null;
    }
  }

  /// Escape CSV value
  String _escapeCsv(String value) {
    if (value.contains(',') || value.contains('"') || value.contains('\n')) {
      return '"${value.replaceAll('"', '""')}"';
    }
    return value;
  }

  /// Save content to file and return path
  Future<String> _saveToFile(String fileName, String content) async {
    if (kIsWeb) {
      // On web we cannot write to a local filesystem path; trigger a download instead.
      return ExportWebHelper.saveCsv(fileName, content);
    }

    Directory exportDir;
    
    try {
      // Try to save to Downloads folder (more accessible on Android)
      if (Platform.isAndroid) {
        // For Android, use external storage Downloads directory
        final externalDir = await getExternalStorageDirectory();
        if (externalDir != null) {
          // Navigate to Downloads folder
          final downloadsPath = '${externalDir.path.split('/Android')[0]}/Download';
          exportDir = Directory(downloadsPath);
        } else {
          // Fallback to app documents directory
          final directory = await getApplicationDocumentsDirectory();
          exportDir = Directory('${directory.path}/exports');
        }
      } else if (Platform.isIOS) {
        // For iOS, use app documents directory
        final directory = await getApplicationDocumentsDirectory();
        exportDir = Directory('${directory.path}/exports');
      } else {
        // For other platforms, use app documents directory
        final directory = await getApplicationDocumentsDirectory();
        exportDir = Directory('${directory.path}/exports');
      }

      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      final file = File('${exportDir.path}/$fileName');
      await file.writeAsString(content);

      return file.path;
    } catch (e) {
      // Fallback to app documents directory if Downloads fails
      final directory = await getApplicationDocumentsDirectory();
      exportDir = Directory('${directory.path}/exports');
      
      if (!await exportDir.exists()) {
        await exportDir.create(recursive: true);
      }

      final file = File('${exportDir.path}/$fileName');
      await file.writeAsString(content);

      return file.path;
    }
  }
}



# Google Cloud Vision API - Implementation Steps

## 🎯 When to Check: At Registration vs After

### **Recommendation: At Registration (Async Check)**

**Why:**
- ✅ Immediate feedback to user
- ✅ Prevents duplicate from being saved
- ✅ Better UX (user can retake photo if duplicate)
- ✅ Doesn't block registration (async, show warning)

**How:**
1. User captures photo
2. Upload to Cloudinary (already done)
3. **While uploading**, check for duplicates in background
4. If duplicate found → Show warning dialog
5. User can proceed or retake photo

---

## 📋 Step-by-Step Implementation

### **Step 1: Create Google Cloud Project**

1. Go to https://console.cloud.google.com
2. Click "Create Project"
3. Name: "SmartAid-FairID"
4. Click "Create"

### **Step 2: Enable Vision API**

1. In Google Cloud Console, go to "APIs & Services" → "Library"
2. Search "Cloud Vision API"
3. Click "Enable"
4. Wait for activation (~30 seconds)

### **Step 3: Create API Key**

1. Go to "APIs & Services" → "Credentials"
2. Click "Create Credentials" → "API Key"
3. Copy the API key
4. **IMPORTANT:** Restrict the key:
   - Click on the key
   - Under "API restrictions", select "Restrict key"
   - Choose "Cloud Vision API"
   - Save

### **Step 4: Add Dependency**

Add to `pubspec.yaml`:
```yaml
dependencies:
  google_mlkit_face_detection: ^0.9.0
  # OR use HTTP directly:
  http: ^1.2.2  # Already added
```

### **Step 5: Create Vision Service**

Create `lib/services/vision_service.dart`:
```dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:io';

class VisionService {
  static const String _apiKey = 'YOUR_API_KEY_HERE';
  static const String _apiUrl = 
    'https://vision.googleapis.com/v1/images:annotate?key=$_apiKey';

  // Detect faces and extract features
  Future<Map<String, dynamic>?> detectFace(String imageUrl) async {
    try {
      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'requests': [
            {
              'image': {'source': {'imageUri': imageUrl}},
              'features': [
                {'type': 'FACE_DETECTION', 'maxResults': 10}
              ],
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['responses'][0]['faceAnnotations'] != null) {
          final faces = data['responses'][0]['faceAnnotations'];
          if (faces.isNotEmpty) {
            return faces[0]; // Return first face
          }
        }
      }
      return null;
    } catch (e) {
      print('Vision API error: $e');
      return null;
    }
  }

  // Calculate face similarity (simplified)
  double calculateSimilarity(
    Map<String, dynamic> face1,
    Map<String, dynamic> face2,
  ) {
    // Compare face landmarks positions
    // This is simplified - real implementation needs proper algorithm
    final landmarks1 = face1['landmarks'] as List;
    final landmarks2 = face2['landmarks'] as List;
    
    if (landmarks1.length != landmarks2.length) return 0.0;
    
    double totalDiff = 0.0;
    for (int i = 0; i < landmarks1.length; i++) {
      final pos1 = landmarks1[i]['position'];
      final pos2 = landmarks2[i]['position'];
      final diff = (pos1['x'] - pos2['x']).abs() + 
                   (pos1['y'] - pos2['y']).abs();
      totalDiff += diff;
    }
    
    // Convert to similarity score (0-1)
    final similarity = 1.0 - (totalDiff / (landmarks1.length * 100));
    return similarity.clamp(0.0, 1.0);
  }
}
```

### **Step 6: Update BeneficiaryModel**

Add face data field:
```dart
final Map<String, dynamic>? faceData; // Store face landmarks
```

### **Step 7: Update Registration Screen**

In `_submitForm()`:
```dart
// After uploading to Cloudinary
_photoUrl = await cloudinaryService.uploadBeneficiaryPhoto(_photoFile!);

// Check for duplicates (async, don't block)
_checkForDuplicates(_photoUrl!);

// Continue with registration...
```

Add method:
```dart
Future<void> _checkForDuplicates(String photoUrl) async {
  final visionService = VisionService();
  final newFace = await visionService.detectFace(photoUrl);
  
  if (newFace == null) {
    // No face detected - show warning
    return;
  }
  
  // Get all existing beneficiaries
  final allBeneficiaries = await ref.read(beneficiaryServiceProvider)
      .getAllBeneficiaries()
      .first; // Get first snapshot
  
  // Compare with existing faces
  for (var beneficiary in allBeneficiaries) {
    if (beneficiary.faceData != null) {
      final similarity = visionService.calculateSimilarity(
        newFace,
        beneficiary.faceData!,
      );
      
      if (similarity > 0.85) {
        // Duplicate detected!
        _showDuplicateWarning(beneficiary);
        return;
      }
    }
  }
}

void _showDuplicateWarning(BeneficiaryModel existing) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Possible Duplicate Detected'),
      content: Text(
        'This photo matches an existing beneficiary:\n'
        '${existing.fullName} (ID: ${existing.nationalId})\n\n'
        'Do you want to continue anyway?',
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            // User can retake photo
          },
          child: const Text('Retake Photo'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.pop(context);
            // Continue with registration
          },
          child: const Text('Continue Anyway'),
        ),
      ],
    ),
  );
}
```

---

## ⚠️ Important Notes

1. **API Key Security:**
   - Don't commit API key to Git
   - Use environment variables or secure storage
   - For student project, this is acceptable

2. **Cost:**
   - FREE: 1,000 requests/month
   - After: $1.50 per 1,000 requests
   - Very affordable for student projects

3. **Accuracy:**
   - 85% similarity threshold is good
   - Can adjust based on testing
   - False positives are better than false negatives

4. **Performance:**
   - API call takes ~500ms-1s
   - Run async, don't block UI
   - Show loading indicator

---

## 🚀 Quick Start

1. Create Google Cloud account (FREE)
2. Enable Vision API
3. Get API key
4. Add to `vision_service.dart`
5. Integrate in registration screen
6. Test!

**Total Time: ~2 hours** (including testing)



# Cloudinary Setup Guide

## Step 1: Create Free Cloudinary Account

1. Go to https://cloudinary.com/users/register/free
2. Sign up with your email (FREE tier includes 10GB storage)
3. Verify your email

## Step 2: Get Your Credentials

1. After logging in, go to Dashboard
2. You'll see your credentials:
   - **Cloud Name** (e.g., `dxyz123abc`)
   - **API Key** (e.g., `123456789012345`)
   - **API Secret** (e.g., `abcdefghijklmnopqrstuvwxyz123456`)

## Step 3: Update CloudinaryService

Open `lib/services/cloudinary_service.dart` and replace:

```dart
static const String _cloudName = 'YOUR_CLOUD_NAME';
static const String _apiKey = 'YOUR_API_KEY';
static const String _apiSecret = 'YOUR_API_SECRET';
```

With your actual credentials:

```dart
static const String _cloudName = 'dxyz123abc';  // Your cloud name
static const String _apiKey = '123456789012345';  // Your API key
static const String _apiSecret = 'abcdefghijklmnopqrstuvwxyz123456';  // Your API secret
```

## Step 4: Configure Upload Settings (Optional)

The service is already configured to:
- Upload to folder: `fairid/beneficiaries` (⚠️ **Note:** Folders are created automatically - you don't need to create them manually in Cloudinary!)
- Compress images to 80% quality
- Resize if larger than 1200px width
- Use secure URLs (HTTPS)

**Important:** The folder `fairid/beneficiaries` will be created automatically when you upload your first photo. You don't need to create it manually in your Cloudinary dashboard!

## Step 5: Test Upload

1. Run the app
2. Register a beneficiary
3. Capture a photo
4. Check Cloudinary dashboard to see uploaded images

## Security Note

⚠️ **IMPORTANT**: For production, store credentials in environment variables or secure storage. For student projects, this is acceptable.

## Free Tier Limits

- ✅ 10GB storage
- ✅ 10GB bandwidth/month
- ✅ Unlimited transformations
- ✅ Perfect for student projects!

## Troubleshooting

**Error: "Invalid cloud name"**
- Check that you copied the cloud name correctly (no spaces)

**Error: "Invalid API key"**
- Verify API key and secret are correct
- Make sure you're using the right account

**Upload fails**
- Check internet connection
- Verify image file is valid
- Check Cloudinary dashboard for errors




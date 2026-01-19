# FIX CORS IN YOUR priority_model_api (1).py
# Replace line 111 with this:

# BEFORE (line 111):
# CORS(app)  # Enable CORS for mobile app integration

# AFTER (line 111):
CORS(app, resources={r"/*": {"origins": "*", "methods": ["GET", "POST", "OPTIONS"], "allow_headers": ["Content-Type", "X-API-Key"]}})

# OR MORE SPECIFIC (for production):
# CORS(app, origins=["http://localhost:*", "https://your-firebase-project.web.app"])


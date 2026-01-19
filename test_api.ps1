# Test Priority AI API
$baseUrl = "https://ai-v8ey.onrender.com"

Write-Host "Testing Health Endpoint..." -ForegroundColor Cyan
try {
    $healthResponse = Invoke-WebRequest -Uri "$baseUrl/health" -Method GET -UseBasicParsing
    Write-Host "✅ Health Check: SUCCESS" -ForegroundColor Green
    Write-Host $healthResponse.Content
} catch {
    Write-Host "❌ Health Check: FAILED" -ForegroundColor Red
    Write-Host $_.Exception.Message
}

Write-Host "`nTesting Predict Endpoint (without API key)..." -ForegroundColor Cyan
$predictBody = @{
    age = 25
    gender = "Female"
    income = "Low"
    disability = "No"
    dependents = 2
    description = "Single mother with two children"
} | ConvertTo-Json

try {
    $predictResponse = Invoke-WebRequest -Uri "$baseUrl/predict" -Method POST -Body $predictBody -ContentType "application/json" -UseBasicParsing
    Write-Host "✅ Predict: SUCCESS" -ForegroundColor Green
    Write-Host $predictResponse.Content
} catch {
    Write-Host "❌ Predict: FAILED" -ForegroundColor Red
    Write-Host "Status: $($_.Exception.Response.StatusCode.value__)"
    Write-Host $_.Exception.Message
}



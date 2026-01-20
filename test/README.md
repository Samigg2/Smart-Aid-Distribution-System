# Testing Guide

This directory contains unit tests for the Smart Aid Distribution application.

## Test Structure

```
test/
├── config/              # Configuration tests
│   ├── app_config_test.dart
│   └── env_config_test.dart
├── models/              # Model tests
│   ├── beneficiary_model_test.dart
│   └── user_model_test.dart
└── utils/               # Utility tests
    └── beneficiary_validator_test.dart
```

## Running Tests

### Run all tests
```bash
flutter test
```

### Run specific test file
```bash
flutter test test/models/user_model_test.dart
```

### Run tests with coverage
```bash
flutter test --coverage
```

### Generate coverage report
```bash
genhtml coverage/lcov.info -o coverage/html
open coverage/html/index.html
```

## Test Categories

### Unit Tests
- **Config Tests**: Test environment configuration loading
- **Model Tests**: Test data models and their serialization
- **Validator Tests**: Test input validation logic

### Widget Tests
Widget tests should be added in the `test/widgets/` directory.

### Integration Tests
Integration tests should be added in the `test/integration/` directory.

## Writing Tests

### Test Structure
Follow the Arrange-Act-Assert pattern:
```dart
test('description', () {
  // Arrange - set up test data
  final input = 'test';
  
  // Act - execute the code
  final result = functionToTest(input);
  
  // Assert - verify the result
  expect(result, equals(expectedValue));
});
```

### Grouping Tests
Use `group()` to organize related tests:
```dart
group('ClassName', () {
  group('methodName', () {
    test('should do something', () {
      // test code
    });
  });
});
```

## Best Practices

1. **Test naming**: Use descriptive names that explain what is being tested
2. **One assertion per test**: Keep tests focused on a single behavior
3. **Mock external dependencies**: Use mocks for Firestore, HTTP requests, etc.
4. **Test edge cases**: Include tests for null values, empty strings, boundary conditions
5. **Keep tests independent**: Each test should be able to run in isolation

## Dependencies for Testing

The project uses the following testing packages:
- `flutter_test`: Core Flutter testing framework (included in SDK)
- Additional mocks can be added using `mockito` package if needed

## Coverage Goals

Aim for at least 70% code coverage for:
- Business logic
- Data models
- Validators
- Services (where possible)


class Validators {
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email';
    }
    
    return null;
  }
  
  static String? validatePin(String? value, {int length = 4}) {
    if (value == null || value.isEmpty) {
      return 'PIN is required';
    }
    
    if (value.length != length) {
      return 'PIN must be $length digits';
    }
    
    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return 'PIN must contain only numbers';
    }
    
    return null;
  }
  
  static String? validateAmount(String? value) {
    if (value == null || value.isEmpty) {
      return 'Amount is required';
    }
    
    // Allow numbers with optional decimal point
    if (!RegExp(r'^\d+\.?\d{0,2}$').hasMatch(value)) {
      return 'Please enter a valid amount (max 2 decimal places)';
    }
    
    final amount = double.tryParse(value);
    if (amount == null) {
      return 'Please enter a valid amount';
    }
    
    if (amount <= 0) {
      return 'Amount must be greater than 0';
    }
    
    return null;
  }
  
  static String? validateRequired(String? value, [String fieldName = 'This field']) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
  
  static String? validateApiKey(String? value) {
    if (value == null || value.isEmpty) {
      return 'API Key is required';
    }
    
    if (value.length < 20) {
      return 'API Key seems too short';
    }
    
    return null;
  }
}


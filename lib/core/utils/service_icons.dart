// Service Icon Mapping
class ServiceIcons {
  static const Map<String, String> iconMap = {
    // Streaming Services
    'netflix': '🎬',
    'youtube': '▶️',
    'spotify': '🎵',
    'apple music': '🎵',
    'disney+': '🏰',
    'hbo': '📺',
    'amazon prime': '📦',
    'max': '🎭',
    
    // Creative Tools
    'adobe': '🎨',
    'canva': '🖼️',
    'figma': '✏️',
    'notion': '📝',
    
    // Productivity
    'microsoft 365': '💼',
    'google workspace': '📧',
    'dropbox': '☁️',
    'icloud': '☁️',
    
    // Music Production
    'musicbed': '🎼',
    'artlist': '🎶',
    'epidemic sound': '🎵',
    
    // Fitness & Health
    'gym': '💪',
    'fitness': '🏃',
    'yoga': '🧘',
    
    // Food & Delivery
    'grab': '🚗',
    'foodpanda': '🍔',
    'lineman': '🛵',
    
    // Utilities
    'electricity': '⚡',
    'water': '💧',
    'internet': '🌐',
    'phone': '📱',
    
    // Default
    'default': '📊',
  };

  static String getIcon(String serviceName) {
    final name = serviceName.toLowerCase();
    
    // Try exact match first
    if (iconMap.containsKey(name)) {
      return iconMap[name]!;
    }
    
    // Try partial match
    for (var key in iconMap.keys) {
      if (name.contains(key)) {
        return iconMap[key]!;
      }
    }
    
    return iconMap['default']!;
  }

  static List<String> getPopularServices() {
    return [
      'Netflix',
      'YouTube Premium',
      'Spotify',
      'Adobe Creative Cloud',
      'Microsoft 365',
      'Google Workspace',
      'Dropbox',
      'iCloud',
      'Disney+',
      'HBO Max',
      'Apple Music',
      'Amazon Prime',
      'Notion',
      'Figma',
      'Canva',
      'Musicbed',
      'Artlist',
      'Gym Membership',
      'Internet',
      'Phone Plan',
    ];
  }
}

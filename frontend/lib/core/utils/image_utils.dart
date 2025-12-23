class ImageUtils {
  /// Check if image URL is valid and can be loaded by Flutter
  /// Rejects invalid schemes like 'r2-disabled://' or 'file://'
  static bool isValidImageUrl(String? url) {
    if (url == null || url.isEmpty) {
      return false;
    }
    
    // Only allow http:// and https:// schemes
    return url.startsWith('http://') || url.startsWith('https://');
  }
}

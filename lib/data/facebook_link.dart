/// A shop's Facebook page, which buyers use to message the shop directly in
/// Messenger.
class FacebookLink {
  const FacebookLink._(this._name);

  /// The page's username (e.g. "testshop.oro") or numeric profile ID.
  final String _name;

  bool get _isNumericId => RegExp(r'^\d+$').hasMatch(_name);

  /// The page link that is saved and shown, e.g.
  /// `https://www.facebook.com/testshop.oro`.
  String get pageUrl => _isNumericId
      ? 'https://www.facebook.com/profile.php?id=$_name'
      : 'https://www.facebook.com/$_name';

  Uri get pageUri => Uri.parse(pageUrl);

  /// Opens a Messenger chat with the page.
  Uri get messengerUri => Uri.parse('https://m.me/$_name');
}

/// First path parts of facebook.com links that are not a page or profile.
const _notAPage = {
  'events',
  'groups',
  'hashtag',
  'help',
  'home.php',
  'login',
  'login.php',
  'marketplace',
  'messages',
  'permalink.php',
  'photo',
  'photo.php',
  'reel',
  'search',
  'settings',
  'share',
  'sharer',
  'stories',
  'story.php',
  'watch',
};

final _username = RegExp(r'^[A-Za-z0-9.\-]{2,80}$');
final _numericId = RegExp(r'^\d{5,20}$');

/// Reads a Facebook page or Messenger link a shop owner pasted, such as
/// `facebook.com/yourshop`, `fb.com/yourshop`, `m.me/yourshop` or
/// `facebook.com/profile.php?id=1000…`. Null when it is not one.
FacebookLink? parseFacebookLink(String input) {
  var text = input.trim();
  if (text.isEmpty) return null;
  if (!text.contains('://')) text = 'https://$text';
  final uri = Uri.tryParse(text);
  if (uri == null || (uri.scheme != 'https' && uri.scheme != 'http')) {
    return null;
  }
  var host = uri.host.toLowerCase();
  for (final prefix in ['www.', 'm.', 'web.', 'mobile.', 'business.']) {
    if (host.startsWith(prefix) && host != 'm.me') {
      host = host.substring(prefix.length);
    }
  }
  final parts = [
    for (final part in uri.pathSegments)
      if (part.isNotEmpty) part,
  ];

  String? name;
  if (host == 'facebook.com' || host == 'fb.com') {
    if (parts.isEmpty) return null;
    if (parts.first == 'profile.php') {
      name = uri.queryParameters['id'];
    } else if (parts.first == 'pages' && parts.length >= 3) {
      // facebook.com/pages/Shop-Name/1234567890
      name = parts[2];
    } else if (parts.first == 'people' && parts.length >= 3) {
      name = parts[2];
    } else if (!_notAPage.contains(parts.first.toLowerCase())) {
      name = parts.first;
    }
  } else if (host == 'm.me') {
    if (parts.isNotEmpty) name = parts.first;
  } else if (host == 'messenger.com') {
    if (parts.length >= 2 && parts.first == 't') name = parts[1];
  }

  if (name == null) return null;
  if (!_numericId.hasMatch(name) && !_username.hasMatch(name)) return null;
  if (_notAPage.contains(name.toLowerCase())) return null;
  return FacebookLink._(name);
}

/// Error text for the shop's Facebook field, or null when it is fine.
String? validateFacebookLink(String input) {
  final text = input.trim();
  if (text.isEmpty) return null;
  if (RegExp(r'^\+?[\d\s\-()]{7,}$').hasMatch(text)) {
    return 'Enter your shop\'s Facebook page link, not a phone number.';
  }
  if (parseFacebookLink(text) == null) {
    return 'Paste your shop\'s Facebook page link, e.g. facebook.com/yourshop.';
  }
  return null;
}

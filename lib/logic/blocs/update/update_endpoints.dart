class UpdateEndpoints {

  static const String _baseUrl = 'https://api.github.com';
  static const String _repo = 'shakle/arber';

  static const String latestRelease = '$_baseUrl/repos/$_repo/releases/latest';
  static const String releasesPage = 'https://github.com/$_repo/releases/latest';
}

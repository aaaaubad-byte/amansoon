import 'package:flutter_test/flutter_test.dart';

import 'package:aman_app/core/config/app_config.dart';

void main() {
  test('configuration is disabled when build defines are absent', () {
    expect(AppConfig.isConfigured, isFalse);
  });
}

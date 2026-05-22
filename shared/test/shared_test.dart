import 'package:flutter_test/flutter_test.dart';

import 'package:wtf_shared/wtf_shared.dart';

void main() {
  test('shared library exports are accessible', () {
    expect(WtfColors.trainerPrimary.toARGB32(), 0xFFE50914);
    expect(WtfColors.guruPrimary.toARGB32(), 0xFF1769E0);
  });
}

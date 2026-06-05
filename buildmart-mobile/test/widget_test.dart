import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:buildmart_mobile/core/theme/app_theme.dart';

void main() {
  test('App theme visual design system test', () {
    expect(AppColors.primary, const Color(0xFF0F4C81));
    expect(AppColors.secondary, const Color(0xFF00AEEF));
  });
}

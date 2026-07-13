// Regression test for the RenderFlex overflow seen in the "Free From" row
// (add_receipes.dart / update_ai_inputs_sheet.dart) when a long title like
// "Processed food Ingredients" was rendered in a Row that combined
// `mainAxisSize: MainAxisSize.min` with `MainAxisAlignment.spaceBetween` and
// forced a 30px height around a 40px-tall checkbox icon.
//
// Reproduces both the buggy structure (to prove this test would have caught
// it) and the fixed structure (to prove the fix actually resolves it), at a
// narrow width matching the iPhone 12 Pro screenshot where it was observed.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';

const _longTitle = 'Processed food Ingredients';

Widget _checkboxIcon() => Container(
  height: 40,
  width: 40,
  color: Colors.grey,
);

Widget _buggyRow() => SizedBox(
  height: 30,
  child: Row(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const CustomText(
        text: _longTitle,
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: Color(0xff384250),
      ),
      _checkboxIcon(),
    ],
  ),
);

Widget _fixedRow() => Padding(
  padding: const EdgeInsets.symmetric(vertical: 4),
  child: Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      const Expanded(
        child: CustomText(
          text: _longTitle,
          fontSize: 18,
          fontWeight: FontWeight.w500,
          color: Color(0xff384250),
        ),
      ),
      _checkboxIcon(),
    ],
  ),
);

Future<void> _pumpAtPhoneWidth(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(width: 320, child: child),
      ),
    ),
  );
}

void main() {
  testWidgets(
    'buggy structure overflows with a long Free From title (sanity check)',
    (tester) async {
      await _pumpAtPhoneWidth(tester, _buggyRow());
      expect(tester.takeException(), isNotNull);
    },
  );

  testWidgets(
    'fixed structure does not overflow with a long Free From title',
    (tester) async {
      await _pumpAtPhoneWidth(tester, _fixedRow());
      expect(tester.takeException(), isNull);
    },
  );
}

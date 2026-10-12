import 'package:docwellnesdoc/app/modules/receipes/models/recipe_model.dart';
import 'package:docwellnesdoc/app/modules/receipes/services/recipe_service.dart';
import 'package:docwellnesdoc/app/modules/receipes/widgets/receipe_container.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/sponsored_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget host(Widget child) =>
    MaterialApp(home: Scaffold(body: Center(child: child)));

void main() {
  group('SponsoredLabel / SponsoredBadge', () {
    testWidgets('show the disclosure text', (tester) async {
      await tester.pumpWidget(
        host(
          const Column(
            children: [SponsoredLabel('Sponsored'), SponsoredBadge('Paid partnership')],
          ),
        ),
      );
      expect(find.text('Sponsored'), findsOneWidget);
      expect(find.text('Paid partnership'), findsOneWidget);
    });

    testWidgets('render nothing without a label', (tester) async {
      await tester.pumpWidget(
        host(
          const Column(
            children: [SponsoredLabel(null), SponsoredBadge(''), SponsoredBadge('  ')],
          ),
        ),
      );
      expect(find.byType(Text), findsNothing);
    });
  });

  group('recipe grid card', () {
    testWidgets('shows the Sponsored badge only when a label is given', (tester) async {
      await tester.pumpWidget(
        host(
          ReceipeContainer(
            imageUrl: '',
            title: 'Whey Protein',
            subTitle: '3 ingredients',
            sponsoredLabel: 'Sponsored',
            onTap: () {},
          ),
        ),
      );
      expect(find.text('Sponsored'), findsOneWidget);

      await tester.pumpWidget(
        host(
          ReceipeContainer(
            imageUrl: '',
            title: 'Poha',
            subTitle: '5 ingredients',
            onTap: () {},
          ),
        ),
      );
      expect(find.text('Sponsored'), findsNothing);
    });
  });

  group('sponsoredLabel in models', () {
    test('RecipeListItem parses it', () {
      final item = RecipeListItem.fromJson({
        'id': 'r1',
        'name': 'Whey Protein',
        'image': 'https://res.cloudinary.com/x/commercial.jpg',
        'sponsoredLabel': 'Sponsored',
      });
      expect(item.sponsoredLabel, 'Sponsored');
      expect(RecipeListItem.fromJson({'id': 'r2', 'name': 'Poha'}).sponsoredLabel, isNull);
      expect(
        RecipeListItem.fromJson({'id': 'r3', 'name': 'Idli', 'sponsoredLabel': null}).sponsoredLabel,
        isNull,
      );
    });

    test('RecipePreview parses it and keeps it through every copy', () {
      final p = RecipePreview.fromJson({
        '_id': 'r1',
        'name': 'Whey Protein',
        'image': 'https://res.cloudinary.com/x/commercial.jpg',
        'sponsoredLabel': 'Sponsored',
      });
      expect(p.sponsoredLabel, 'Sponsored');
      expect(p.copyWithId('r9').sponsoredLabel, 'Sponsored');
      expect(p.copyWithIngredients(const []).sponsoredLabel, 'Sponsored');
      expect(RecipePreview.fromJson({'_id': 'r2', 'name': 'Poha'}).sponsoredLabel, isNull);
    });
  });
}

import 'package:docwellnesdoc/app/modules/exercises/views/exercises_view.dart';
import 'package:docwellnesdoc/app/modules/receipes/views/receipes_view.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Combined "Recipes & Supplements" / "Exercises" bottom-nav tab: a TabBar
/// (title-sized labels, sliding pill indicator) replaces the AppBar's usual
/// title and switches a TabBarView between RecipesTabBody and
/// ExercisesTabBody - swipeable directly, or tap a tab to animate to it.
/// Built on Flutter's own TabController/TabBar/TabBarView trio rather than a
/// hand-rolled Stack+AnimatedAlign segmented control - that first attempt
/// had centering issues a real TabBar's layout engine doesn't have, and it
/// gets swipe-to-switch for free via TabBarView. Replaces the old
/// plain-title ReceipesView as the bottom nav's 3rd tab (see
/// bottom_navi_bar.dart) now that diet and exercise plans live under one
/// roof for the dietician, the same way they do for the patient.
class DietAndExerciseView extends StatefulWidget {
  const DietAndExerciseView({super.key});

  @override
  State<DietAndExerciseView> createState() => _DietAndExerciseViewState();
}

class _DietAndExerciseViewState extends State<DietAndExerciseView>
    with SingleTickerProviderStateMixin {
  static const _headerColor = Color(0xffFDF2FA);
  static const _accent = Color(0xff851653);

  late final TabController _tabController = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: _headerColor,
        elevation: 0,
        toolbarHeight: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(78),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: const Color(0xffE5E7EB)),
              ),
              clipBehavior: Clip.antiAlias,
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(color: _accent, borderRadius: BorderRadius.circular(26)),
                indicatorSize: TabBarIndicatorSize.tab,
                indicatorPadding: EdgeInsets.zero,
                dividerColor: Colors.transparent,
                splashBorderRadius: BorderRadius.circular(26),
                labelColor: Colors.white,
                unselectedLabelColor: const Color(0xff384250),
                labelStyle: GoogleFonts.roboto(fontSize: 19, fontWeight: FontWeight.w600),
                unselectedLabelStyle: GoogleFonts.roboto(fontSize: 19, fontWeight: FontWeight.w400),
                tabs: const [
                  Tab(
                    height: 52,
                    iconMargin: EdgeInsets.zero,
                    child: _TabLabel(icon: Icons.restaurant_menu_rounded, text: 'Recipes'),
                  ),
                  Tab(
                    height: 52,
                    iconMargin: EdgeInsets.zero,
                    child: _TabLabel(icon: Icons.fitness_center_rounded, text: 'Exercises'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          RecipesTabBody(),
          ExercisesTabBody(),
        ],
      ),
    );
  }
}

/// Icon + label pair for one Tab - deliberately plain Icon()/Text() with no
/// explicit color/style so both inherit the IconTheme/DefaultTextStyle the
/// enclosing TabBar sets per tab (selected vs unselected), the same
/// mechanism Tab's own built-in icon/text params use internally.
class _TabLabel extends StatelessWidget {
  final IconData icon;
  final String text;
  const _TabLabel({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 19),
        const SizedBox(width: 8),
        Text(text),
      ],
    );
  }
}

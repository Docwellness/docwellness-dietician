import 'package:docwellnesdoc/app/modules/chat/views/chat_view.dart';
import 'package:docwellnesdoc/app/modules/home/controllers/home_controller.dart';
import 'package:docwellnesdoc/app/modules/home/views/diet_and_exercise_view.dart';
import 'package:docwellnesdoc/app/modules/home/views/home_view.dart';
import 'package:docwellnesdoc/app/modules/patients/views/patients_view.dart';
import 'package:docwellnesdoc/app/modules/performance/views/performance_view.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

const maroonColor = Color(0xFF6A0D33);
const lightPink = Color(0xffFEF6FB);

class BottomNaviBar extends StatelessWidget {
  BottomNaviBar({super.key});

  final controller = Get.put(HomeController());

  // Lazily built, then kept alive via IndexedStack (AI_EXECUTION_PLAN.md
  // Phase 7/P8-02) - previously `body: screens[controller.selectedIndex.value]`
  // constructed a brand-new widget subtree on every tab switch, destroying
  // scroll position and any in-progress state (e.g. the Patients tab's
  // search/filter selections) and re-firing every initState each time.
  // Each slot starts null and is only constructed the first time its index
  // is selected, matching docwellness-user's identical fix (P6-03) - a
  // plain eager screens list would preserve state too, but would also
  // build every tab immediately on first mount instead of only the tabs
  // actually visited.
  final List<Widget?> _screens = List<Widget?>.filled(5, null);

  Widget _screenAt(int index) {
    return _screens[index] ??= switch (index) {
      0 => HomeView(),
      1 => const PatientsView(),
      2 => const DietAndExerciseView(),
      3 => const PerformanceView(),
      4 => const ChatView(),
      _ => HomeView(),
    };
  }

  final icons = [
    'assets/icons/Vector.png',
    'assets/icons/Frame.png',
    'assets/icons/diet_exercise_icon.png',
    'assets/icons/Frame(1).png',
    'assets/icons/Frame(2).png',
  ];

  final labels = ["Home", "Patients", "Diet & Exercise", "Performance", "Chat"];

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor: lightPink,
        body: IndexedStack(
          index: controller.selectedIndex.value,
          children: List.generate(_screens.length, (index) {
            if (index != controller.selectedIndex.value && _screens[index] == null) {
              return const SizedBox.shrink();
            }
            return _screenAt(index);
          }),
        ),
        // SafeArea (not a fixed bottom padding) so this clears whichever
        // system navigation style is active - the 3-button nav bar's ~48dp
        // inset and gesture nav's slimmer inset are both reported through
        // MediaQuery's padding, which SafeArea reads automatically. Apps
        // targeting Android 15+ render edge-to-edge by default, so without
        // this the system nav bar draws on top of - not below - this Row.
        bottomNavigationBar: SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
            decoration: const BoxDecoration(
              color: lightPink,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(icons.length, (index) {
                final isSelected = controller.selectedIndex.value == index;
                return Expanded(
                  child: GestureDetector(
                    onTap: () {
                      controller.onTabSelected(index);
                      controller.changeTab(index);
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          padding: const EdgeInsets.only(
                            left: 20,
                            right: 20,
                            top: 6,
                            bottom: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? maroonColor
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          // diet_exercise_icon.png is a full-color line-art
                          // badge with an opaque (non-transparent) cream
                          // background - unlike the other nav icons it can't
                          // be tint-recolored via colorBlendMode (that would
                          // paint the whole square solid), so it renders at
                          // its own natural colors always, clipped to a
                          // circle to crop away the square's cream corners.
                          child: index == 2
                              ? ClipOval(
                                  child: Image.asset(icons[index], height: 26, width: 26, fit: BoxFit.cover),
                                )
                              : Image.asset(
                                  icons[index],
                                  height: 22,
                                  colorBlendMode: BlendMode.srcIn,
                                  color: isSelected ? Colors.white : Colors.grey[700],
                                ),
                        ),
                        const SizedBox(height: 4),
                        CustomText(
                          text: labels[index],
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          color: isSelected ? maroonColor : Colors.grey[700]!,
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          fontSize: 11,
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

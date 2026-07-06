import 'package:docwellnesdoc/app/modules/chat/views/chat_view.dart';
import 'package:docwellnesdoc/app/modules/home/controllers/home_controller.dart';
import 'package:docwellnesdoc/app/modules/home/views/home_view.dart';
import 'package:docwellnesdoc/app/modules/patients/views/patients_view.dart';
import 'package:docwellnesdoc/app/modules/performance/views/performance_view.dart';
import 'package:docwellnesdoc/app/modules/receipes/views/receipes_view.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

const maroonColor = Color(0xFF6A0D33);
const lightPink = Color(0xffFEF6FB);

class BottomNaviBar extends StatelessWidget {
  BottomNaviBar({super.key});

  final controller = Get.put(HomeController());
  final screens = [
    HomeView(),
    const PatientsView(),
    const ReceipesView(),
    const PerformanceView(),
    const ChatView(),
  ];

  final icons = [
    'assets/icons/Vector.png',
    'assets/icons/Frame.png',
    'assets/icons/Vector(1).png',
    'assets/icons/Frame(1).png',
    'assets/icons/Frame(2).png',
  ];

  final labels = ["Home", "Patients", "Receipes", "Performance", "Chat"];

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Scaffold(
        backgroundColor: lightPink,
        body: screens[controller.selectedIndex.value],
        bottomNavigationBar: Container(
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
                          color: isSelected ? maroonColor : Colors.transparent,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Image.asset(
                          icons[index],
                          height: 22,
                          colorBlendMode: BlendMode.srcIn,
                          color: isSelected ? Colors.white : Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      CustomText(
                        text: labels[index],

                        color: isSelected ? maroonColor : Colors.grey[700]!,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.w500,
                        fontSize: 10.5,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

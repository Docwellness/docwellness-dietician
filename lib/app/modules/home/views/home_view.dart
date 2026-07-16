import 'dart:math';

import 'package:docwellnesdoc/app/models/patient_request_model.dart';
import 'package:docwellnesdoc/app/modules/home/views/action_details_view.dart';
import 'package:docwellnesdoc/app/modules/home/views/all_patient_requests_view.dart';
import 'package:docwellnesdoc/app/modules/home/views/doctor_profile_view.dart';
import 'package:docwellnesdoc/app/modules/home/widgets/patient_request_container.dart';
import 'package:docwellnesdoc/app/modules/receipes/views/add_receipes.dart';
import 'package:docwellnesdoc/app/modules/receipes/views/view_added_receipes.dart';
import 'package:docwellnesdoc/app/modules/receipes/widgets/receipe_container.dart';
import 'package:docwellnesdoc/app/routes/app_pages.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/home_controller.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xffFDF2FA),
        title: Text(
          'Dashboard',
          style: GoogleFonts.roboto(
            fontWeight: FontWeight.w400,
            color: Color(0xff1F2A37),
          ),
        ),
        actionsPadding: EdgeInsets.only(right: 16),
        actions: [
          Obx(() {
            final count = controller.notificationUnreadCount.value;
            return GestureDetector(
              onTap: () async {
                await Get.toNamed(Routes.NOTIFICATIONS);
                controller.fetchNotificationCount();
              },
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Icon(
                    Icons.notifications_none_rounded,
                    size: 26,
                    color: Color(0xff1F2A37),
                  ),
                  if (count > 0)
                    Positioned(
                      right: -4,
                      top: -4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xffDE2493),
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          count > 99 ? '99+' : '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
            );
          }),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => Get.to(() => DoctorProfileView()),
            child: Container(
              height: 24,
              width: 24,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/profile.png'),
                  fit: BoxFit.cover,
                ),
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(top: 16, left: 16, right: 16),
        child: Obx(() {
          if (controller.showHomeLoading.value) {
            return Center(
              child: CircularProgressIndicator(color: Color(0xff851653)),
            );
          }
          return _buildHomeContent();
        }),
      ),
    );
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      color: const Color(0xff851653),
      backgroundColor: Colors.white,
      onRefresh: () => controller.refreshHomeData(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CustomText(
              text: 'Take actions',
              fontWeight: FontWeight.w400,
              fontSize: 18,
              color: Color(0xff530630),
            ),
            SizedBox(height: 24),
            // this will come if all 3 is 0
            // Container(
            //   height: 278,
            //   decoration: BoxDecoration(
            //     borderRadius: BorderRadius.circular(12),
            //     color: Color(0xffFEF6FB),
            //   ),
            //   padding: EdgeInsets.only(
            //     top: 48.81,
            //     bottom: 12,
            //     left: 12,
            //     right: 12,
            //   ),
            //   child: Column(
            //     crossAxisAlignment: CrossAxisAlignment.center,
            //     children: [
            //       Image.asset('assets/images/Group.png',height: 113.39,width: 75.97,fit: BoxFit.cover,),
            //       SizedBox(
            //         height: 11,
            //       ),
            //       CustomText(
            //         text: 'All Actions taken',
            //         fontWeight: FontWeight.w600,
            //         fontSize: 20,
            //         color: Color(0xff530630),
            //       ),

            //       SizedBox(height: 2),

            //       CustomText(
            //         text:
            //             'Just relax on your chair for few minutes. I am sure that every clients is having a good progress',
            //         fontWeight: FontWeight.w400,
            //         fontSize: 14,
            //         color: Color(0xff851653),
            //         textAlign: TextAlign.center,
            //       ),
            //     ],
            //   ),
            // ),
            SizedBox(
              height: 118,
              width: double.infinity,
              child: Obx(
                () => ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    actionContainer(
                      'Messages\nReceived',
                      controller.messagesReceived.value,
                      onTap: () => _showActionDetails('Messages Received'),
                    ),
                    const SizedBox(width: 12),
                    actionContainer(
                      'Review\nLogged Data',
                      controller.reviewLoggedData.value,
                      onTap: () => _showActionDetails('Review Logged Data'),
                    ),
                    const SizedBox(width: 12),
                    actionContainer(
                      'Clients Close\nto End',
                      controller.closingClients.value,
                      onTap: () => _showActionDetails('Clients Close to End'),
                    ),
                    const SizedBox(width: 12),
                    actionContainer(
                      'Did Extremely\nWell',
                      controller.didExtremelyWell.value,
                      onTap: () => _showActionDetails('Did Extremely Well'),
                    ),
                    const SizedBox(width: 12),
                    actionContainer(
                      'Need\nAttention',
                      controller.needAttention.value,
                      onTap: () => _showActionDetails('Need Attention'),
                    ),
                    const SizedBox(width: 12),
                    actionContainer(
                      'Pending\nPayments',
                      controller.pendingPaymentRequests.length,
                      onTap: () => _showActionDetails('Pending Payments'),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                CustomText(
                  text: 'New patient requests',
                  fontWeight: FontWeight.w400,
                  fontSize: 17,
                  color: Color(0xff530630),
                ),
                GestureDetector(
                  onTap: () {
                    Get.to(() => const AllPatientRequestsView());
                  },
                  child: Container(
                    height: 32,
                    width: 70,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: Color(0xff530630)),
                      color: Colors.transparent,
                    ),
                    child: Center(
                      child: CustomText(
                        text: 'See all',
                        fontWeight: FontWeight.w500,
                        fontSize: 13.5,
                        color: Color(0xff530630),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 26),

            Obx(
              () => ListView.builder(
                itemCount: min(4, controller.filteredPatientRequests.length),
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) {
                  if (controller.filteredPatientRequests.isEmpty) {
                    return Text("No Request Found");
                  }

                  final data = controller.filteredPatientRequests[index];

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: PatientRequestContainer(
                      goal: data.primaryGoal ?? "",
                      title: data.patientName ?? "",
                      onTap: () {
                        Get.toNamed('/patient-profile/${data.patientId ?? ''}');
                      },
                      status: data.status ?? 'Unpaid',
                      avatarUrl: data.avatarUrl,
                      membershipPlan: data.membershipPlan,
                    ),
                  );
                },
              ),
            ),

            // SizedBox(height: 8),
            // PatientRequestContainer(
            //   imageUrl:
            //       'assets/demos/126b814837c9ad599d252555d0aca226af2b1504.jpg',
            //   title: 'Patient name',
            //   onTap: () {},
            //   isPaid: 1,
            // ),
            SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: CustomText(
                    text: 'Recipes',
                    fontWeight: FontWeight.w400,
                    fontSize: 17,
                    color: Color(0xff530630),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Get.to(() => AddRecipeScreen());
                  },
                  child: Container(
                    height: 32,
                    width: 136,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: Color(0xff530630)),
                      color: Colors.transparent,
                    ),
                    child: Center(
                      child: CustomText(
                        text: 'Add new recipe',
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Color(0xff530630),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),
            Obx(() {
              if (controller.isLoadingCategories.value) {
                return SizedBox(
                  height: 185,
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xff851653)),
                  ),
                );
              }
              if (controller.recipeCategories.isEmpty) {
                return SizedBox(
                  height: 185,
                  child: Center(
                    child: CustomText(
                      text: 'No recipe categories yet',
                      fontWeight: FontWeight.w400,
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                );
              }
              return SizedBox(
                height: 185,
                width: double.infinity,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: controller.recipeCategories.length,
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    final category = controller.recipeCategories[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ReceipeContainer(
                        imageUrl:
                            category.image ??
                            'assets/demos/4338dff1fae4820e15916dfa19ae06cd6d19c5ed.jpg',
                        title: category.name,
                        subTitle: '${category.count} recipes',
                        onTap: () {
                          Get.to(
                            () =>
                                ViewAddedReceipes(categoryName: category.name),
                          );
                        },
                      ),
                    );
                  },
                ),
              );
            }),
            SizedBox(height: 21),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: CustomText(
                    text: 'Discounts & Coupons',
                    fontWeight: FontWeight.w400,
                    fontSize: 17,
                    color: Color(0xff530630),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    controller.onTabSelected(3);
                    controller.changeTab(3);
                  },
                  child: Container(
                    height: 32,
                    width: 59,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(100),
                      border: Border.all(color: Color(0xff530630)),
                      color: Colors.transparent,
                    ),
                    child: Center(
                      child: CustomText(
                        text: 'See all',
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                        color: Color(0xff530630),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            Container(
              height: 104,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Color(0xffFEF6FB),
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.only(left: 16, top: 12, bottom: 12, right: 9),
              child: Row(
                children: [
                  Container(
                    height: 80,
                    width: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: DecorationImage(
                        image: AssetImage(
                          'assets/images/a497facdd8d00bcb90521a8f41d608f0f294b8d9.jpg',
                        ),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(height: 5),
                        CustomText(
                          text: 'Active Coupons',
                          fontWeight: FontWeight.w400,
                          fontSize: 18,
                          color: Color(0xff1F2A37),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 7),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Color(0xffFDF2FA),
                            border: Border.all(color: Color(0xffFCE7F6)),
                          ),
                          child: Obx(
                            () => CustomText(
                              text: '${controller.activeCouponCount.value}',
                              fontWeight: FontWeight.w500,
                              fontSize: 12,
                              color: Color(0xffEF45B2),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      controller.onTabSelected(3);
                      controller.changeTab(3);
                    },
                    icon: Icon(
                      Icons.arrow_forward_ios_rounded,
                      color: Color(0xff851653),
                      size: 21,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),

            Container(
              height: 235,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Color(0xffFEF6FB),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 17),

                    Image.asset(
                      'assets/images/badge.png',
                      height: 97.66,
                      width: 77.15,
                      fit: BoxFit.cover,
                    ),
                    SizedBox(height: 25.5),

                    CustomText(
                      text: 'Huge achievement',
                      fontWeight: FontWeight.w600,
                      fontSize: 20,
                      color: Color(0xff530630),
                    ),
                    SizedBox(height: 1),
                    SizedBox(
                      width: 235,
                      child: CustomText(
                        text:
                            '80% of patients achieved their first-week goal. You got this!',
                        fontWeight: FontWeight.w400,
                        fontSize: 14,
                        color: Color(0xff851653),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    fontSize: 13,

                    onTap: () {},
                    text: 'Add new patient',
                    isOutline: true,
                  ),
                ),
                SizedBox(width: 8),
                Expanded(
                  child: CustomButton(
                    fontSize: 13,
                    onTap: () {},
                    text: 'Generate report',
                    isOutline: false,
                  ),
                ),
              ],
            ),

            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget actionContainer(
    String label,
    int count, {
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.only(top: 20, left: 16, right: 16),
        height: 118,
        width: 130,
        decoration: BoxDecoration(
          color: Color(0xffFEF6FB),
          border: Border.all(color: Color(0xff9F1561)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            CustomText(
              text: label,
              fontWeight: FontWeight.w500,
              fontSize: 14,
              color: Color(0xff1F2A37),
              height: 1.3,
            ),
            SizedBox(height: 4),
            Container(
              decoration: BoxDecoration(
                color: Color(0xffFDF2FA),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Color(0xffFCE7F6)),
              ),
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: CustomText(
                text: '$count',
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: Color(0xffEF45B2),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showActionDetails(String actionTitle) {
    int count;
    List<PatientRequestModel> requestPatients = [];
    List<Map<String, String>> simplePatients = [];

    switch (actionTitle) {
      case 'Messages Received':
        count = controller.messagesReceived.value;
        simplePatients = controller.messagesReceivedPatients;
        break;
      case 'Review Logged Data':
        count = controller.reviewLoggedData.value;
        simplePatients = controller.reviewLoggedPatients;
        break;
      case 'Clients Close to End':
        count = controller.closingClients.value;
        simplePatients = controller.closingClientsPatients;
        break;
      case 'Did Extremely Well':
        count = controller.didExtremelyWell.value;
        simplePatients = controller.didExtremelyWellPatients;
        break;
      case 'Need Attention':
        count = controller.needAttention.value;
        simplePatients = controller.needAttentionPatients;
        break;
      case 'Pending Payments':
        requestPatients = controller.pendingPaymentRequests;
        count = requestPatients.length;
        break;
      default:
        count = 0;
    }

    Get.to(
      () => ActionDetailsView(
        title: actionTitle,
        count: count,
        requestPatients: requestPatients,
        simplePatients: simplePatients,
        historyPatients: actionTitle == 'Need Attention'
            ? controller.needAttentionHistory
            : const [],
      ),
    );
  }
}

// // chart
// import 'package:flutter/material.dart';

// class ScheduleGrid extends StatelessWidget {
//   final List<String> dates;
//   final List<String> rows;
//   final List<List<Color>> colors;
//   final double cellHeight;
//   final double cellWidth;
//   final double labelWidth;

//   const ScheduleGrid({
//     super.key,
//     required this.dates,
//     required this.rows,
//     required this.colors,
//     this.cellHeight = 45,
//     this.cellWidth = 70,
//     this.labelWidth = 100,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // ---------- HEADER (DATES) ----------
//         Row(
//           children: [
//             SizedBox(width: labelWidth),
//             for (String d in dates)
//               SizedBox(
//                 width: cellWidth,
//                 child: Text(
//                   d,
//                   textAlign: TextAlign.center,
//                   style: const TextStyle(
//                     fontSize: 16,
//                     color: Color(0xFF555555),
//                   ),
//                 ),
//               ),
//           ],
//         ),

//         const SizedBox(height: 10),

//         // ---------- TABLE GRID ----------
//         Table(
//           columnWidths: {0: FixedColumnWidth(labelWidth)},
//           children: [
//             for (int r = 0; r < rows.length; r++)
//               TableRow(
//                 children: [
//                   Padding(
//                     padding: const EdgeInsets.symmetric(vertical: 16),
//                     child: Text(rows[r]),
//                   ),
//                   for (int c = 0; c < dates.length; c++)
//                     Container(
//                       height: cellHeight,
//                       width: cellWidth,
//                       margin: const EdgeInsets.all(2),
//                       decoration: BoxDecoration(
//                         color: colors[r][c],
//                         borderRadius: BorderRadius.circular(4),
//                       ),
//                     ),
//                 ],
//               )
//           ],
//         ),
//       ],
//     );
//   }
// }
// import 'package:flutter/material.dart';
// import 'schedule_grid.dart';

// class MyPage extends StatelessWidget {
//   const MyPage({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: SafeArea(
//         child: Padding(
//           padding: const EdgeInsets.all(20),
//           child: ScheduleGrid(
//             dates: ["01 Feb", "02 Feb", "02 Feb", "02 Feb", "02 Feb"],

//             rows: ["Client 1", "Client 1", "Client 1", "Client 1", "Client 1"],

//             colors: [
//               [pink, lightPink, lighterPink, red, lightest],
//               [pink, lightPink, lighterPink, lightest, lightest],
//               [pink, lightPink, lighterPink, lightest, lightest],
//               [lightPink, lightPink, green, lightest, lightest],
//               [lightest, lightest, lightest, lightest, lightest],
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// // Color presets
// const pink = Color(0xFFFFA9DB);
// const lightPink = Color(0xFFFFC4E7);
// const lighterPink = Color(0xFFFFE3F4);
// const red = Color(0xFF9B0000);
// const green = Color(0xFF00A94F);
// const lightest = Color(0xFFFDF3F9);

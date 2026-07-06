import 'dart:io';

import 'package:docwellnesdoc/app/modules/patients/controllers/patients_controller.dart';
import 'package:docwellnesdoc/app/modules/performance/models/consultation_form_field.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_field.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class QuestionsView extends StatelessWidget {
  final String gendar;
  final String patientId;
  final ScrollController scrollController;
  final bool isDisable;
  final bool isEditMode;
  QuestionsView({
    super.key,
    required this.scrollController,
    required this.gendar,
    required this.patientId,
    required this.isDisable,
    this.isEditMode = false,
  });
  final PatientsController controller = Get.find<PatientsController>();
  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 360 ? 12.0 : 16.0;
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: ListView(
            controller: scrollController,
            children: [
              SizedBox(height: 16),
              Center(
                child: Container(
                  height: 4,
                  width: 32,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    color: Color(0xff79747E),
                  ),
                ),
              ),
              SizedBox(height: 15),

              Row(
                children: [
                  IconButton(
                    onPressed: () {
                      Get.back();
                    },
                    icon: Icon(Icons.arrow_back, color: Color(0xff1F2A37)),
                  ),
                  CustomText(
                    text: isEditMode
                        ? 'Edit Consultation'
                        : 'Dietary Habits & Allergies',
                    fontWeight: FontWeight.w400,
                    fontSize: 20,
                    color: Color(0xff1F2A37),
                  ),
                ],
              ),
              Divider(color: Color(0xff9DA4AE)),
              Padding(
                padding: EdgeInsets.only(
                  left: horizontalPadding,
                  right: horizontalPadding,
                  top: 30,
                ),
                child: CustomText(
                  text: 'Q1. Current eating style',
                  fontWeight: FontWeight.w400,
                  fontSize: 18,
                  color: Color(0xff530630),
                ),
              ),
              Obx(
                () => Padding(
                  padding: EdgeInsets.only(
                    top: 19,
                    left: horizontalPadding,
                    right: horizontalPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: controller.options.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 11),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: isDisable == true
                                  ? () {}
                                  : () {
                                      for (final opt in controller.options) {
                                        opt.isSelected.value = false;
                                      }
                                      item.isSelected.value = true;
                                    },
                              child: Icon(
                                item.isSelected.value
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                size: 20,
                                color: item.isSelected.value
                                    ? const Color(0xff9B1459)
                                    : const Color(0xff49454F),
                              ),
                            ),
                            const SizedBox(width: 8),
                            CustomText(
                              text: item.name,

                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xff1F2A37),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  left: horizontalPadding,
                  right: horizontalPadding,
                  top: 16,
                ),
                child: CustomField(
                  isDisable: isDisable,
                  controller: controller.currentEatingStyleOtherInfo,
                  lable: 'Other Information',
                  hintText: 'Add few more words for describing your feeling',
                  maxLines: 7,
                  changeBorderColor: false,
                ),
              ),
              Padding(
                padding: EdgeInsets.only(
                  left: horizontalPadding,
                  right: horizontalPadding,
                  top: 25,
                ),
                child: CustomText(
                  text: 'Q2. Do you have any allergies/intolerances?',
                  fontWeight: FontWeight.w400,
                  fontSize: 18,
                  color: Color(0xff530630),
                ),
              ),
              Obx(
                () => Padding(
                  padding: EdgeInsets.only(
                    top: 19,
                    left: horizontalPadding,
                    right: horizontalPadding,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: controller.allergiesOrIntolerances.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 11),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: isDisable == true
                                  ? () {}
                                  : () {
                                      item.isSelected.value =
                                          !item.isSelected.value;
                                      //  print('-----------${controller.selectedAllergiesOrIntolerancesList}');
                                    },
                              child: Container(
                                height: 18,
                                width: 18,
                                decoration: BoxDecoration(
                                  color: item.isSelected.value
                                      ? const Color(0xff9B1459)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(2),
                                  border: Border.all(
                                    width: 2,
                                    color: item.isSelected.value
                                        ? const Color(0xff9B1459)
                                        : const Color(0xff49454F),
                                  ),
                                ),
                                child: item.isSelected.value
                                    ? Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 14,
                                        fontWeight: FontWeight.w600,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            CustomText(
                              text: item.name,

                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xff1F2A37),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Obx(
                () =>
                    controller.selectedAllergiesOrIntolerancesList.contains(
                      'Other',
                    )
                    ? Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 10,
                        ),
                        child: CustomField(
                          isDisable: isDisable,

                          controller: controller.allergiesIntolerancesOtherInfo,
                          lable: 'Other Information',
                          hintText:
                              'Add few more words for describing your feeling',
                          changeBorderColor: false,
                        ),
                      )
                    : SizedBox(),
              ),
              // Obx(
              //   () => Padding(
              //     padding: const EdgeInsets.only(top: 19, left: 16),
              //     child: Column(
              //       crossAxisAlignment: CrossAxisAlignment.start,
              //       children: controller.allergies.map((item) {
              //         return Padding(
              //           padding: const EdgeInsets.only(bottom: 11),
              //           child: Row(
              //             children: [
              //               GestureDetector(
              //                 onTap: () {
              //                   item.isSelected.value = !item.isSelected.value;
              //                   //  print('-----------${controller.selectedallergiesList}');
              //                 },
              //                 child: Container(
              //                   height: 18,
              //                   width: 18,
              //                   decoration: BoxDecoration(
              //                     color: item.isSelected.value
              //                         ? const Color(0xff9B1459)
              //                         : Colors.transparent,
              //                     borderRadius: BorderRadius.circular(2),
              //                     border: Border.all(
              //                       width: 2,
              //                       color: item.isSelected.value
              //                           ? const Color(0xff9B1459)
              //                           : const Color(0xff49454F),
              //                     ),
              //                   ),
              //                   child: item.isSelected.value
              //                       ? Icon(
              //                           Icons.check,
              //                           color: Colors.white,
              //                           size: 14,
              //                           fontWeight: FontWeight.w600,
              //                         )
              //                       : null,
              //                 ),
              //               ),
              //               const SizedBox(width: 8),
              //               CustomText(
              //                 text: item.name,

              //                 fontSize: 16,
              //                 fontWeight: FontWeight.w400,
              //                 color: const Color(0xff1F2A37),
              //               ),
              //             ],
              //           ),
              //         );
              //       }).toList(),
              //     ),
              //   ),
              // ),
              // Padding(
              //   padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
              //   child: CustomField(
              //     controller: controller.allergiesIntolerancesOtherInfo,
              //     lable: 'Other Information',
              //     hintText: 'Add few more words for describing your feeling',
              //     changeBorderColor: false,
              //   ),
              // ),
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 28),
                child: CustomText(
                  text:
                      'Q3. What foods do you avoid (religious/cultural/personal)?',
                  fontWeight: FontWeight.w400,
                  fontSize: 18,
                  color: Color(0xff530630),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
                child: CustomField(
                  isDisable: isDisable,

                  controller: controller.foodsToAvoid,
                  lable: 'Other Information',
                  hintText: 'Add few more words for describing your feeling',
                  changeBorderColor: false,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 28),
                child: CustomText(
                  text: 'Q4. Are there any cravings you struggle with?',
                  fontWeight: FontWeight.w400,
                  fontSize: 18,
                  color: Color(0xff530630),
                ),
              ),
              // Obx(
              //   () => Padding(
              //     padding: const EdgeInsets.only(top: 19, left: 16),
              //     child: Column(
              //       crossAxisAlignment: CrossAxisAlignment.start,
              //       children: controller.dietaryHabits.map((item) {
              //         return Padding(
              //           padding: const EdgeInsets.only(bottom: 11),
              //           child: Row(
              //             children: [
              //               GestureDetector(
              //                 onTap: () {
              //                   item.isSelected.value = !item.isSelected.value;
              //                   //  print('-----------${controller.selectedDietaryHabitsList}');
              //                 },
              //                 child: Container(
              //                   height: 18,
              //                   width: 18,
              //                   decoration: BoxDecoration(
              //                     color: item.isSelected.value
              //                         ? const Color(0xff9B1459)
              //                         : Colors.transparent,
              //                     borderRadius: BorderRadius.circular(2),
              //                     border: Border.all(
              //                       width: 2,
              //                       color: item.isSelected.value
              //                           ? const Color(0xff9B1459)
              //                           : const Color(0xff49454F),
              //                     ),
              //                   ),
              //                   child: item.isSelected.value
              //                       ? Icon(
              //                           Icons.check,
              //                           color: Colors.white,
              //                           size: 14,
              //                           fontWeight: FontWeight.w600,
              //                         )
              //                       : null,
              //                 ),
              //               ),
              //               const SizedBox(width: 8),
              //               CustomText(
              //                 text: item.name,

              //                 fontSize: 16,
              //                 fontWeight: FontWeight.w400,
              //                 color: const Color(0xff1F2A37),
              //               ),
              //             ],
              //           ),
              //         );
              //       }).toList(),
              //     ),
              //   ),
              // ),
              // Padding(
              //   padding: const EdgeInsets.only(left: 16, right: 16),
              //   child: CustomText(
              //     text: 'Do you have any allergies/intolerances?',
              //     fontWeight: FontWeight.w400,
              //     fontSize: 18,
              //     color: Color(0xff530630),
              //   ),
              // ),
              // Obx(
              //   () => Padding(
              //     padding: const EdgeInsets.only(top: 19, left: 16),
              //     child: Column(
              //       crossAxisAlignment: CrossAxisAlignment.start,
              //       children: controller.allergiesOrIntolerances.map((item) {
              //         return Padding(
              //           padding: const EdgeInsets.only(bottom: 11),
              //           child: Row(
              //             children: [
              //               GestureDetector(
              //                 onTap: () {
              //                   item.isSelected.value = !item.isSelected.value;
              //                   //  print('-----------${controller.selectedAllergiesOrIntolerancesList}');
              //                 },
              //                 child: Container(
              //                   height: 18,
              //                   width: 18,
              //                   decoration: BoxDecoration(
              //                     color: item.isSelected.value
              //                         ? const Color(0xff9B1459)
              //                         : Colors.transparent,
              //                     borderRadius: BorderRadius.circular(2),
              //                     border: Border.all(
              //                       width: 2,
              //                       color: item.isSelected.value
              //                           ? const Color(0xff9B1459)
              //                           : const Color(0xff49454F),
              //                     ),
              //                   ),
              //                   child: item.isSelected.value
              //                       ? Icon(
              //                           Icons.check,
              //                           color: Colors.white,
              //                           size: 14,
              //                           fontWeight: FontWeight.w600,
              //                         )
              //                       : null,
              //                 ),
              //               ),
              //               const SizedBox(width: 8),
              //               CustomText(
              //                 text: item.name,

              //                 fontSize: 16,
              //                 fontWeight: FontWeight.w400,
              //                 color: const Color(0xff1F2A37),
              //               ),
              //             ],
              //           ),
              //         );
              //       }).toList(),
              //     ),
              //   ),
              // ),
              // Obx(
              //   () =>
              //       controller.selectedAllergiesOrIntolerancesList.contains('Other')
              //       ? Padding(
              //           padding: const EdgeInsets.only(
              //             left: 16,
              //             right: 16,
              //             top: 10,
              //           ),
              //           child: CustomField(
              //             controller: TextEditingController(),
              //             lable: 'Other Information',
              //             hintText:
              //                 'Add few more words for describing your feeling',
              //             changeBorderColor: false,
              //           ),
              //         )
              //       : SizedBox(),
              // ),
              // Padding(
              //   padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
              //   child: CustomText(
              //     text: 'Are there any cravings you struggle with?',
              //     fontWeight: FontWeight.w400,
              //     fontSize: 18,
              //     color: Color(0xff530630),
              //   ),
              // ),
              Obx(
                () => Padding(
                  padding: const EdgeInsets.only(top: 19, left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: controller.cravings.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 11),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: isDisable == true
                                  ? () {}
                                  : () {
                                      item.isSelected.value =
                                          !item.isSelected.value;
                                      //  print('-----------${controller.selectedcravingsList}');
                                    },
                              child: Container(
                                height: 18,
                                width: 18,
                                decoration: BoxDecoration(
                                  color: item.isSelected.value
                                      ? const Color(0xff9B1459)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(2),
                                  border: Border.all(
                                    width: 2,
                                    color: item.isSelected.value
                                        ? const Color(0xff9B1459)
                                        : const Color(0xff49454F),
                                  ),
                                ),
                                child: item.isSelected.value
                                    ? Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 14,
                                        fontWeight: FontWeight.w600,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            CustomText(
                              text: item.name,

                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xff1F2A37),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 1),
                child: CustomText(
                  text: 'Who cooks your meals?',
                  fontWeight: FontWeight.w400,
                  fontSize: 18,
                  color: Color(0xff530630),
                ),
              ),
              Obx(
                () => Padding(
                  padding: const EdgeInsets.only(top: 15, left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: controller.cooksMeals.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 11),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: isDisable == true
                                  ? () {}
                                  : () {
                                      item.isSelected.value =
                                          !item.isSelected.value;
                                      //  print('-----------${controller.selectedCooksMealsList}');
                                    },
                              child: Container(
                                height: 18,
                                width: 18,
                                decoration: BoxDecoration(
                                  color: item.isSelected.value
                                      ? const Color(0xff9B1459)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(2),
                                  border: Border.all(
                                    width: 2,
                                    color: item.isSelected.value
                                        ? const Color(0xff9B1459)
                                        : const Color(0xff49454F),
                                  ),
                                ),
                                child: item.isSelected.value
                                    ? Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 14,
                                        fontWeight: FontWeight.w600,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            CustomText(
                              text: item.name,

                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xff1F2A37),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 1),
                child: CustomText(
                  text: 'Water Intake (liters/day):',
                  fontWeight: FontWeight.w400,
                  fontSize: 18,
                  color: Color(0xff530630),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 8),
                child: CustomField(
                  isDisable: isDisable,

                  controller: controller.waterIntake,
                  lable: 'Water Intake (liters/day)',
                  hintText: 'Water Intake (liters/day)',
                  changeBorderColor: false,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
                child: CustomText(
                  text: 'Alcohol or Smoking?',
                  fontWeight: FontWeight.w400,
                  fontSize: 18,
                  color: Color(0xff530630),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
                child: Obx(
                  () => Column(
                    children: controller.alcohol.map((item) {
                      bool isSelected =
                          controller.selectedAlcohol.value == item.name;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 11),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: isDisable == true
                                  ? () {}
                                  : () {
                                      controller.selectItem(item.name);
                                    },
                              child: Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                size: 20,
                                color: isSelected
                                    ? const Color(0xff9B1459)
                                    : const Color(0xff49454F),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Color(0xff1F2A37),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Obx(
                () => controller.selectedAlcohol.value == 'Yes'
                    ? Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 8,
                        ),
                        child: CustomField(
                          isDisable: isDisable,

                          controller: controller.alcoholOrSmokingFrequency,
                          lable: 'frequency',
                          hintText: 'frequency',
                          keyboardType: TextInputType.number,
                          changeBorderColor: false,
                        ),
                      )
                    : SizedBox(),
              ),
              if (gendar != 'Male')
                Padding(
                  padding: const EdgeInsets.only(left: 16, top: 16),
                  child: CustomText(
                    text: 'Q5. Are your periods regular?',
                    fontWeight: FontWeight.w400,
                    fontSize: 18,
                    color: Color(0xff530630),
                  ),
                ),
              if (gendar != 'Male')
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
                  child: Obx(
                    () => Column(
                      children: controller.periods.map((item) {
                        bool isSelected =
                            controller.selectedPeriods.value == item.name;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 11),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: isDisable == true
                                    ? () {}
                                    : () {
                                        controller.selectPeriods(item.name);
                                      },
                                child: Icon(
                                  isSelected
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_off,
                                  size: 20,
                                  color: isSelected
                                      ? const Color(0xff9B1459)
                                      : const Color(0xff49454F),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                item.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xff1F2A37),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              if (gendar != 'Male')
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
                  child: CustomText(
                    text: 'Any of the following apply to you:',
                    fontWeight: FontWeight.w400,
                    fontSize: 18,
                    color: Color(0xff530630),
                  ),
                ),
              if (gendar != 'Male')
                Obx(
                  () => Padding(
                    padding: const EdgeInsets.only(top: 19, left: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: controller.applyToYou.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 11),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: isDisable == true
                                    ? () {}
                                    : () {
                                        item.isSelected.value =
                                            !item.isSelected.value;
                                        //  print('-----------${controller.selectedApplyToYouList}');
                                      },
                                child: Container(
                                  height: 18,
                                  width: 18,
                                  decoration: BoxDecoration(
                                    color: item.isSelected.value
                                        ? const Color(0xff9B1459)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(2),
                                    border: Border.all(
                                      width: 2,
                                      color: item.isSelected.value
                                          ? const Color(0xff9B1459)
                                          : const Color(0xff49454F),
                                    ),
                                  ),
                                  child: item.isSelected.value
                                      ? Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 14,
                                          fontWeight: FontWeight.w600,
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              CustomText(
                                text: item.name,

                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xff1F2A37),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              if (gendar != 'Male')
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
                  child: CustomText(
                    text: 'Are you on:',
                    fontWeight: FontWeight.w400,
                    fontSize: 18,
                    color: Color(0xff530630),
                  ),
                ),
              if (gendar != 'Male')
                Obx(
                  () => Padding(
                    padding: const EdgeInsets.only(top: 19, left: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: controller.areYouOn.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 11),
                          child: Row(
                            children: [
                              GestureDetector(
                                onTap: isDisable == true
                                    ? () {}
                                    : () {
                                        item.isSelected.value =
                                            !item.isSelected.value;
                                        //  print('-----------${controller.selectedAreYouOnList}');
                                      },
                                child: Container(
                                  height: 18,
                                  width: 18,
                                  decoration: BoxDecoration(
                                    color: item.isSelected.value
                                        ? const Color(0xff9B1459)
                                        : Colors.transparent,
                                    borderRadius: BorderRadius.circular(2),
                                    border: Border.all(
                                      width: 2,
                                      color: item.isSelected.value
                                          ? const Color(0xff9B1459)
                                          : const Color(0xff49454F),
                                    ),
                                  ),
                                  child: item.isSelected.value
                                      ? Icon(
                                          Icons.check,
                                          color: Colors.white,
                                          size: 14,
                                          fontWeight: FontWeight.w600,
                                        )
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 8),
                              CustomText(
                                text: item.name,

                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xff1F2A37),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 28),
                child: CustomText(
                  text: gendar != 'Male'
                      ? 'Q6. Digestion & Elimination'
                      : 'Q5. Digestion & Elimination',
                  fontWeight: FontWeight.w400,
                  fontSize: 18,
                  color: Color(0xff530630),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 5),
                child: CustomText(
                  text: 'Do you experience:',
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: Color(0xff530630),
                ),
              ),
              Obx(
                () => Padding(
                  padding: const EdgeInsets.only(top: 19, left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: controller.digestionOrElimination.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 11),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: isDisable == true
                                  ? () {}
                                  : () {
                                      item.isSelected.value =
                                          !item.isSelected.value;
                                      //  print('-----------${controller.selectedDigestionOREliminationList}');
                                    },
                              child: Container(
                                height: 18,
                                width: 18,
                                decoration: BoxDecoration(
                                  color: item.isSelected.value
                                      ? const Color(0xff9B1459)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(2),
                                  border: Border.all(
                                    width: 2,
                                    color: item.isSelected.value
                                        ? const Color(0xff9B1459)
                                        : const Color(0xff49454F),
                                  ),
                                ),
                                child: item.isSelected.value
                                    ? Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 14,
                                        fontWeight: FontWeight.w600,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            CustomText(
                              text: item.name,

                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xff1F2A37),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 16),
                child: CustomText(
                  text: 'Frequency of bowel movements:',
                  fontWeight: FontWeight.w400,
                  fontSize: 18,
                  color: Color(0xff530630),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
                child: Obx(
                  () => Column(
                    children: controller.frequencyOfBowel.map((item) {
                      bool isSelected =
                          controller.selectedFrequencyOfBowel.value ==
                          item.name;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 11),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: isDisable == true
                                  ? () {}
                                  : () {
                                      controller.selectFrequencyOfBowel(
                                        item.name,
                                      );
                                    },
                              child: Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                size: 20,
                                color: isSelected
                                    ? const Color(0xff9B1459)
                                    : const Color(0xff49454F),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Color(0xff1F2A37),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 16),
                child: CustomText(
                  text: 'Q7. Sleep & Stress',
                  fontWeight: FontWeight.w400,
                  fontSize: 18,
                  color: Color(0xff530630),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
                child: CustomField(
                  isDisable: isDisable,

                  controller: controller.sleepStressSleepDuration,
                  lable: 'Sleep duration (avg hours/night)',
                  hintText: 'Sleep duration (avg hours/night):',
                  changeBorderColor: false,
                ),
              ),
              //
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 16),
                child: CustomText(
                  text: 'Quality of sleep:',
                  fontWeight: FontWeight.w400,
                  fontSize: 18,
                  color: Color(0xff530630),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
                child: Obx(
                  () => Column(
                    children: controller.qualityOfSleep.map((item) {
                      bool isSelected =
                          controller.selectedQualityOfSleep.value == item.name;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 11),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: isDisable == true
                                  ? () {}
                                  : () {
                                      controller.selectQualityOfSleep(
                                        item.name,
                                      );
                                    },
                              child: Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                size: 20,
                                color: isSelected
                                    ? const Color(0xff9B1459)
                                    : const Color(0xff49454F),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Color(0xff1F2A37),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              //
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 16),
                child: CustomText(
                  text: 'Stress level:',
                  fontWeight: FontWeight.w400,
                  fontSize: 18,
                  color: Color(0xff530630),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
                child: Obx(
                  () => Column(
                    children: controller.stressLevel.map((item) {
                      bool isSelected =
                          controller.selectedStressLevel.value == item.name;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 11),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: isDisable == true
                                  ? () {}
                                  : () {
                                      controller.selectStressLevel(item.name);
                                    },
                              child: Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                size: 20,
                                color: isSelected
                                    ? const Color(0xff9B1459)
                                    : const Color(0xff49454F),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Color(0xff1F2A37),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              //
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 16),
                child: CustomText(
                  text:
                      'Any diagnosed mental health conditions (anxiety/depression/etc.)?',
                  fontWeight: FontWeight.w400,
                  fontSize: 18,
                  color: Color(0xff530630),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
                child: Obx(
                  () => Column(
                    children: controller.mentalHealthConditions.map((item) {
                      bool isSelected =
                          controller.selectedMentalHealthConditions.value ==
                          item.name;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 11),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: isDisable == true
                                  ? () {}
                                  : () {
                                      controller.selectMentalHealthConditionsl(
                                        item.name,
                                      );
                                    },
                              child: Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                size: 20,
                                color: isSelected
                                    ? const Color(0xff9B1459)
                                    : const Color(0xff49454F),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Color(0xff1F2A37),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 16),
                child: CustomText(
                  text: 'Q8. Medication & Supplements',
                  fontWeight: FontWeight.w400,
                  fontSize: 18,
                  color: Color(0xff530630),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 12),
                child: CustomText(
                  text: 'Are you currently taking any prescribed medication?',
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: Color(0xff530630),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
                child: Obx(
                  () => Column(
                    children: controller.prescribedMedication.map((item) {
                      bool isSelected =
                          controller.selectedPrescribedMedication.value ==
                          item.name;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 11),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: isDisable == true
                                  ? () {}
                                  : () {
                                      controller.selectPrescribedMedication(
                                        item.name,
                                      );
                                    },
                              child: Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                size: 20,
                                color: isSelected
                                    ? const Color(0xff9B1459)
                                    : const Color(0xff49454F),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Color(0xff1F2A37),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Obx(
                () => controller.selectedPrescribedMedication.value == "Yes"
                    ? Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 16,
                        ),
                        child: CustomField(
                          isDisable: isDisable,

                          controller: controller.medicationSupplementsDetails,
                          lable: 'Please list',
                          hintText: 'Please list',
                          changeBorderColor: false,
                        ),
                      )
                    : SizedBox(),
              ),

              Padding(
                padding: const EdgeInsets.only(left: 16, top: 12),
                child: CustomText(
                  text: 'Do you take supplements?',
                  fontWeight: FontWeight.w400,
                  fontSize: 18,
                  color: Color(0xff530630),
                ),
              ),
              Obx(
                () => Padding(
                  padding: const EdgeInsets.only(top: 19, left: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: controller.supplements.map((item) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 11),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: isDisable == true
                                  ? () {}
                                  : () {
                                      item.isSelected.value =
                                          !item.isSelected.value;
                                      //  print('-----------${controller.selectedSupplementsList}');
                                    },
                              child: Container(
                                height: 18,
                                width: 18,
                                decoration: BoxDecoration(
                                  color: item.isSelected.value
                                      ? const Color(0xff9B1459)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(2),
                                  border: Border.all(
                                    width: 2,
                                    color: item.isSelected.value
                                        ? const Color(0xff9B1459)
                                        : const Color(0xff49454F),
                                  ),
                                ),
                                child: item.isSelected.value
                                    ? Icon(
                                        Icons.check,
                                        color: Colors.white,
                                        size: 14,
                                        fontWeight: FontWeight.w600,
                                      )
                                    : null,
                              ),
                            ),
                            const SizedBox(width: 8),
                            CustomText(
                              text: item.name,

                              fontSize: 16,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xff1F2A37),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Obx(
                () => controller.selectedSupplementsList.contains('Other')
                    ? Padding(
                        padding: const EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 16,
                        ),
                        child: CustomField(
                          isDisable: isDisable,

                          controller: controller.supplementsOther,
                          lable: 'Other Information',
                          hintText:
                              'Add few more words for describing your feeling',
                          changeBorderColor: false,
                        ),
                      )
                    : SizedBox(),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 16, bottom: 16),
                child: CustomText(
                  text: 'Q9. Lab Reports (Optional)',
                  fontWeight: FontWeight.w400,
                  fontSize: 18,
                  color: Color(0xff530630),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Obx(
                  () => GestureDetector(
                    onTap: isDisable == true
                        ? () {}
                        : () => controller.pickReport(),
                    child: Container(
                      height: 150,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Color(0xffFEF6FB),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: controller.report.value.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.network(
                                  controller.report.value,
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                ),
                              )
                            : controller.pickedReport.value == null
                            ? Image.asset('assets/icons/camra.png', height: 48)
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.file(
                                  File(controller.pickedReport.value!.path),
                                  fit: BoxFit.contain,
                                  width: double.infinity,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, top: 16, bottom: 16),
                child: CustomText(
                  text: 'Q10. Final Notes',
                  fontWeight: FontWeight.w400,
                  fontSize: 18,
                  color: Color(0xff530630),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 16, right: 16),
                child: CustomText(
                  text: 'Any other specific concerns you want to address?',
                  fontWeight: FontWeight.w400,
                  fontSize: 15,
                  color: Color(0xff530630),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16),
                child: CustomField(
                  isDisable: isDisable,

                  controller: controller.finalNotesConcerns,
                  lable: 'Specific concerns you want to address?',
                  hintText: 'Any other specific concerns you want to address?',
                  changeBorderColor: false,
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
                child: CustomText(
                  text:
                      'Are you ready to commit to a personalized nutrition plan?',
                  fontWeight: FontWeight.w400,
                  fontSize: 15,
                  color: Color(0xff530630),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 16),
                child: Obx(
                  () => Column(
                    children: controller.personalizedNutrition.map((item) {
                      bool isSelected =
                          controller.selectedPersonalizedNutrition.value ==
                          item.name;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 11),
                        child: Row(
                          children: [
                            GestureDetector(
                              onTap: isDisable == true
                                  ? () {}
                                  : () {
                                      controller.selectPersonalizedNutrition(
                                        item.name,
                                      );
                                    },
                              child: Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons.radio_button_off,
                                size: 20,
                                color: isSelected
                                    ? const Color(0xff9B1459)
                                    : const Color(0xff49454F),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              item.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w400,
                                color: Color(0xff1F2A37),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              // ── Custom Consultation Form (per dietician's template) ────
              Obx(() {
                if (controller.consultationTemplate.isEmpty) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(left: 16, top: 24, right: 16),
                  child: CustomText(
                    text: 'Additional Questions',
                    fontWeight: FontWeight.w500,
                    fontSize: 18,
                    color: Color(0xff530630),
                  ),
                );
              }),
              Obx(
                () => Column(
                  children: List.generate(
                    controller.consultationTemplate.length,
                    (index) => Padding(
                      padding: const EdgeInsets.only(
                        left: 16,
                        right: 16,
                        top: 12,
                      ),
                      child: _buildCustomFieldCard(
                        controller.consultationTemplate[index],
                      ),
                    ),
                  ),
                ),
              ),
              // ─────────────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 35,
                ),
                child: Obx(
                  () => CustomButton(
                    isLoading: controller.isConsultationSending.value,
                    onTap: isDisable == true
                        ? () {}
                        : () async {
                            await controller.sendConsultation(
                              patientId,
                              gendar == 'Male' ? false : true,
                            );
                          },
                    text: isEditMode
                        ? 'Update Consultation'
                        : 'Save Consultation',
                    isOutline: false,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Dynamic field renderer for the dietician's custom consultation form ──
  Widget _buildCustomFieldCard(ConsultationFormField field) {
    const accent = Color(0xff851653);
    const bg = Color(0xffFEF6FB);
    const border = Color(0xffFAA7E0);
    const labelColor = Color(0xff1F2A37);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  field.label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: labelColor,
                  ),
                ),
              ),
              if (field.required)
                const Text(
                  ' *',
                  style: TextStyle(color: accent, fontWeight: FontWeight.w700),
                ),
            ],
          ),
          const SizedBox(height: 8),
          _buildCustomFieldInput(field),
        ],
      ),
    );
  }

  Widget _buildCustomFieldInput(ConsultationFormField field) {
    switch (field.type) {
      case ConsultationFieldType.text:
        return _customTextInput(field, maxLines: 1);
      case ConsultationFieldType.textarea:
        return _customTextInput(field, maxLines: 4);
      case ConsultationFieldType.number:
        return _customTextInput(
          field,
          maxLines: 1,
          keyboardType: TextInputType.number,
        );
      case ConsultationFieldType.date:
        return _customDateInput(field);
      case ConsultationFieldType.yesNo:
        return _customSingleChoice(field, const ['Yes', 'No']);
      case ConsultationFieldType.singleChoice:
        return _customSingleChoice(field, field.options);
      case ConsultationFieldType.multiChoice:
        return _customMultiChoice(field, field.options);
    }
  }

  Widget _customTextInput(
    ConsultationFormField field, {
    required int maxLines,
    TextInputType? keyboardType,
  }) {
    final ctrl = controller.customTextControllerFor(field.fieldId);
    return TextField(
      controller: ctrl,
      enabled: !isDisable,
      maxLines: maxLines,
      keyboardType: keyboardType,
      onChanged: (v) => controller.setCustomAnswer(field.fieldId, v),
      decoration: InputDecoration(
        hintText: 'Type your answer...',
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 10,
        ),
        hintStyle: const TextStyle(color: Color(0xff9DA4AE), fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xffFAA7E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xffFAA7E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xff851653)),
        ),
      ),
      style: const TextStyle(fontSize: 13, color: Color(0xff1F2A37)),
    );
  }

  Widget _customDateInput(ConsultationFormField field) {
    final ctrl = controller.customTextControllerFor(field.fieldId);
    return Builder(
      builder: (context) => TextField(
        controller: ctrl,
        readOnly: true,
        enabled: !isDisable,
        onTap: isDisable
            ? null
            : () async {
                final initial = DateTime.tryParse(ctrl.text) ?? DateTime.now();
                final picked = await showDatePicker(
                  context: context,
                  initialDate: initial,
                  firstDate: DateTime(1900),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  final text =
                      '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                  ctrl.text = text;
                  controller.setCustomAnswer(field.fieldId, text);
                }
              },
        decoration: InputDecoration(
          hintText: 'Pick a date',
          filled: true,
          fillColor: Colors.white,
          suffixIcon: const Icon(Icons.event, color: Color(0xff851653)),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 10,
            vertical: 10,
          ),
          hintStyle: const TextStyle(color: Color(0xff9DA4AE), fontSize: 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xffFAA7E0)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xffFAA7E0)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xff851653)),
          ),
        ),
        style: const TextStyle(fontSize: 13, color: Color(0xff1F2A37)),
      ),
    );
  }

  /// Single choice → renders as RADIO buttons.
  Widget _customSingleChoice(
    ConsultationFormField field,
    List<String> options,
  ) {
    return Obx(() {
      final selected = (controller.customAnswerValues[field.fieldId] ?? '')
          .toString();
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: options.map((opt) {
          return InkWell(
            onTap: isDisable
                ? null
                : () => controller.setCustomAnswer(field.fieldId, opt),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Radio<String>(
                    value: opt,
                    groupValue: selected,
                    activeColor: const Color(0xff851653),
                    onChanged: isDisable
                        ? null
                        : (v) => controller.setCustomAnswer(
                            field.fieldId,
                            v ?? '',
                          ),
                  ),
                  Expanded(
                    child: Text(
                      opt,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xff1F2A37),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    });
  }

  /// Multiple choice → renders as CHECK BOXES.
  Widget _customMultiChoice(ConsultationFormField field, List<String> options) {
    return Obx(() {
      final raw = controller.customAnswerValues[field.fieldId];
      final selected = raw is List
          ? List<String>.from(raw.map((e) => e.toString()))
          : <String>[];
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: options.map((opt) {
          final isChecked = selected.contains(opt);
          return InkWell(
            onTap: isDisable
                ? null
                : () => controller.toggleMultiChoiceAnswer(field.fieldId, opt),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Checkbox(
                    value: isChecked,
                    activeColor: const Color(0xff851653),
                    onChanged: isDisable
                        ? null
                        : (_) => controller.toggleMultiChoiceAnswer(
                            field.fieldId,
                            opt,
                          ),
                  ),
                  Expanded(
                    child: Text(
                      opt,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xff1F2A37),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      );
    });
  }
}

// model
class DietOption {
  String name;
  RxBool isSelected;

  DietOption({required this.name, required bool selected})
    : isSelected = RxBool(selected);
}

class CustomDoctorQuestion {
  final TextEditingController questionController;
  final TextEditingController answerController;

  CustomDoctorQuestion({String question = '', String answer = ''})
    : questionController = TextEditingController(text: question),
      answerController = TextEditingController(text: answer);

  void dispose() {
    questionController.dispose();
    answerController.dispose();
  }
}

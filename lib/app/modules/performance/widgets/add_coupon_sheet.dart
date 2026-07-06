import 'package:docwellnesdoc/app/modules/performance/controllers/performance_controller.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_date_picker.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_field.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddCouponSheet extends StatelessWidget {
  final ScrollController scrollController;
  AddCouponSheet({super.key, required this.scrollController});

  final PerformanceController controller = Get.find<PerformanceController>();
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(height: 16),
        Center(
          child: Container(
            height: 4,
            width: 32,
            decoration: BoxDecoration(
              color: Color(0xff79747E),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 18, left: 12),
          child: Row(
            children: [
              IconButton(
                onPressed: () {
                  Get.back();
                },
                icon: Icon(Icons.arrow_back, color: Color(0xff1F2A37)),
              ),
              SizedBox(width: 10),
              CustomText(
                text: 'Discounts & Coupons',
                fontWeight: FontWeight.w400,
                fontSize: 20,
                color: Color(0xff1F2A37),
              ),
            ],
          ),
        ),

        Divider(color: Color(0xff9DA4AE)),
        SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: CustomField(
            changeBorderColor: false,
            controller: controller.couponNameController,
            lable: 'Discount Name',
            changeTextColor: Color(0xff4D5761),
          ),
        ),
        SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: CustomField(
            changeBorderColor: false,
            controller: controller.couponCodeController,
            lable: 'Discount Code',
            changeTextColor: Color(0xff4D5761),
          ),
        ),
        SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: CustomField(
            changeBorderColor: false,
            controller: controller.couponPercentageController,
            lable: 'Discount Percentage',
            keyboardType: TextInputType.number,
            changeTextColor: Color(0xff4D5761),
          ),
        ),
        SizedBox(height: 16),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16),

          child: DatePickerField(
            controller: controller.couponValidTillController,
            label: 'Valid Till',
            changeTextColor: Color(0xff49454F),
            changeBorderColor: Color(0xff6C737F),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CustomText(
                text: 'Set Active',
                fontWeight: FontWeight.w500,
                fontSize: 18,
                color: Color(0xff384250),
              ),

              // Custom switch
              Obx(
                () => GestureDetector(
                  onTap: () {
                    controller.isCouponActive.value =
                        !controller.isCouponActive.value;
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    width: 60,
                    height: 31,
                    padding: EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: controller.isCouponActive.value
                          ? Color(0xff851653)
                          : Colors.transparent,
                      border: Border.all(
                        color: controller.isCouponActive.value
                            ? Color(0xff851653)
                            : Color(0xffCCCCCC),
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: AnimatedAlign(
                      duration: Duration(milliseconds: 200),
                      alignment: controller.isCouponActive.value
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: controller.isCouponActive.value
                              ? Colors.white
                              : Color(0xffCCCCCC),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 30),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Obx(
            () => CustomButton(
              isLoading: controller.isCouponSaving.value,
              onTap: () {
                if (controller.isCouponEditMode.value) {
                  controller.updateCouponById();
                } else {
                  controller.addCoupon();
                }
              },
              text: controller.isCouponEditMode.value
                  ? 'Update Coupon'
                  : 'Add Coupon',
              isOutline: false,
              fontSize: 14,
            ),
          ),
        ),
        SizedBox(height: 24),
        Obx(
          () => controller.isCouponEditMode.value
              ? Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CustomButton(
                    onTap: () {
                      controller.deleteCouponById(
                        controller.editingCouponId.value,
                      );
                    },
                    text: 'Delete Coupon',
                    isOutline: true,
                    fontSize: 14,
                  ),
                )
              : SizedBox.shrink(),
        ),
      ],
    );
  }
}

import 'dart:io';

import 'package:docwellnesdoc/app/modules/performance/controllers/performance_controller.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddUpdateQuotes extends StatelessWidget {
  final ScrollController scrollController;
  AddUpdateQuotes({super.key, required this.scrollController});

  final PerformanceController controller = Get.find<PerformanceController>();
  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
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
                  text: controller.isQuoteEditMode.value
                      ? 'Edit Quote'
                      : 'Add Quote',
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
            child: GestureDetector(
              onTap: () => controller.pickQuoteImage(),
              child: Container(
                height: 196,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Color(0xffFEF6FB),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: controller.pickedQuoteImage.value == null
                      ? Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset('assets/icons/camra.png', height: 48),
                            if (controller.isQuoteEditMode.value) ...[
                              SizedBox(height: 8),
                              CustomText(
                                text: 'Tap to upload new image',
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: Color(0xff6C737F),
                              ),
                            ],
                          ],
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: Image.file(
                            File(controller.pickedQuoteImage.value!.path),
                            fit: BoxFit.contain,
                            width: double.infinity,
                          ),
                        ),
                ),
              ),
            ),
          ),
          SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: controller.quoteTextController,
              maxLines: 3,
              minLines: 2,
              decoration: InputDecoration(
                hintText: 'Add quote text (optional)',
                hintStyle: TextStyle(
                  color: Color(0xff9DA4AE),
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
                filled: true,
                fillColor: Color(0xffFEF6FB),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xffE5E7EB)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xffE5E7EB)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Color(0xff851653)),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
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
                GestureDetector(
                  onTap: () {
                    controller.isQuotesSelected.value =
                        !controller.isQuotesSelected.value;
                  },
                  child: AnimatedContainer(
                    duration: Duration(milliseconds: 200),
                    width: 60,
                    height: 31,
                    padding: EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: controller.isQuotesSelected.value
                          ? Color(0xff851653)
                          : Colors.transparent,
                      border: Border.all(
                        color: controller.isQuotesSelected.value
                            ? Color(0xff851653)
                            : Color(0xffCCCCCC),
                      ),
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: AnimatedAlign(
                      duration: Duration(milliseconds: 200),
                      alignment: controller.isQuotesSelected.value
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: controller.isQuotesSelected.value
                              ? Colors.white
                              : Color(0xffCCCCCC),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 18),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: controller.isQuoteSaving.value
                ? Center(
                    child: CircularProgressIndicator(color: Color(0xff851653)),
                  )
                : CustomButton(
                    onTap: () => controller.isQuoteEditMode.value
                        ? controller.updateQuoteById()
                        : controller.addQuote(),
                    text: controller.isQuoteEditMode.value
                        ? 'Save Changes'
                        : 'Add Quote',
                    isOutline: false,
                    fontSize: 14,
                  ),
          ),
          SizedBox(height: 23),
        ],
      ),
    );
  }
}

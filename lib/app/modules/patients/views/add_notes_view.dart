import 'package:docwellnesdoc/app/utils/common_widgets/custom_button.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_field.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class AddNotesView extends StatefulWidget {
  const AddNotesView({super.key});

  @override
  State<AddNotesView> createState() => _AddNotesViewState();
}

class _AddNotesViewState extends State<AddNotesView> {
  DateTime? selectedDate;

  Future<void> pickDate() async {
    final DateTime? date = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (date != null) {
      setState(() {
        selectedDate = date;
      });
    }
  }

  String get formattedDate {
    if (selectedDate == null) return "Select date";
    return "${selectedDate!.month.toString().padLeft(2, '0')}/"
        "${selectedDate!.day.toString().padLeft(2, '0')}/"
        "${selectedDate!.year}";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        leading: IconButton(
          onPressed: () {
            Get.back();
          },
          icon: Icon(Icons.arrow_back, color: Color(0xff1F2A37)),
        ),
        title: CustomText(
          text: 'Notes',
          fontWeight: FontWeight.w400,
          fontSize: 21,
          color: Color(0xff1F2A37),
        ),
        titleSpacing: 0,
        actions: [
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 7, vertical: 1.5),
                height: 24,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(7),
                  color: Color(0xffFCE7F6),
                  border: Border.all(color: Color(0xffEF45B2)),
                ),
                child: Center(
                  child: CustomText(
                    text: formattedDate != 'Select date'
                        ? 'Mo. $formattedDate'
                        : formattedDate,
                    fontWeight: FontWeight.w500,
                    fontSize: 13.5,
                    color: Color(0xff851653),
                  ),
                ),
              ),
              SizedBox(width: 12),
              GestureDetector(
                onTap: pickDate,
                child: Image.asset(
                  'assets/icons/second_calendar.png',
                  height: 22,
                  width: 22,
                  fit: BoxFit.contain,
                ),
              ),
              SizedBox(width: 16),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.only(left: 16, right: 16, top: 30),
        child: Column(
          children: [
            CustomField(
              controller: TextEditingController(),
              lable: 'Description',
              hintText: 'Add few more words for describing food',
              changeBorderColor: false,
              maxLines: 6,
            ),
            SizedBox(height: 100),
            CustomButton(
              onTap: () {},
              text: 'Submit Notes',
              isOutline: false,
              fontSize: 14,
            ),
          ],
        ),
      ),
    );
  }
}

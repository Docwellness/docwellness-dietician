import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';

class CookingStepsTab extends StatefulWidget {
  final List<String> cookingSteps;

  const CookingStepsTab({super.key, this.cookingSteps = const []});

  @override
  State<CookingStepsTab> createState() => _CookingStepsTabState();
}

class _CookingStepsTabState extends State<CookingStepsTab> {
  List<String> get steps => widget.cookingSteps.isNotEmpty
      ? widget.cookingSteps
      : [
          'Boil water for 5 minutes with mixture of onion and garlic.',
          'Add vegetables and cook for 10 minutes.',
          'Season with salt and pepper to taste.',
        ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          ListView.builder(
            physics: NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: steps.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(left: 9, right: 9),
                child: Column(
                  children: [
                    Divider(color: Color(0xffFCCEEF), thickness: 0.6),
                    Padding(
                      padding: const EdgeInsets.only(
                        left: 10,
                        right: 16,
                        top: 7,
                      ),
                      child: Row(
                        children: [
                          Container(
                            height: 40,
                            width: 40,
                            decoration: BoxDecoration(
                              color: Color(0xffFCE7F6),
                              borderRadius: BorderRadius.circular(64),
                            ),
                            child: Center(
                              child: CustomText(
                                text: "${index + 1}",

                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Color(0xff851653),
                              ),
                            ),
                          ),

                          SizedBox(width: 16),
                          Expanded(
                            child: CustomText(
                              text: steps[index],
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Color(0xff384250),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),

          SizedBox(height: 30),
        ],
      ),
    );
  }
}

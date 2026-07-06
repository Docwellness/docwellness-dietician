/// Model for patient tracking data (calorie intake, weight trend, BMI)
class TrackingData {
  final String period;
  final DateRangeLabel dateRange;
  final int currentIndex;
  final double currentWeight;
  final double currentBmi;
  final int plannedDailyCalories;
  final int tdee;
  final List<CalorieDataPoint> calorieData;
  final List<WeightDataPoint> weightTrend;
  final List<BmiDataPoint> bmiTrend;

  TrackingData({
    required this.period,
    required this.dateRange,
    required this.currentIndex,
    required this.currentWeight,
    required this.currentBmi,
    required this.plannedDailyCalories,
    required this.tdee,
    required this.calorieData,
    required this.weightTrend,
    required this.bmiTrend,
  });

  factory TrackingData.fromJson(Map<String, dynamic> json) {
    return TrackingData(
      period: json['period'] ?? 'week',
      dateRange: DateRangeLabel.fromJson(json['dateRange'] ?? {}),
      currentIndex: json['currentIndex'] ?? 0,
      currentWeight: (json['currentWeight'] ?? 0).toDouble(),
      currentBmi: (json['currentBmi'] ?? 0).toDouble(),
      plannedDailyCalories: json['plannedDailyCalories'] ?? 0,
      tdee: json['tdee'] ?? 0,
      calorieData:
          (json['calorieData'] as List?)
              ?.map((e) => CalorieDataPoint.fromJson(e))
              .toList() ??
          [],
      weightTrend:
          (json['weightTrend'] as List?)
              ?.map((e) => WeightDataPoint.fromJson(e))
              .toList() ??
          [],
      bmiTrend:
          (json['bmiTrend'] as List?)
              ?.map((e) => BmiDataPoint.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class DateRangeLabel {
  final String start;
  final String end;

  DateRangeLabel({required this.start, required this.end});

  factory DateRangeLabel.fromJson(Map<String, dynamic> json) {
    return DateRangeLabel(start: json['start'] ?? '', end: json['end'] ?? '');
  }
}

class CalorieDataPoint {
  final String label;
  final String? date;
  final String? dateRange;
  final int calories;
  final int? totalCalories;
  final int plannedCalories;
  final int? mealsLogged;
  final int? daysLogged;

  CalorieDataPoint({
    required this.label,
    this.date,
    this.dateRange,
    required this.calories,
    this.totalCalories,
    required this.plannedCalories,
    this.mealsLogged,
    this.daysLogged,
  });

  factory CalorieDataPoint.fromJson(Map<String, dynamic> json) {
    return CalorieDataPoint(
      label: json['label'] ?? '',
      date: json['date'],
      dateRange: json['dateRange'],
      calories: json['calories'] ?? 0,
      totalCalories: json['totalCalories'],
      plannedCalories: json['plannedCalories'] ?? 0,
      mealsLogged: json['mealsLogged'],
      daysLogged: json['daysLogged'],
    );
  }
}

class WeightDataPoint {
  final String label;
  final String date;
  final double weight;

  WeightDataPoint({
    required this.label,
    required this.date,
    required this.weight,
  });

  factory WeightDataPoint.fromJson(Map<String, dynamic> json) {
    return WeightDataPoint(
      label: json['label'] ?? '',
      date: json['date'] ?? '',
      weight: (json['weight'] ?? 0).toDouble(),
    );
  }
}

class BmiDataPoint {
  final String label;
  final String date;
  final double bmi;
  final double weight;

  BmiDataPoint({
    required this.label,
    required this.date,
    required this.bmi,
    required this.weight,
  });

  factory BmiDataPoint.fromJson(Map<String, dynamic> json) {
    return BmiDataPoint(
      label: json['label'] ?? '',
      date: json['date'] ?? '',
      bmi: (json['bmi'] ?? 0).toDouble(),
      weight: (json['weight'] ?? 0).toDouble(),
    );
  }
}

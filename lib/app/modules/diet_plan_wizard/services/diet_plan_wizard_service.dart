import 'package:docwellnesdoc/app/utils/functions/dio_function.dart';
import 'package:docwellnesdoc/main.dart';
import 'package:flutter/foundation.dart';

/// Wraps the Phase 3 "Clever UX" endpoints (Exception Review, Supplement
/// Injection) added to routes/dietician.js/dietPlanController.js alongside
/// the deterministic diet-plan engine, plus the v4.0 ingredient-versioning
/// endpoints further below. Week Tweak/Swap vs Scale methods were removed
/// as part of v4.0's hard cutover - see finalize_step_controller.dart's
/// header comment; those days-array endpoints no longer exist on the
/// backend either. Kept separate from PatientService (which already has
/// 700+ lines) rather than growing that file further - the wizard's own
/// service, same request/response convention (ApiService.request, check
/// statusCode==200 && data['success']==true, return response.data or null).
class DietPlanWizardService {
  final ApiService service = ApiService();

  String _base(String patientId, String dietPlanId) =>
      '/patients/$patientId/diet-plans/$dietPlanId';

  Future<dynamic> getWeekDays({
    required String patientId,
    required String dietPlanId,
    required int week,
  }) async {
    try {
      final response = await service.request(
        endPoint: '${_base(patientId, dietPlanId)}/weeks/$week/days',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data;
      }
    } catch (e) {
      debugPrint('getWeekDays error: $e');
    }
    return null;
  }

  Future<dynamic> getExceptions({
    required String patientId,
    required String dietPlanId,
    required int week,
  }) async {
    try {
      final response = await service.request(
        endPoint: '${_base(patientId, dietPlanId)}/weeks/$week/exceptions',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response != null &&
          response.statusCode == 200 &&
          response.data['success'] == true) {
        return response.data;
      }
    } catch (e) {
      debugPrint('getExceptions error: $e');
    }
    return null;
  }

  Future<dynamic> upsertSupplement({
    required String patientId,
    required String dietPlanId,
    required int week,
    required String dayGroup,
    required String servingTime,
    required String supplementId,
    String? dosage,
    String? instructions,
    required String timingAnchor,
  }) async {
    try {
      final response = await service.request(
        endPoint: '${_base(patientId, dietPlanId)}/supplements',
        method: 'POST',
        headers: {'Authorization': 'Bearer $token'},
        data: {
          'week': week,
          'dayGroup': dayGroup,
          'servingTime': servingTime,
          'supplementId': supplementId,
          if (dosage != null) 'dosage': dosage,
          if (instructions != null) 'instructions': instructions,
          'timingAnchor': timingAnchor,
        },
      );
      if (response != null && response.data is Map) return response.data;
    } catch (e) {
      debugPrint('upsertSupplement error: $e');
    }
    return null;
  }

  // ============================================================
  // v4.0: Ingredient-Level Portioning + Recipe Versioning - wraps
  // routes/dietician.js's "Ingredient-Level Portioning + Recipe Versioning"
  // block (controllers/dietician/planItemController.js). Only meaningful for
  // a DietPlan whose dataModel == 'plan-item' - see WizardController.dataModel.
  // ============================================================

  Future<dynamic> generateMenu({
    required String patientId,
    required String dietPlanId,
    List<int>? weekNumbers,
    bool restrictNonVegToDayGroups = false,
    Map<String, dynamic>? calorieStrategy,
    Map<String, dynamic>? macroStrategy,
  }) async {
    try {
      final response = await service.request(
        endPoint: '${_base(patientId, dietPlanId)}/generate-menu',
        method: 'POST',
        headers: {'Authorization': 'Bearer $token'},
        data: {
          if (weekNumbers != null) 'weekNumbers': weekNumbers,
          'restrictNonVegToDayGroups': restrictNonVegToDayGroups,
          // Only sent on a regenerate where the dietician changed targets;
          // the backend persists them to the plan before building the menu.
          if (calorieStrategy != null) 'calorieStrategy': calorieStrategy,
          if (macroStrategy != null) 'macroStrategy': macroStrategy,
        },
      );
      if (response != null && response.data is Map) return response.data;
    } catch (e) {
      debugPrint('generateMenu error: $e');
    }
    return null;
  }

  Future<dynamic> createCustomVersion({
    required String patientId,
    required String dietPlanId,
    required String planItemId,
    required List<Map<String, dynamic>> ingredients,
  }) async {
    try {
      final response = await service.request(
        endPoint: '${_base(patientId, dietPlanId)}/create-custom-version',
        method: 'POST',
        headers: {'Authorization': 'Bearer $token'},
        data: {'planItemId': planItemId, 'ingredients': ingredients},
      );
      if (response != null && response.data is Map) return response.data;
    } catch (e) {
      debugPrint('createCustomVersion error: $e');
    }
    return null;
  }

  /// Applies an AI-regenerated recipe snapshot (see recipe_details.dart's
  /// "Update AI Inputs"/"Update Existing") to ONE plan item - unlike
  /// [createCustomVersion] above, `recipe` carries free-text
  /// name/quantity/unit ingredients (not yet resolved to FoodItem ids); the
  /// backend resolves them and creates a new RecipeVersion under this item's
  /// existing parentRecipeId, never touching the shared Recipe document.
  Future<dynamic> updateItemRecipeVersion({
    required String patientId,
    required String dietPlanId,
    required String planItemId,
    required Map<String, dynamic> recipe,
  }) async {
    try {
      final response = await service.request(
        endPoint: '${_base(patientId, dietPlanId)}/update-item-recipe-version',
        method: 'POST',
        headers: {'Authorization': 'Bearer $token'},
        data: {'planItemId': planItemId, 'recipe': recipe},
      );
      if (response != null && response.data is Map) return response.data;
    } catch (e) {
      debugPrint('updateItemRecipeVersion error: $e');
    }
    return null;
  }

  Future<dynamic> autoBalanceItem({
    required String patientId,
    required String dietPlanId,
    required String planItemId,
    required double targetCalories,
  }) async {
    try {
      final response = await service.request(
        endPoint: '${_base(patientId, dietPlanId)}/auto-balance',
        method: 'POST',
        headers: {'Authorization': 'Bearer $token'},
        data: {'scope': 'item', 'planItemId': planItemId, 'targetCalories': targetCalories},
      );
      if (response != null && response.data is Map) return response.data;
    } catch (e) {
      debugPrint('autoBalanceItem error: $e');
    }
    return null;
  }

  Future<dynamic> autoBalanceDay({
    required String patientId,
    required String dietPlanId,
    required String dayPlanId,
    required double targetDailyCalories,
  }) async {
    try {
      final response = await service.request(
        endPoint: '${_base(patientId, dietPlanId)}/auto-balance',
        method: 'POST',
        headers: {'Authorization': 'Bearer $token'},
        data: {'scope': 'day', 'dayPlanId': dayPlanId, 'targetDailyCalories': targetDailyCalories},
      );
      if (response != null && response.data is Map) return response.data;
    } catch (e) {
      debugPrint('autoBalanceDay error: $e');
    }
    return null;
  }

  Future<dynamic> autoBalanceWeek({
    required String patientId,
    required String dietPlanId,
    required int week,
    required double targetDailyCalories,
  }) async {
    try {
      final response = await service.request(
        endPoint: '${_base(patientId, dietPlanId)}/auto-balance',
        method: 'POST',
        headers: {'Authorization': 'Bearer $token'},
        data: {'scope': 'week', 'week': week, 'targetDailyCalories': targetDailyCalories},
      );
      if (response != null && response.data is Map) return response.data;
    } catch (e) {
      debugPrint('autoBalanceWeek error: $e');
    }
    return null;
  }

  /// Auto-balances EVERY generated week of the plan, not just one. The
  /// Refine Portions step's one-shot entry balance uses this so a Silver
  /// plan's weeks 2-4 (generated up front, never shown in the single-week
  /// Refine UI) don't stay at raw portions and block finalize's whole-plan
  /// +/-5% activation gate.
  Future<dynamic> autoBalancePlan({
    required String patientId,
    required String dietPlanId,
    required double targetDailyCalories,
  }) async {
    try {
      final response = await service.request(
        endPoint: '${_base(patientId, dietPlanId)}/auto-balance',
        method: 'POST',
        headers: {'Authorization': 'Bearer $token'},
        data: {'scope': 'plan', 'targetDailyCalories': targetDailyCalories},
      );
      if (response != null && response.data is Map) return response.data;
    } catch (e) {
      debugPrint('autoBalancePlan error: $e');
    }
    return null;
  }

  Future<dynamic> getWeekPlanItems({
    required String patientId,
    required String dietPlanId,
    required int week,
  }) async {
    try {
      final response = await service.request(
        endPoint: '${_base(patientId, dietPlanId)}/weeks/$week/plan-items',
        method: 'GET',
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response != null && response.statusCode == 200 && response.data['success'] == true) {
        return response.data;
      }
    } catch (e) {
      debugPrint('getWeekPlanItems error: $e');
    }
    return null;
  }

  Future<dynamic> swapRecipeVersion({
    required String patientId,
    required String dietPlanId,
    required String planItemId,
    required String newParentRecipeId,
  }) async {
    try {
      final response = await service.request(
        endPoint: '${_base(patientId, dietPlanId)}/swap-recipe-version',
        method: 'POST',
        headers: {'Authorization': 'Bearer $token'},
        data: {'planItemId': planItemId, 'newParentRecipeId': newParentRecipeId},
      );
      if (response != null && response.data is Map) return response.data;
    } catch (e) {
      debugPrint('swapRecipeVersion error: $e');
    }
    return null;
  }

  Future<dynamic> upsertTimelineSupplement({
    required String patientId,
    required String dietPlanId,
    required int week,
    required String dayGroup,
    required String servingTime,
    required String supplementRecipeId,
    String? dosage,
    String? instructions,
    required String timingAnchor,
  }) async {
    try {
      final response = await service.request(
        endPoint: '${_base(patientId, dietPlanId)}/timeline-supplements',
        method: 'POST',
        headers: {'Authorization': 'Bearer $token'},
        data: {
          'week': week,
          'dayGroup': dayGroup,
          'servingTime': servingTime,
          'supplementRecipeId': supplementRecipeId,
          if (dosage != null) 'dosage': dosage,
          if (instructions != null) 'instructions': instructions,
          'timingAnchor': timingAnchor,
        },
      );
      if (response != null && response.data is Map) return response.data;
    } catch (e) {
      debugPrint('upsertTimelineSupplement error: $e');
    }
    return null;
  }

  Future<dynamic> finalizePlanItemWeek({
    required String patientId,
    required String dietPlanId,
  }) async {
    try {
      final response = await service.request(
        endPoint: '${_base(patientId, dietPlanId)}/finalize-plan-item-week',
        method: 'POST',
        headers: {'Authorization': 'Bearer $token'},
        data: {},
      );
      if (response != null && response.data is Map) return response.data;
    } catch (e) {
      debugPrint('finalizePlanItemWeek error: $e');
    }
    return null;
  }

  /// Step 2: add an extra recipe to a meal slot (distinct from swap, which
  /// replaces the existing item's recipe - this adds a new, independent one).
  Future<dynamic> addPlanItem({
    required String patientId,
    required String dietPlanId,
    required String mealSlotId,
    required String recipeId,
  }) async {
    try {
      final response = await service.request(
        endPoint: '${_base(patientId, dietPlanId)}/plan-items',
        method: 'POST',
        headers: {'Authorization': 'Bearer $token'},
        data: {'mealSlotId': mealSlotId, 'recipeId': recipeId},
      );
      if (response != null && response.data is Map) return response.data;
    } catch (e) {
      debugPrint('addPlanItem error: $e');
    }
    return null;
  }

  /// Step 2: remove one item from a meal slot entirely, no replacement.
  Future<dynamic> removePlanItem({
    required String patientId,
    required String dietPlanId,
    required String planItemId,
  }) async {
    try {
      final response = await service.request(
        endPoint: '${_base(patientId, dietPlanId)}/plan-items/$planItemId',
        method: 'DELETE',
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response != null && response.data is Map) return response.data;
    } catch (e) {
      debugPrint('removePlanItem error: $e');
    }
    return null;
  }

  /// Step 3: set/clear a plan item's `pinned` flag. Saving a hand-edited
  /// portion pins it automatically on the backend - this is the Refine
  /// Portions card's "Edited" badge tapping through to unpin, returning the
  /// item to "Auto Adjust"'s pool. Does not change any portion.
  Future<dynamic> setPinned({
    required String patientId,
    required String dietPlanId,
    required String planItemId,
    required bool pinned,
  }) async {
    try {
      final response = await service.request(
        endPoint: '${_base(patientId, dietPlanId)}/plan-items/$planItemId',
        method: 'PATCH',
        headers: {'Authorization': 'Bearer $token'},
        data: {'pinned': pinned},
      );
      if (response != null && response.data is Map) return response.data;
    } catch (e) {
      debugPrint('setPinned error: $e');
    }
    return null;
  }
}

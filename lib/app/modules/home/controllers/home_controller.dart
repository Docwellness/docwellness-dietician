import 'dart:async';

import 'package:docwellnesdoc/app/models/patient_request_model.dart';
import 'package:docwellnesdoc/app/modules/chat/controllers/chat_controller.dart';
import 'package:docwellnesdoc/app/modules/home/services/home_service.dart';
import 'package:docwellnesdoc/app/modules/notifications/services/notification_service.dart';
import 'package:docwellnesdoc/app/modules/patients/controllers/patients_controller.dart';
import 'package:docwellnesdoc/app/modules/performance/controllers/performance_controller.dart';
import 'package:docwellnesdoc/app/modules/performance/services/coupon_service.dart';
import 'package:docwellnesdoc/app/modules/receipes/controllers/receipes_controller.dart';
import 'package:docwellnesdoc/app/modules/receipes/services/recipe_service.dart';
import 'package:docwellnesdoc/app/services/socket_service.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

class HomeController extends GetxController {
  final HomeService service = HomeService();
  final RecipeService _recipeService = RecipeService();
  final NotificationService _notifService = NotificationService();
  final CouponService _couponService = CouponService();
  RxInt selectedIndex = 0.obs;
  RxBool showHomeLoading = false.obs;

  RxList<PatientRequestModel> allRequestedPatientList =
      <PatientRequestModel>[].obs;

  // Recipe categories for home display
  RxList<RecipeCategory> recipeCategories = <RecipeCategory>[].obs;
  RxBool isLoadingCategories = false.obs;

  // Filtered list: only Unpaid and Paid for dashboard display
  List<PatientRequestModel> get filteredPatientRequests =>
      allRequestedPatientList
          .where((e) => e.status == 'Unpaid' || e.status == 'Paid')
          .toList();

  List<PatientRequestModel> get pendingPaymentRequests =>
      allRequestedPatientList
          .where(
            (e) =>
                e.status == 'PaymentRequested' ||
                e.status == 'PaymentSubmitted',
          )
          .toList();

  // Dashboard action tile stats
  RxInt messagesReceived = 0.obs;
  RxInt reviewLoggedData = 0.obs;
  RxInt closingClients = 0.obs;
  RxInt didExtremelyWell = 0.obs;
  RxInt needAttention = 0.obs;

  // Patient lists per action category
  RxList<Map<String, String>> messagesReceivedPatients =
      <Map<String, String>>[].obs;
  RxList<Map<String, String>> reviewLoggedPatients =
      <Map<String, String>>[].obs;
  RxList<Map<String, String>> closingClientsPatients =
      <Map<String, String>>[].obs;
  RxList<Map<String, String>> didExtremelyWellPatients =
      <Map<String, String>>[].obs;
  RxList<Map<String, String>> needAttentionPatients =
      <Map<String, String>>[].obs;
  RxList<Map<String, String>> needAttentionHistory =
      <Map<String, String>>[].obs;

  // Notification badge count
  RxInt notificationUnreadCount = 0.obs;

  // Coupon count for home dashboard
  RxInt activeCouponCount = 0.obs;

  StreamSubscription? _notifSub;
  StreamSubscription? _messageSub;
  Timer? _dashboardDebounce;

  @override
  void onInit() {
    loadHomeData();
    _listenForNotifications();
    _listenForMessages();
    super.onInit();
  }

  @override
  void onClose() {
    _notifSub?.cancel();
    _messageSub?.cancel();
    _dashboardDebounce?.cancel();
    super.onClose();
  }

  void _listenForNotifications() {
    final socket = Get.find<SocketService>();
    _notifSub = socket.onNotification.listen((data) {
      notificationUnreadCount.value++;
      // Also refresh dashboard stats when a chat notification arrives
      if (data['type'] == 'chat') {
        _dashboardDebounce?.cancel();
        _dashboardDebounce = Timer(const Duration(seconds: 1), () {
          fetchDashboardStats();
        });
      }
    });
  }

  /// Listen for incoming messages to update "Messages Received" live
  void _listenForMessages() {
    try {
      final socket = Get.find<SocketService>();
      _messageSub = socket.onMessage.listen((data) {
        debugPrint(
          '🏠 HomeController received socket message: type=${data['type']}',
        );
        // Skip ACKs (our own sent messages)
        if (data['type'] == 'ack') return;
        // Debounce: only refresh once even if many messages arrive quickly
        _dashboardDebounce?.cancel();
        _dashboardDebounce = Timer(const Duration(seconds: 1), () {
          debugPrint('🏠 Debounced dashboard refresh triggered');
          fetchDashboardStats();
        });
      });
      debugPrint('🏠 HomeController: message listener registered');
    } catch (e) {
      debugPrint('🏠 HomeController: failed to register message listener: $e');
    }
  }

  Future<void> loadHomeData() async {
    showHomeLoading.value = true;
    await Future.wait([
      getAllPatientRequest(),
      fetchRecipeCategories(),
      fetchDashboardStats(),
      fetchNotificationCount(),
      fetchCouponCount(),
    ]);
    showHomeLoading.value = false;
  }

  Future<void> refreshHomeData() async {
    await Future.wait([
      getAllPatientRequest(),
      fetchRecipeCategories(),
      fetchDashboardStats(),
      fetchNotificationCount(),
      fetchCouponCount(),
    ]);
  }

  Future<void> fetchRecipeCategories() async {
    isLoadingCategories.value = true;
    try {
      final result = await _recipeService.getRecipeCategories();
      recipeCategories.value = result;
    } catch (e) {
      debugPrint('Error fetching recipe categories: $e');
    } finally {
      isLoadingCategories.value = false;
    }
  }

  void changeTab(int index) {
    selectedIndex.value = index;
  }

  void onTabSelected(int index) {
    // Refresh coupon count when returning to Home tab
    if (index == 0) {
      fetchCouponCount();
    }
    switch (index) {
      case 1:
        Get.put(PatientsController());
        break;
      case 2:
        Get.put(ReceipesController());
        break;
      case 3:
        Get.put(PerformanceController());
        break;
      case 4:
        Get.put(ChatController());
        break;
    }
  }

  Future<void> getAllPatientRequest() async {
    try {
      final response = await service.getAllRequestedPatients();

      if (response != null) {
        final requests = (response['data'] as List)
            .map((e) => PatientRequestModel.fromJson(e))
            .toList();

        // Keep newest requests at the top.
        // If createdAt/updatedAt is available, sort descending by it.
        // Otherwise fall back to reversing the API order (assumed ascending).
        final hasTimestamps = requests.any(
          (r) => r.createdAt != null || r.updatedAt != null,
        );
        if (hasTimestamps) {
          requests.sort((a, b) {
            final aTime =
                a.createdAt ??
                a.updatedAt ??
                DateTime.fromMillisecondsSinceEpoch(0);
            final bTime =
                b.createdAt ??
                b.updatedAt ??
                DateTime.fromMillisecondsSinceEpoch(0);
            return bTime.compareTo(aTime);
          });
        } else {
          allRequestedPatientList.value = requests.reversed.toList();
          return;
        }

        allRequestedPatientList.value = requests;
      }
    } catch (e) {
      debugPrint('-------------$e');
    }
  }

  List<Map<String, String>> _parsePatientList(dynamic list) {
    if (list == null || list is! List) return [];
    return list
        .map<Map<String, String>>(
          (e) => {
            'patientId': (e['patientId'] ?? '').toString(),
            'patientName': (e['patientName'] ?? 'Patient').toString(),
          },
        )
        .toList();
  }

  Future<void> fetchDashboardStats() async {
    try {
      final data = await service.getDashboardStats();
      if (data != null) {
        debugPrint(
          '📊 Dashboard stats: messages=${data['messagesReceived']}, review=${data['reviewLoggedData']}',
        );
        messagesReceived.value = data['messagesReceived'] ?? 0;
        reviewLoggedData.value = data['reviewLoggedData'] ?? 0;
        closingClients.value = data['closingClients'] ?? 0;
        didExtremelyWell.value = data['didExtremelyWell'] ?? 0;
        needAttention.value = data['needAttention'] ?? 0;

        messagesReceivedPatients.value = _parsePatientList(
          data['messagesReceivedPatients'],
        );
        reviewLoggedPatients.value = _parsePatientList(
          data['reviewLoggedPatients'],
        );
        closingClientsPatients.value = _parsePatientList(
          data['closingClientsPatients'],
        );
        didExtremelyWellPatients.value = _parsePatientList(
          data['didExtremelyWellPatients'],
        );
        needAttentionPatients.value = _parsePatientList(
          data['needAttentionPatients'],
        );
        needAttentionHistory.value = _parsePatientList(
          data['needAttentionHistory'],
        );
      }
    } catch (e) {
      debugPrint('Dashboard stats error: $e');
    }
  }

  Future<void> fetchNotificationCount() async {
    notificationUnreadCount.value = await _notifService.getUnreadCount();
  }

  /// Acknowledge a need-attention patient (mark as read), then refresh stats
  Future<void> acknowledgeNeedAttention(String patientId) async {
    await service.acknowledgeNeedAttention(patientId);
    await fetchDashboardStats();
  }

  Future<void> fetchCouponCount() async {
    final coupons = await _couponService.getCoupons();
    activeCouponCount.value = coupons.length;
  }
}

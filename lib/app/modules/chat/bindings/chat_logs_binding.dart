import 'package:get/get.dart';
import '../controllers/chat_logs_controller.dart';

class ChatLogsBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ChatLogsController>(
      () => ChatLogsController(),
    );
  }
}

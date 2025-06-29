import 'package:get/get.dart';
import '../models/train.dart';

class TrainListController extends GetxController {
  final trainData = Rxn<Train>();
  final errorMessage = RxnString();

  @override
  void onInit() {
    super.onInit();
    try {
      final args = Get.arguments;
      Train? trainDataArg;
      
      // Handle the new argument structure
      if (args is Map && args['trainData'] != null) {
        trainDataArg = args['trainData'] as Train;
      } else if (args is Train) {
        // For backward compatibility
        trainDataArg = args;
      }
      
      if (trainDataArg == null) {
        errorMessage.value = 'No train data found. Please try searching again.';
        trainData.value = null;
      } else if (trainDataArg.data.isEmpty) {
        errorMessage.value = 'No trains found for the selected route.';
        trainData.value = trainDataArg;
      } else {
        trainData.value = trainDataArg;
        errorMessage.value = null;
      }
    } catch (e) {
      errorMessage.value = 'An error occurred while loading train data or no trains found.';
      trainData.value = null;
    }
  }
}

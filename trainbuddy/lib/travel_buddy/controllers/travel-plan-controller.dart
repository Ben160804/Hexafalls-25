import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart' as share_plus;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:trainbuddy/travel_buddy/models/travel_model.dart';
import 'package:trainbuddy/travel_buddy/models/train_miss_model.dart';

class TravelDetailsController extends GetxController {
  final Map<String, dynamic> initialTravelInfo;
  TravelDetailsController({required this.initialTravelInfo});

  final Rx<TravelDetails> travelDetails = TravelDetails(
    tripSummary: null,
    transportation: null,
    accommodation: [],
    itinerary: [],
    budgetBreakdown: null,
    recommendations: null,
  ).obs;
  final RxInt currentDayIndex = 0.obs;
  final RxBool isLoading = false.obs;
  final RxBool isPdfGenerating = false.obs;
  final RxString errorMessage = ''.obs;
  final RxDouble pdfProgress = 0.0.obs;
  
  // Store alternate trains for each train journey
  final RxMap<String, TrainMissResponse> alternateTrains = <String, TrainMissResponse>{}.obs;
  final RxBool isLoadingAlternateTrains = false.obs;

  // Station code lookup
  Map<String, String> stationCodeMap = {};
  Map<String, String> stationNameMap = {};
  bool isStationCodesLoaded = false;

  late final PageController pageController;

  @override
  void onInit() {
    super.onInit();
    _initializePageController();
    _loadStationCodes();
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }

  void _initializePageController() {
    pageController = PageController(
      viewportFraction: 0.85,
      initialPage: currentDayIndex.value,
    );

    pageController.addListener(() {
      final newPage = pageController.page?.round() ?? 0;
      if (newPage != currentDayIndex.value) {
        Future.delayed(const Duration(milliseconds: 100), () {
          if (pageController.hasClients && pageController.page?.round() == newPage) {
            currentDayIndex.value = newPage;
          }
        });
      }
    });
  }

  Future<void> fetchTravelDetails(Map<String, dynamic> travelInfo) async {
    try {
      isLoading.value = true;
      errorMessage.value = '';

      // Log request details
      final startTime = DateTime.now();
      debugPrint('API Request Started: ${DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(startTime)}');
      debugPrint('API Endpoint: https://easyjourney-production.up.railway.app/generate-plan');
      debugPrint('Request Method: POST');
      debugPrint('Request Headers: ${jsonEncode({'Content-Type': 'application/json'})}');
      debugPrint('Request Body: ${jsonEncode(travelInfo)}');

      final response = await http.post(
        Uri.parse('https://easyjourney-production.up.railway.app/generate-plan'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(travelInfo),
      ).timeout(
        const Duration(seconds: 30),
        onTimeout: () {
          throw TimeoutException('API request timed out after 30 seconds');
        },
      );

      final endTime = DateTime.now();
      final duration = endTime.difference(startTime).inMilliseconds;
      debugPrint('API Request Completed: ${DateFormat('yyyy-MM-dd HH:mm:ss.SSS').format(endTime)}');
      debugPrint('Response Time: $duration ms');
      debugPrint('Response Status Code: ${response.statusCode}');
      debugPrint('Response Headers: ${jsonEncode(response.headers)}');
      debugPrint('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        try {
          final jsonData = jsonDecode(response.body);
          debugPrint('Parsed JSON Response: $jsonData');
          
          // Log the trip_summary structure specifically
          if (jsonData['trip_summary'] != null) {
            final tripSummary = jsonData['trip_summary'];
            debugPrint('Trip Summary Structure:');
            debugPrint('  from/origin: ${tripSummary['from'] ?? tripSummary['origin']}');
            debugPrint('  to/destination: ${tripSummary['to'] ?? tripSummary['destination']}');
            debugPrint('  dates type: ${tripSummary['dates'].runtimeType}');
            debugPrint('  dates value: ${tripSummary['dates']}');
            debugPrint('  travelers: ${tripSummary['travelers']}');
            debugPrint('  trip_type: ${tripSummary['trip_type']}');
            debugPrint('  budget: ${tripSummary['budget']}');
          }
          
          // Log accommodation structure if present
          if (jsonData['accommodation'] != null) {
            debugPrint('Accommodation Structure:');
            debugPrint('  accommodation type: ${jsonData['accommodation'].runtimeType}');
            debugPrint('  accommodation value: ${jsonData['accommodation']}');
          }
          
          // Log itinerary structure if present
          if (jsonData['itinerary'] != null) {
            debugPrint('Itinerary Structure:');
            debugPrint('  itinerary type: ${jsonData['itinerary'].runtimeType}');
            debugPrint('  itinerary value: ${jsonData['itinerary']}');
          }
          
          travelDetails.value = TravelDetails.fromJson(jsonData);
          debugPrint('Travel Details Model Created Successfully');
          debugPrint('Trip Summary: ${travelDetails.value.tripSummary?.from} to ${travelDetails.value.tripSummary?.to}');
          debugPrint('Transportation: ${travelDetails.value.transportation?.trains?.length ?? 0} trains');
          debugPrint('Accommodation: ${travelDetails.value.accommodation.length} items');
          debugPrint('Itinerary: ${travelDetails.value.itinerary.length} days');
          debugPrint('Budget Breakdown: Total Estimated: ${travelDetails.value.budgetBreakdown?.totalEstimated}');
          debugPrint('Recommendations: Places to Visit: ${travelDetails.value.recommendations?.placesToVisit}');
          
          // Fetch alternate trains for all train journeys
          if (hasTrainTransportation()) {
            debugPrint('Fetching alternate trains for train journeys...');
            await fetchAlternateTrainsForAllJourneys();
          }
          
          _showSuccessSnackbar('Success', 'Travel details loaded successfully');
        } catch (e, stackTrace) {
          debugPrint('JSON Parsing Error: $e');
          debugPrint('Stack Trace: $stackTrace');
          debugPrint('Raw Response Body: ${response.body}');
          throw Exception('Failed to parse response JSON: $e');
        }
      } else {
        debugPrint('API Error Response: ${response.body}');
        throw Exception('API call failed with status ${response.statusCode}: ${response.body}');
      }
    } catch (e, stackTrace) {
      debugPrint('API Request Failed: $e');
      debugPrint('Stack Trace: $stackTrace');
      errorMessage.value = 'Failed to load travel details: ${e.toString()}';
      _showErrorSnackbar('Error', errorMessage.value);
    } finally {
      isLoading.value = false;
      debugPrint('API Request Finalized');
    }
  }

  String getTripSummary() {
    final tripSummary = travelDetails.value.tripSummary;
    if (tripSummary == null) return 'No trip details available';
    return '${tripSummary.from ?? 'Unknown'} → ${tripSummary.to ?? 'Unknown'}';
  }

  double getTotalCost() {
    return (travelDetails.value.budgetBreakdown?.totalEstimated ?? 0).toDouble();
  }

  int get dayCount => travelDetails.value.itinerary.length;

  void goBack() {
    Get.back();
  }

  Future<int> _getAndroidSdkVersion() async {
    if (!Platform.isAndroid) return 0;
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.version.sdkInt;
    } catch (e) {
      debugPrint('Error getting Android SDK version: $e');
      return 30;
    }
  }

  Future<bool> _requestStoragePermission() async {
    if (!Platform.isAndroid) return true;
    final sdkVersion = await _getAndroidSdkVersion();
    debugPrint('Android SDK Version: $sdkVersion');

    try {
      if (sdkVersion >= 33) {
        return await _handleAndroid13PlusPermissions();
      } else if (sdkVersion >= 30) {
        return await _handleAndroid11To12Permissions();
      } else {
        return await _handleAndroidLegacyPermissions();
      }
    } catch (e) {
      debugPrint('Error requesting storage permission: $e');
      return false;
    }
  }

  Future<bool> _handleAndroid13PlusPermissions() async {
    var manageStorageStatus = await Permission.manageExternalStorage.status;
    if (manageStorageStatus.isGranted) return true;

    final shouldRequest = await _showPermissionExplanationDialog(
      'Storage Access Required',
      'To save PDFs to the main Downloads folder on Android 13+, we need the Manage External Storage permission.',
    );
    if (!shouldRequest) return false;

    manageStorageStatus = await Permission.manageExternalStorage.request();
    if (manageStorageStatus.isGranted) {
      return true;
    } else if (manageStorageStatus.isPermanentlyDenied) {
      await _showPermissionDialog(
        'Manage External Storage permission is permanently denied. Please enable it in app settings or use the share option.',
      );
      return false;
    }

    await _showPermissionDialog(
      'Permission denied. PDF will be saved to app-specific storage or you can use the share option.',
    );
    return false;
  }

  Future<bool> _handleAndroid11To12Permissions() async {
    var storageStatus = await Permission.storage.status;

    if (storageStatus.isDenied) {
      final shouldRequest = await _showPermissionExplanationDialog(
        'Storage Access Required',
        'To save PDFs to your Downloads folder, we need storage permission.',
      );
      if (!shouldRequest) return false;
      storageStatus = await Permission.storage.request();
    }

    if (storageStatus.isGranted) return true;

    if (storageStatus.isPermanentlyDenied) {
      await _showPermissionDialog(
        'Storage permission is permanently denied. Please enable it in app settings or use the share option.',
      );
      return false;
    }

    await _showPermissionDialog(
      'Storage permission is required to save PDF files. You can use the share option instead.',
    );
    return false;
  }

  Future<bool> _handleAndroidLegacyPermissions() async {
    var storageStatus = await Permission.storage.status;

    if (storageStatus.isDenied) {
      final shouldRequest = await _showPermissionExplanationDialog(
        'Storage Permission Required',
        'We need storage permission to save your travel PDF to the Downloads folder.',
      );
      if (!shouldRequest) return false;
      storageStatus = await Permission.storage.request();

      if (storageStatus.isDenied) {
        await _showPermissionDialog(
          'Storage permission is required to save PDF files. You can also use the share option.',
        );
        return false;
      } else if (storageStatus.isPermanentlyDenied) {
        await _showPermissionDialog(
          'Storage permission is permanently denied. Please enable it in app settings or use the share option.',
        );
        return false;
      }
    } else if (storageStatus.isPermanentlyDenied) {
      await _showPermissionDialog(
        'Storage permission is permanently denied. Please enable it in app settings or use the share option.',
      );
      return false;
    }

    return storageStatus.isGranted;
  }

  Future<bool> _showPermissionExplanationDialog(String title, String message) async {
    bool shouldRequest = false;
    await Get.dialog(
      AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              shouldRequest = false;
              Get.back();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              shouldRequest = true;
              Get.back();
            },
            child: const Text('Allow'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
    return shouldRequest;
  }

  Future<void> _showPermissionDialog(String message) async {
    await Get.dialog(
      AlertDialog(
        title: const Text('Permission Required'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Get.back();
              openAppSettings();
            },
            child: const Text('Settings'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Future<bool> _showShareAlternativeDialog() async {
    bool shouldShare = false;
    await Get.dialog(
      AlertDialog(
        title: const Text('Save PDF'),
        content: const Text(
          'Unable to save directly to Downloads folder. Would you like to share the PDF instead? You can then save it from the share menu.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              shouldShare = false;
              Get.back();
            },
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              shouldShare = true;
              Get.back();
            },
            child: const Text('Share PDF'),
          ),
        ],
      ),
      barrierDismissible: false,
    );
    return shouldShare;
  }

  Future<void> _clearPermissionCache() async {
    try {
      await Permission.storage.status;
      if (Platform.isAndroid) {
        final sdkVersion = await _getAndroidSdkVersion();
        if (sdkVersion >= 30) {
          await Permission.manageExternalStorage.status;
        }
      }
    } catch (e) {
      debugPrint('Error clearing permission cache: $e');
    }
  }

  Future<bool> _canWriteToDirectory(Directory directory) async {
    try {
      final testFile = File('${directory.path}/.test_write_${DateTime.now().millisecondsSinceEpoch}');
      await testFile.writeAsString('test');
      await testFile.delete();
      return true;
    } catch (e) {
      debugPrint('Cannot write to directory ${directory.path}: $e');
      return false;
    }
  }

  String _generateFileName() {
    final now = DateTime.now();
    final dateStr = DateFormat('yyyyMMdd_HHmmss').format(now);
    final tripName = travelDetails.value.tripSummary?.to
        ?.replaceAll(RegExp(r'[^\w\s-]'), '')
        .replaceAll(' ', '_') ?? 'trip';
    return 'TravelPlan_${tripName}_$dateStr.pdf';
  }

  Future<void> _shareAsPdf() async {
    try {
      isPdfGenerating.value = true;
      pdfProgress.value = 0.0;

      final pdfData = await _generatePdfData();
      pdfProgress.value = 0.9;

      final fileName = _generateFileName();
      await share_plus.Share.shareXFiles([
        share_plus.XFile.fromData(
          pdfData,
          mimeType: 'application/pdf',
          name: fileName,
        )
      ], text: 'Travel Plan PDF');

      pdfProgress.value = 1.0;
      _showSuccessSnackbar('Success', 'PDF shared successfully');
    } catch (e) {
      debugPrint('Share error: $e');
      _showErrorSnackbar('Share Error', 'Failed to share PDF: ${e.toString()}');
    } finally {
      isPdfGenerating.value = false;
      pdfProgress.value = 0.0;
    }
  }

  Future<void> generatePdf() async {
    try {
      isPdfGenerating.value = true;
      pdfProgress.value = 0.0;
      errorMessage.value = '';

      await _clearPermissionCache();
      pdfProgress.value = 0.1;

      bool canSaveToDownloads = false;

      if (Platform.isAndroid) {
        canSaveToDownloads = await _requestStoragePermission();
        pdfProgress.value = 0.2;

        if (!canSaveToDownloads) {
          final shouldShare = await _showShareAlternativeDialog();
          if (shouldShare) {
            await _shareAsPdf();
            return;
          } else {
            return;
          }
        }
      } else if (Platform.isIOS) {
        await _shareAsPdf();
        return;
      }

      pdfProgress.value = 0.3;

      final pdfData = await _generatePdfData();
      pdfProgress.value = 0.7;

      final saveResult = await _savePdfToStorage(pdfData);
      pdfProgress.value = 0.9;

      if (saveResult.success) {
        _showSuccessSnackbar('Success', saveResult.message);
      } else {
        throw Exception(saveResult.message);
      }

      pdfProgress.value = 1.0;
    } catch (e) {
      debugPrint('PDF generation error: $e');
      errorMessage.value = 'Failed to generate PDF: ${e.toString()}';
      Get.snackbar(
        'Error',
        errorMessage.value,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 5),
        mainButton: TextButton(
          child: const Text('Share Instead', style: TextStyle(color: Colors.white)),
          onPressed: () => _shareAsPdf(),
        ),
      );
    } finally {
      isPdfGenerating.value = false;
      pdfProgress.value = 0.0;
    }
  }

  Future<SaveResult> _savePdfToStorage(Uint8List pdfData) async {
    try {
      final directory = await _getStorageDirectory();
      final fileName = _generateFileName();
      final file = File('${directory.path}/$fileName');

      await file.writeAsBytes(pdfData);

      if (!file.existsSync()) {
        throw Exception('Failed to create PDF file');
      }

      final fileSize = await file.length();
      debugPrint('PDF saved: ${file.path} (${fileSize} bytes)');

      return SaveResult(
        success: true,
        message: 'PDF saved successfully to Downloads\nFile: $fileName',
        filePath: file.path,
      );
    } catch (e) {
      return SaveResult(
        success: false,
        message: 'Failed to save PDF: ${e.toString()}',
      );
    }
  }

  Future<Directory> _getStorageDirectory() async {
    if (Platform.isAndroid) {
      final sdkVersion = await _getAndroidSdkVersion();

      if (sdkVersion >= 33 && await Permission.manageExternalStorage.status.isGranted) {
        var directory = Directory('/storage/emulated/0/Download');
        if (await directory.exists() && await _canWriteToDirectory(directory)) {
          return directory;
        }
        directory = Directory('/storage/emulated/0/Downloads');
        if (await directory.exists() && await _canWriteToDirectory(directory)) {
          return directory;
        }
      } else if (sdkVersion >= 30) {
        var directory = Directory('/storage/emulated/0/Download');
        if (await directory.exists() && await _canWriteToDirectory(directory)) {
          return directory;
        }
        directory = Directory('/storage/emulated/0/Downloads');
        if (await directory.exists() && await _canWriteToDirectory(directory)) {
          return directory;
        }
      }

      final externalDir = await getExternalStorageDirectory();
      if (externalDir != null) {
        final downloadDir = Directory('${externalDir.path}/Downloads');
        if (!downloadDir.existsSync()) {
          downloadDir.createSync(recursive: true);
        }
        return downloadDir;
      }
      return await getApplicationDocumentsDirectory();
    } else {
      return await getApplicationDocumentsDirectory();
    }
  }

  Future<Uint8List> _generatePdfData() async {
    final pdf = pw.Document();
    final font = pw.Font.ttf(await _loadFont());

    final pages = await _buildPdfPages(font);
    for (final page in pages) {
      pdf.addPage(page);
    }

    return await pdf.save();
  }

  Future<List<pw.Page>> _buildPdfPages(pw.Font font) async {
    final pages = <pw.Page>[];

    // Page 1: Header and Trip Overview
    pages.add(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildPdfHeader(font),
              pw.SizedBox(height: 20),
              _buildTripOverviewSection(font),
              pw.SizedBox(height: 20),
              _buildTransportationSection(font),
              pw.SizedBox(height: 20),
              _buildEmergencyMissedTrainSection(font),
            ],
          );
        },
      ),
    );

    // Page 2: Accommodation and Budget
    if (travelDetails.value.accommodation.isNotEmpty || travelDetails.value.budgetBreakdown != null) {
      pages.add(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildAccommodationSection(font),
                pw.SizedBox(height: 20),
                _buildBudgetBreakdownSection(font),
              ],
            );
          },
        ),
      );
    }

    // Page 3: Itinerary
    if (travelDetails.value.itinerary.isNotEmpty) {
      pages.add(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildDailyItinerarySection(font),
              ],
            );
          },
        ),
      );
    }

    // Page 4: Recommendations
    if (travelDetails.value.recommendations != null) {
      pages.add(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(20),
          build: (pw.Context context) {
            return pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildRecommendationsSection(font),
              ],
            );
          },
        ),
      );
    }

    return pages;
  }

  pw.Widget _buildPdfHeader(pw.Font font) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(25),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [PdfColors.blue50, PdfColors.blue100],
          begin: pw.Alignment.topLeft,
          end: pw.Alignment.bottomRight,
        ),
        borderRadius: pw.BorderRadius.circular(15),
        border: pw.Border.all(color: PdfColors.blue300, width: 2),
      ),
      child: pw.Column(
        children: [
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.center,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue600,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Text(
                  '✈️',
                  style: pw.TextStyle(fontSize: 20),
                ),
              ),
              pw.SizedBox(width: 15),
              pw.Text(
                'TRAVEL PLAN',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 32,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 15),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(10),
              border: pw.Border.all(color: PdfColors.blue200),
            ),
            child: pw.Text(
              getTripSummary(),
              style: pw.TextStyle(
                font: font,
                fontSize: 20,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue700,
              ),
              textAlign: pw.TextAlign.center,
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Text(
            'Generated on ${DateFormat('EEEE, MMMM dd, yyyy').format(DateTime.now())}',
            style: pw.TextStyle(
              font: font,
              fontSize: 14,
              color: PdfColors.blue600,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTripOverviewSection(pw.Font font) {
    final tripSummary = travelDetails.value.tripSummary;
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        border: pw.Border.all(color: PdfColors.grey300, width: 1.5),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.blue600,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Icon(
                  pw.IconData(0xe3c9),
                  color: PdfColors.white,
                  size: 20,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Text(
                'Trip Overview',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 15),
          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.grey200),
            ),
            child: pw.Column(
              children: [
                _buildInfoRow(font, 'From', tripSummary?.from ?? 'Not specified', PdfColors.blue600),
                _buildInfoRow(font, 'To', tripSummary?.to ?? 'Not specified', PdfColors.blue600),
                _buildInfoRow(font, 'Dates', tripSummary?.dates ?? 'Not specified', PdfColors.blue600),
                _buildInfoRow(font, 'Trip Type', tripSummary?.tripType ?? 'Not specified', PdfColors.blue600),
                _buildInfoRow(font, 'Total Budget', '₹${NumberFormat('#,##,###').format(tripSummary?.budget ?? 0)}', PdfColors.green600),
                if (tripSummary?.travelers != null) ...[
                  _buildInfoRow(font, 'Adults', '${tripSummary!.travelers!.adults ?? 0}', PdfColors.blue600),
                  if ((tripSummary.travelers!.children ?? 0) > 0)
                    _buildInfoRow(font, 'Children', '${tripSummary.travelers!.children}', PdfColors.blue600),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildInfoRow(pw.Font font, String label, String value, PdfColor labelColor) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            width: 140,
            child: pw.Text(
              '$label:',
              style: pw.TextStyle(
                font: font,
                fontWeight: pw.FontWeight.bold,
                color: labelColor,
                fontSize: 14,
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                font: font,
                fontSize: 14,
                color: PdfColors.grey800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildTransportationSection(pw.Font font) {
    final transportation = travelDetails.value.transportation;
    if (transportation == null) return pw.SizedBox();

    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        border: pw.Border.all(color: PdfColors.grey300, width: 1.5),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.orange600,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Icon(
                  pw.IconData(0xe3c9),
                  color: PdfColors.white,
                  size: 20,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Text(
                'Transportation',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 15),
          
          // Handle new API structure
          if (transportation.outbound != null) ...[
            _buildTransportLegPdf(font, transportation.outbound!, 'Outbound Journey', PdfColors.blue600),
            pw.SizedBox(height: 15),
          ],
          if (transportation.returnLeg != null) ...[
            _buildTransportLegPdf(font, transportation.returnLeg!, 'Return Journey', PdfColors.green600),
            pw.SizedBox(height: 15),
          ],
          if (transportation.localTransport != null) ...[
            _buildLocalTransportPdf(font, transportation.localTransport!),
            pw.SizedBox(height: 15),
          ],
          
          // Handle old API structure
          if (transportation.trains?.isNotEmpty == true) ...[
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.blue200),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Train Journeys',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.blue700,
                    ),
                  ),
                  pw.SizedBox(height: 10),
                  ...transportation.trains!.asMap().entries.map((entry) {
                    final train = entry.value;
                    return pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 15),
                      padding: const pw.EdgeInsets.all(12),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue50,
                        borderRadius: pw.BorderRadius.circular(8),
                        border: pw.Border.all(color: PdfColors.blue200),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Train ${entry.key + 1}',
                            style: pw.TextStyle(
                              font: font,
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.blue800,
                            ),
                          ),
                          pw.SizedBox(height: 8),
                          _buildInfoRow(font, 'Name', train.name ?? 'Not specified', PdfColors.blue600),
                          _buildInfoRow(font, 'Number', train.number ?? 'Not specified', PdfColors.blue600),
                          if (train.departure != null)
                            _buildInfoRow(font, 'Departure', '${train.departure!.station ?? 'Unknown'} at ${train.departure!.time ?? 'Unknown'}', PdfColors.blue600),
                          if (train.arrival != null)
                            _buildInfoRow(font, 'Arrival', '${train.arrival!.station ?? 'Unknown'} at ${train.arrival!.time ?? 'Unknown'}', PdfColors.blue600),
                          _buildInfoRow(font, 'Duration', train.duration ?? 'Not specified', PdfColors.blue600),
                          _buildInfoRow(font, 'Class', train.trainClass ?? 'Not specified', PdfColors.blue600),
                          _buildInfoRow(font, 'Cost', '₹${NumberFormat('#,##,###').format(train.totalCost ?? 0)}', PdfColors.green600),
                        ],
                      ),
                    );
                  }).toList(),
                ],
              ),
            ),
          ],
          if (transportation.flights?.isNotEmpty == true) ...[
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.orange200),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Flights',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.orange700,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    '${transportation.flights?.length ?? 0} flight(s) available',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 14,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (transportation.buses?.isNotEmpty == true) ...[
            pw.SizedBox(height: 10),
            pw.Container(
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.green200),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    'Buses',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColors.green700,
                    ),
                  ),
                  pw.SizedBox(height: 8),
                  pw.Text(
                    '${transportation.buses?.length ?? 0} bus(es) available',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 14,
                      color: PdfColors.grey600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildTransportLegPdf(pw.Font font, TransportLeg leg, String title, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: color),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              font: font,
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 10),
          _buildInfoRow(font, 'Mode', leg.mode.toUpperCase(), color),
          _buildInfoRow(font, 'Details', leg.details, color),
          _buildInfoRow(font, 'Duration', leg.duration, color),
          _buildInfoRow(font, 'Departure', leg.departureTime, color),
          _buildInfoRow(font, 'Arrival', leg.arrivalTime, color),
          _buildInfoRow(font, 'Total Cost', '₹${NumberFormat('#,##,###').format(leg.totalCost)}', PdfColors.green600),
        ],
      ),
    );
  }

  pw.Widget _buildLocalTransportPdf(pw.Font font, LocalTransport localTransport) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.purple600),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Local Transport',
            style: pw.TextStyle(
              font: font,
              fontSize: 18,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.purple700,
            ),
          ),
          pw.SizedBox(height: 10),
          _buildInfoRow(font, 'Mode', localTransport.mode.toUpperCase(), PdfColors.purple600),
          _buildInfoRow(font, 'Daily Cost', '₹${NumberFormat('#,##,###').format(localTransport.dailyCost)}', PdfColors.green600),
          _buildInfoRow(font, 'Total Cost', '₹${NumberFormat('#,##,###').format(localTransport.totalCost)}', PdfColors.green600),
        ],
      ),
    );
  }

  pw.Widget _buildEmergencyMissedTrainSection(pw.Font font) {
    // Only show if there's train transportation and valid station codes
    if (!hasTrainTransportation() || 
        extractSourceStationCode() == null || 
        extractDestinationStationCode() == null) {
      return pw.SizedBox();
    }

    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        border: pw.Border.all(color: PdfColors.red300, width: 1.5),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.red600,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Icon(
                  pw.IconData(0xe3c9),
                  color: PdfColors.white,
                  size: 20,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Text(
                'Emergency: Missed Train',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.red800,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 15),
          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.red200),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Alternative Train Options',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.red700,
                  ),
                ),
                pw.SizedBox(height: 10),
                _buildInfoRow(font, 'From', extractSourceStationName() ?? 'Unknown', PdfColors.red600),
                _buildInfoRow(font, 'To', extractDestinationStationName() ?? 'Unknown', PdfColors.red600),
                _buildInfoRow(font, 'Source Code', extractSourceStationCode() ?? 'N/A', PdfColors.red600),
                _buildInfoRow(font, 'Destination Code', extractDestinationStationCode() ?? 'N/A', PdfColors.red600),
                pw.SizedBox(height: 10),
                pw.Text(
                  'If you miss your train, use the Train Miss feature in the app to find alternative trains between these stations.',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 14,
                    color: PdfColors.grey700,
                    fontStyle: pw.FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildAccommodationSection(pw.Font font) {
    final accommodations = travelDetails.value.accommodation;
    if (accommodations.isEmpty) return pw.SizedBox();
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        border: pw.Border.all(color: PdfColors.grey300, width: 1.5),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.orange600,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Icon(
                  pw.IconData(0xe3c9),
                  color: PdfColors.white,
                  size: 20,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Text(
                'Accommodation',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 15),
          ...accommodations.asMap().entries.map((entry) {
            final accommodation = entry.value;
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 15),
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.orange200),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Text(
                        'Hotel ${entry.key + 1}',
                        style: pw.TextStyle(
                          font: font,
                          fontSize: 16,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.orange700,
                        ),
                      ),
                      pw.Spacer(),
                      if (accommodation.rating != null)
                        pw.Container(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.orange100,
                            borderRadius: pw.BorderRadius.circular(12),
                          ),
                          child: pw.Text(
                            '${accommodation.rating} ⭐',
                            style: pw.TextStyle(
                              font: font,
                              fontSize: 12,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.orange700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  _buildInfoRow(font, 'Name', accommodation.name ?? 'Not specified', PdfColors.orange600),
                  _buildInfoRow(font, 'Location', accommodation.location ?? 'Not specified', PdfColors.orange600),
                  if (accommodation.checkIn != null)
                    _buildInfoRow(font, 'Check-In', DateFormat('MMM dd, yyyy').format(accommodation.checkIn!), PdfColors.orange600),
                  if (accommodation.checkOut != null)
                    _buildInfoRow(font, 'Check-Out', DateFormat('MMM dd, yyyy').format(accommodation.checkOut!), PdfColors.orange600),
                  _buildInfoRow(font, 'Cost per Night', '₹${NumberFormat('#,##,###').format(accommodation.costPerNight ?? 0)}', PdfColors.green600),
                  _buildInfoRow(font, 'Total Cost', '₹${NumberFormat('#,##,###').format(accommodation.totalCost ?? 0)}', PdfColors.green600),
                  if (accommodation.amenities.isNotEmpty) ...[
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Amenities:',
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.orange600,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      accommodation.amenities.join(', '),
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 12,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  pw.Widget _buildBudgetBreakdownSection(pw.Font font) {
    final budgetBreakdown = travelDetails.value.budgetBreakdown;
    if (budgetBreakdown == null) return pw.SizedBox();
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        border: pw.Border.all(color: PdfColors.grey300, width: 1.5),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.green600,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Icon(
                  pw.IconData(0xe3c9),
                  color: PdfColors.white,
                  size: 20,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Text(
                'Budget Breakdown',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 15),
          pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: PdfColors.white,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.green200),
            ),
            child: pw.Column(
              children: [
                pw.Text(
                  'Total Estimated Budget',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 18,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green700,
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  '₹${NumberFormat('#,##,###').format(budgetBreakdown.totalEstimated ?? 0)}',
                  style: pw.TextStyle(
                    font: font,
                    fontSize: 28,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.green600,
                  ),
                ),
                pw.SizedBox(height: 20),
                _buildInfoRow(font, 'Transportation', '₹${NumberFormat('#,##,###').format(budgetBreakdown.transportation ?? 0)}', PdfColors.blue600),
                _buildInfoRow(font, 'Accommodation', '₹${NumberFormat('#,##,###').format(budgetBreakdown.accommodation ?? 0)}', PdfColors.orange600),
                _buildInfoRow(font, 'Food & Misc', '₹${NumberFormat('#,##,###').format(budgetBreakdown.food ?? 0)}', PdfColors.purple600),
                if (budgetBreakdown.buffer != null && budgetBreakdown.buffer! > 0)
                  _buildInfoRow(font, 'Buffer', '₹${NumberFormat('#,##,###').format(budgetBreakdown.buffer!)}', PdfColors.red600),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildDailyItinerarySection(pw.Font font) {
    final itinerary = travelDetails.value.itinerary;
    if (itinerary.isEmpty) return pw.SizedBox();

    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        border: pw.Border.all(color: PdfColors.grey300, width: 1.5),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.pink600,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Icon(
                  pw.IconData(0xe3c9),
                  color: PdfColors.white,
                  size: 20,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Text(
                'Daily Itinerary',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 15),
          ...itinerary.asMap().entries.map((entry) {
            final day = entry.value;
            return pw.Container(
              margin: const pw.EdgeInsets.only(bottom: 15),
              padding: const pw.EdgeInsets.all(15),
              decoration: pw.BoxDecoration(
                color: PdfColors.white,
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColors.pink200),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    children: [
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.pink600,
                          borderRadius: pw.BorderRadius.circular(12),
                        ),
                        child: pw.Text(
                          'Day ${day.day ?? entry.key + 1}',
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 14,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.white,
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 12),
                      if (day.date != null)
                        pw.Text(
                          DateFormat('EEEE, MMM dd, yyyy').format(day.date!),
                          style: pw.TextStyle(
                            font: font,
                            fontSize: 14,
                            color: PdfColors.grey600,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                    ],
                  ),
                  pw.SizedBox(height: 12),
                  if (day.activities.isNotEmpty) ...[
                    pw.Text(
                      'Activities:',
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 16,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.pink700,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    ...day.activities.map((activity) {
                      return pw.Container(
                        margin: const pw.EdgeInsets.only(bottom: 8),
                        padding: const pw.EdgeInsets.all(10),
                        decoration: pw.BoxDecoration(
                          color: PdfColors.pink50,
                          borderRadius: pw.BorderRadius.circular(6),
                          border: pw.Border.all(color: PdfColors.pink200),
                        ),
                        child: pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Row(
                              children: [
                                pw.Text(
                                  activity.time,
                                  style: pw.TextStyle(
                                    font: font,
                                    fontSize: 12,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColors.pink600,
                                  ),
                                ),
                                pw.SizedBox(width: 8),
                                pw.Text(
                                  '•',
                                  style: pw.TextStyle(
                                    font: font,
                                    fontSize: 12,
                                    color: PdfColors.pink600,
                                  ),
                                ),
                                pw.SizedBox(width: 8),
                                pw.Expanded(
                                  child: pw.Text(
                                    activity.activity,
                                    style: pw.TextStyle(
                                      font: font,
                                      fontSize: 14,
                                      fontWeight: pw.FontWeight.bold,
                                      color: PdfColors.grey800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (activity.location.isNotEmpty) ...[
                              pw.SizedBox(height: 4),
                              pw.Text(
                                '📍 ${activity.location}',
                                style: pw.TextStyle(
                                  font: font,
                                  fontSize: 12,
                                  color: PdfColors.grey600,
                                ),
                              ),
                            ],
                            if (activity.duration.isNotEmpty) ...[
                              pw.SizedBox(height: 2),
                              pw.Text(
                                '⏱️ ${activity.duration}',
                                style: pw.TextStyle(
                                  font: font,
                                  fontSize: 12,
                                  color: PdfColors.grey600,
                                ),
                              ),
                            ],
                            if (activity.cost > 0) ...[
                              pw.SizedBox(height: 2),
                              pw.Text(
                                '💰 ₹${NumberFormat('#,##,###').format(activity.cost)}',
                                style: pw.TextStyle(
                                  font: font,
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColors.green600,
                                ),
                              ),
                            ],
                          ],
                        ),
                      );
                    }).toList(),
                  ] else ...[
                    pw.Text(
                      'No activities planned for this day',
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 14,
                        color: PdfColors.grey500,
                        fontStyle: pw.FontStyle.italic,
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  pw.Widget _buildRecommendationsSection(pw.Font font) {
    final recommendations = travelDetails.value.recommendations;
    if (recommendations == null) return pw.SizedBox();
    
    return pw.Container(
      padding: const pw.EdgeInsets.all(20),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        border: pw.Border.all(color: PdfColors.grey300, width: 1.5),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.purple600,
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Icon(
                  pw.IconData(0xe3c9),
                  color: PdfColors.white,
                  size: 20,
                ),
              ),
              pw.SizedBox(width: 12),
              pw.Text(
                'Recommendations',
                style: pw.TextStyle(
                  font: font,
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.blue800,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 15),
          
          if (recommendations.placesToVisit != null) ...[
            _buildRecommendationCardPdf(font, 'Places to Visit', recommendations.placesToVisit!, PdfColors.blue600),
            pw.SizedBox(height: 15),
          ],
          if (recommendations.foodToTry != null) ...[
            _buildRecommendationCardPdf(font, 'Food to Try', recommendations.foodToTry!, PdfColors.orange600),
            pw.SizedBox(height: 15),
          ],
          if (recommendations.thingsToDo != null) ...[
            _buildRecommendationCardPdf(font, 'Things to Do', recommendations.thingsToDo!, PdfColors.green600),
            pw.SizedBox(height: 15),
          ],
          if (recommendations.tips != null) ...[
            _buildRecommendationCardPdf(font, 'Travel Tips', recommendations.tips!, PdfColors.purple600),
            pw.SizedBox(height: 15),
          ],
          if (recommendations.packingList.isNotEmpty) ...[
            _buildListRecommendationCardPdf(font, 'Packing List', recommendations.packingList, PdfColors.grey600),
            pw.SizedBox(height: 15),
          ],
          if (recommendations.travelTips.isNotEmpty) ...[
            _buildListRecommendationCardPdf(font, 'Travel Tips', recommendations.travelTips, PdfColors.brown600),
            pw.SizedBox(height: 15),
          ],
          if (recommendations.emergencyContacts.isNotEmpty) ...[
            _buildListRecommendationCardPdf(font, 'Emergency Contacts', recommendations.emergencyContacts, PdfColors.red600),
            pw.SizedBox(height: 15),
          ],
          if (recommendations.weatherAdvice != null) ...[
            _buildRecommendationCardPdf(font, 'Weather Advice', recommendations.weatherAdvice!, PdfColors.yellow600),
            pw.SizedBox(height: 15),
          ],
          if (recommendations.localCustoms != null) ...[
            _buildRecommendationCardPdf(font, 'Local Customs', recommendations.localCustoms!, PdfColors.pink600),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildRecommendationCardPdf(pw.Font font, String title, String content, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: color),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              font: font,
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            content,
            style: pw.TextStyle(
              font: font,
              fontSize: 14,
              color: PdfColors.grey800,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildListRecommendationCardPdf(pw.Font font, String title, List<String> items, PdfColor color) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(15),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: color),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              font: font,
              fontSize: 16,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
          pw.SizedBox(height: 8),
          ...items.map((item) {
            return pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 4),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    '• ',
                    style: pw.TextStyle(
                      font: font,
                      fontSize: 14,
                      color: color,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      item,
                      style: pw.TextStyle(
                        font: font,
                        fontSize: 14,
                        color: PdfColors.grey800,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  void _showSuccessSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.green,
      colorText: Colors.white,
      duration: const Duration(seconds: 3),
    );
  }

  void _showErrorSnackbar(String title, String message) {
    Get.snackbar(
      title,
      message,
      snackPosition: SnackPosition.BOTTOM,
      backgroundColor: Colors.red,
      colorText: Colors.white,
      duration: const Duration(seconds: 5),
    );
  }

  Future<ByteData> _loadFont() async {
    try {
      return await rootBundle.load('assets/fonts/NotoSans-Regular.ttf');
    } catch (e) {
      debugPrint('Error loading custom font: $e, falling back to Roboto');
      return await rootBundle.load('assets/fonts/Roboto-Regular.ttf');
    }
  }

  void navigateToDay(int index) {
    if (index >= 0 && index < travelDetails.value.itinerary.length) {
      pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  // Methods for train miss component
  String? extractSourceStationCode() {
    final tripSummary = travelDetails.value.tripSummary;
    debugPrint('=== EXTRACTING SOURCE STATION CODE ===');
    debugPrint('Trip Summary: $tripSummary');
    debugPrint('From Field: ${tripSummary?.from}');
    
    if (tripSummary?.from == null || tripSummary!.from!.isEmpty) {
      debugPrint('From field is null or empty');
      return null;
    }

    final fromText = tripSummary!.from!;
    debugPrint('From Text: $fromText');

    // Look for common patterns in from text
    final patterns = [
      RegExp(r'(\w+)\s*\(([A-Z]{3,4})\)', caseSensitive: false),
      RegExp(r'([A-Z]{3,4})\s*-\s*(\w+)', caseSensitive: false),
      RegExp(r'(\w+)\s*-\s*([A-Z]{3,4})', caseSensitive: false),
    ];

    for (int i = 0; i < patterns.length; i++) {
      final match = patterns[i].firstMatch(fromText);
      if (match != null) {
        final stationCode = match.group(2);
        final stationName = match.group(1);
        debugPrint('Pattern $i matched:');
        debugPrint('  Station Name: $stationName');
        debugPrint('  Station Code: $stationCode');
        debugPrint('  Full Match: ${match.group(0)}');
        return stationCode;
      }
    }

    // Use loaded station codes
    if (isStationCodesLoaded) {
      final lowerFrom = fromText.toLowerCase();
      debugPrint('Searching for station code in: $lowerFrom');
      
      // Try exact match first
      if (stationNameMap.containsKey(lowerFrom)) {
        final code = stationNameMap[lowerFrom];
        debugPrint('Found exact station code: $code');
        return code;
      }
      
      // Try partial matches
      for (final entry in stationNameMap.entries) {
        if (lowerFrom.contains(entry.key) || entry.key.contains(lowerFrom)) {
          debugPrint('Found partial match: ${entry.key} -> ${entry.value}');
          return entry.value;
        }
      }
    }

    debugPrint('No station code pattern found in from text');
    return null;
  }

  String? extractDestinationStationCode() {
    final tripSummary = travelDetails.value.tripSummary;
    debugPrint('=== EXTRACTING DESTINATION STATION CODE ===');
    debugPrint('Trip Summary: $tripSummary');
    debugPrint('To Field: ${tripSummary?.to}');
    
    if (tripSummary?.to == null || tripSummary!.to!.isEmpty) {
      debugPrint('To field is null or empty');
      return null;
    }

    final toText = tripSummary!.to!;
    debugPrint('To Text: $toText');

    // Look for destination patterns in to text
    final patterns = [
      RegExp(r'(\w+)\s*\(([A-Z]{3,4})\)', caseSensitive: false),
      RegExp(r'([A-Z]{3,4})\s*-\s*(\w+)', caseSensitive: false),
      RegExp(r'(\w+)\s*-\s*([A-Z]{3,4})', caseSensitive: false),
    ];

    for (int i = 0; i < patterns.length; i++) {
      final match = patterns[i].firstMatch(toText);
      if (match != null) {
        final stationCode = match.group(2);
        final stationName = match.group(1);
        debugPrint('Pattern $i matched:');
        debugPrint('  Station Name: $stationName');
        debugPrint('  Station Code: $stationCode');
        debugPrint('  Full Match: ${match.group(0)}');
        return stationCode;
      }
    }

    // Use loaded station codes
    if (isStationCodesLoaded) {
      final lowerTo = toText.toLowerCase();
      debugPrint('Searching for destination station code in: $lowerTo');
      
      // Try exact match first
      if (stationNameMap.containsKey(lowerTo)) {
        final code = stationNameMap[lowerTo];
        debugPrint('Found exact destination station code: $code');
        return code;
      }
      
      // Try partial matches
      for (final entry in stationNameMap.entries) {
        if (lowerTo.contains(entry.key) || entry.key.contains(lowerTo)) {
          debugPrint('Found partial destination match: ${entry.key} -> ${entry.value}');
          return entry.value;
        }
      }
    }

    debugPrint('No destination station code pattern found in to text');
    return null;
  }

  String? extractSourceStationName() {
    final tripSummary = travelDetails.value.tripSummary;
    debugPrint('=== EXTRACTING SOURCE STATION NAME ===');
    debugPrint('Trip Summary: $tripSummary');
    debugPrint('From Field: ${tripSummary?.from}');
    
    if (tripSummary?.from == null || tripSummary!.from!.isEmpty) {
      debugPrint('From field is null or empty');
      return null;
    }

    final fromText = tripSummary!.from!;
    debugPrint('From Text: $fromText');

    // Look for source station name patterns
    final patterns = [
      RegExp(r'(\w+)\s*\([A-Z]{3,4}\)', caseSensitive: false),
      RegExp(r'([A-Z]{3,4})\s*-\s*(\w+)', caseSensitive: false),
      RegExp(r'(\w+)\s*-\s*[A-Z]{3,4}', caseSensitive: false),
    ];

    for (int i = 0; i < patterns.length; i++) {
      final match = patterns[i].firstMatch(fromText);
      if (match != null) {
        final stationName = match.group(1);
        debugPrint('Pattern $i matched:');
        debugPrint('  Station Name: $stationName');
        debugPrint('  Full Match: ${match.group(0)}');
        return stationName;
      }
    }

    // If no pattern matched, return the original text (cleaned)
    final cleanedName = fromText.replaceAll(RegExp(r'\([A-Z]{3,4}\)'), '').trim();
    debugPrint('Returning cleaned name: $cleanedName');
    return cleanedName;
  }

  String? extractDestinationStationName() {
    final tripSummary = travelDetails.value.tripSummary;
    debugPrint('=== EXTRACTING DESTINATION STATION NAME ===');
    debugPrint('Trip Summary: $tripSummary');
    debugPrint('To Field: ${tripSummary?.to}');
    
    if (tripSummary?.to == null || tripSummary!.to!.isEmpty) {
      debugPrint('To field is null or empty');
      return null;
    }

    final toText = tripSummary!.to!;
    debugPrint('To Text: $toText');

    // Look for destination station name patterns
    final patterns = [
      RegExp(r'(\w+)\s*\([A-Z]{3,4}\)', caseSensitive: false),
      RegExp(r'([A-Z]{3,4})\s*-\s*(\w+)', caseSensitive: false),
      RegExp(r'(\w+)\s*-\s*[A-Z]{3,4}', caseSensitive: false),
    ];

    for (int i = 0; i < patterns.length; i++) {
      final match = patterns[i].firstMatch(toText);
      if (match != null) {
        final stationName = match.group(1);
        debugPrint('Pattern $i matched:');
        debugPrint('  Station Name: $stationName');
        debugPrint('  Full Match: ${match.group(0)}');
        return stationName;
      }
    }

    // If no pattern matched, return the original text (cleaned)
    final cleanedName = toText.replaceAll(RegExp(r'\([A-Z]{3,4}\)'), '').trim();
    debugPrint('Returning cleaned name: $cleanedName');
    return cleanedName;
  }

  // Helper method to get better station names for API calls
  String getBetterStationName(String stationName, String stationCode) {
    // Map station names to their full/standard names for better API compatibility
    final stationNameMap = {
      'kolkata': 'Howrah Jn',
      'howrah': 'Howrah Jn',
      'jammu': 'Jammu Tawi',
      'jammu tawi': 'Jammu Tawi',
      'delhi': 'New Delhi',
      'new delhi': 'New Delhi',
      'mumbai': 'Mumbai Central',
      'bombay': 'Mumbai Central',
      'bangalore': 'Bangalore City',
      'bengaluru': 'Bangalore City',
      'chennai': 'Chennai Central',
      'madras': 'Chennai Central',
      'hyderabad': 'Hyderabad Decan',
      'lucknow': 'Lucknow Nr',
      'varanasi': 'Varanasi Junction',
      'patna': 'Patna Junction',
      'guwahati': 'Guwahati',
      'bhubaneswar': 'Bhubaneswar',
      'visakhapatnam': 'Visakhapatnam',
      'vizag': 'Visakhapatnam',
    };
    
    final lowerName = stationName.toLowerCase();
    return stationNameMap[lowerName] ?? stationName;
  }

  bool hasTrainTransportation() {
    final transportation = travelDetails.value.transportation;
    return transportation?.trains?.isNotEmpty == true || 
           transportation?.outbound != null || 
           transportation?.returnLeg != null;
  }

  String? getSourceStationCode() {
    return extractSourceStationCode();
  }

  String? getDestinationStationCode() {
    return extractDestinationStationCode();
  }

  // Fetch alternate trains for each train journey
  Future<void> fetchAlternateTrainsForAllJourneys() async {
    debugPrint('=== STARTING ALTERNATE TRAINS FETCH ===');
    if (!hasTrainTransportation()) {
      debugPrint('No train transportation found, skipping alternate trains fetch');
      return;
    }
    
    isLoadingAlternateTrains.value = true;
    alternateTrains.clear();
    
    try {
      final transportation = travelDetails.value.transportation;
      if (transportation == null) {
        debugPrint('Transportation is null, skipping alternate trains fetch');
        return;
      }
      
      // Extract station codes once
      final sourceCode = extractSourceStationCode();
      final destCode = extractDestinationStationCode();
      final sourceName = extractSourceStationName();
      final destName = extractDestinationStationName();
      
      debugPrint('Extracted station codes:');
      debugPrint('  Source: $sourceName ($sourceCode)');
      debugPrint('  Destination: $destName ($destCode)');
      
      // Fetch for outbound journey if it's a train
      if (transportation.outbound != null && 
          transportation.outbound!.mode.toLowerCase() == 'train') {
        debugPrint('Fetching alternate trains for outbound journey');
        await _fetchAlternateTrainsForJourney(
          'outbound',
          sourceName ?? '',
          sourceCode ?? '',
          destName ?? '',
          destCode ?? '',
        );
      }
      
      // Fetch for return journey if it's a train
      if (transportation.returnLeg != null && 
          transportation.returnLeg!.mode.toLowerCase() == 'train') {
        debugPrint('Fetching alternate trains for return journey');
        await _fetchAlternateTrainsForJourney(
          'return',
          destName ?? '',
          destCode ?? '',
          sourceName ?? '',
          sourceCode ?? '',
        );
      }
      
      // Fetch for individual trains in the trains array
      if (transportation.trains?.isNotEmpty == true) {
        debugPrint('Fetching alternate trains for ${transportation.trains!.length} individual trains');
        for (int i = 0; i < transportation.trains!.length; i++) {
          final train = transportation.trains![i];
          debugPrint('Processing train $i: ${train.name} (${train.number})');
          
          final sourceStation = train.departure?.station ?? sourceName ?? '';
          final destStation = train.arrival?.station ?? destName ?? '';
          final trainSourceCode = sourceCode ?? '';
          final trainDestCode = destCode ?? '';
          
          debugPrint('Train $i station info:');
          debugPrint('  Source: $sourceStation ($trainSourceCode)');
          debugPrint('  Destination: $destStation ($trainDestCode)');
          
          await _fetchAlternateTrainsForJourney(
            'train_$i',
            sourceStation,
            trainSourceCode,
            destStation,
            trainDestCode,
          );
        }
      }
      
      debugPrint('Alternate trains fetch completed. Total journeys: ${alternateTrains.length}');
      for (final entry in alternateTrains.entries) {
        debugPrint('  ${entry.key}: ${entry.value.data.length} trains');
      }
    } catch (e) {
      debugPrint('Error fetching alternate trains: $e');
    } finally {
      isLoadingAlternateTrains.value = false;
    }
  }

  Future<void> _fetchAlternateTrainsForJourney(
    String journeyKey,
    String sourceName,
    String sourceCode,
    String destinationName,
    String destinationCode,
  ) async {
    debugPrint('=== FETCHING ALTERNATE TRAINS FOR $journeyKey ===');
    debugPrint('Original Source Name: $sourceName');
    debugPrint('Original Source Code: $sourceCode');
    debugPrint('Original Destination Name: $destinationName');
    debugPrint('Original Destination Code: $destinationCode');
    
    if (sourceCode.isEmpty || destinationCode.isEmpty) {
      debugPrint('Skipping alternate trains for $journeyKey: missing station codes');
      debugPrint('Source code empty: ${sourceCode.isEmpty}');
      debugPrint('Destination code empty: ${destinationCode.isEmpty}');
      
      // Try to extract codes again if they're missing
      if (sourceCode.isEmpty) {
        sourceCode = extractSourceStationCode() ?? '';
        debugPrint('Retried source code extraction: $sourceCode');
      }
      if (destinationCode.isEmpty) {
        destinationCode = extractDestinationStationCode() ?? '';
        debugPrint('Retried destination code extraction: $destinationCode');
      }
      
      if (sourceCode.isEmpty || destinationCode.isEmpty) {
        debugPrint('Still missing station codes after retry, skipping $journeyKey');
        return;
      }
    }
    
    // Use better station names for API compatibility
    final betterSourceName = getBetterStationName(sourceName, sourceCode);
    final betterDestName = getBetterStationName(destinationName, destinationCode);
    
    debugPrint('Better Source Name: $betterSourceName');
    debugPrint('Better Destination Name: $betterDestName');
    
    try {
      final url = Uri.parse(
        'https://capitol-import-assisted-doors.trycloudflare.com/trains/json?src_name=${Uri.encodeComponent(betterSourceName)}&src_code=$sourceCode&dst_name=${Uri.encodeComponent(betterDestName)}&dst_code=$destinationCode'
      );
      
      debugPrint('Fetching alternate trains for $journeyKey: $url');
      
      final response = await http.get(
        url,
        headers: {
          'accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 30));
      
      debugPrint('Response status for $journeyKey: ${response.statusCode}');
      debugPrint('Response body for $journeyKey: ${response.body}');
      
      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        debugPrint('Parsed JSON for $journeyKey: $jsonData');
        
        final trainResponse = TrainMissResponse.fromJson(jsonData);
        debugPrint('Train response for $journeyKey:');
        debugPrint('  Success: ${trainResponse.success}');
        debugPrint('  Total count: ${trainResponse.totalCount}');
        debugPrint('  Message: ${trainResponse.message}');
        debugPrint('  Data length: ${trainResponse.data.length}');
        
        // Log each train in the response
        for (int i = 0; i < trainResponse.data.length; i++) {
          final train = trainResponse.data[i];
          debugPrint('  Train $i: ${train.trainName} (${train.trainNumber}) - ${train.source} to ${train.destination}');
        }
        
        alternateTrains[journeyKey] = trainResponse;
        debugPrint('Alternate trains stored for $journeyKey: ${trainResponse.data.length} trains');
        
        // Verify the data is stored correctly
        final storedData = alternateTrains[journeyKey];
        debugPrint('Verification - stored data for $journeyKey: ${storedData?.data.length ?? 0} trains');
      } else {
        debugPrint('Failed to fetch alternate trains for $journeyKey: ${response.statusCode}');
        debugPrint('Error response: ${response.body}');
        
        // Create an empty response for failed requests
        final emptyResponse = TrainMissResponse(
          success: false,
          data: [],
          totalCount: 0,
          timestamp: DateTime.now().toIso8601String(),
          message: 'Failed to fetch trains: ${response.statusCode}',
        );
        alternateTrains[journeyKey] = emptyResponse;
      }
    } catch (e) {
      debugPrint('Error fetching alternate trains for $journeyKey: $e');
      
      // Create an empty response for errors
      final errorResponse = TrainMissResponse(
        success: false,
        data: [],
        totalCount: 0,
        timestamp: DateTime.now().toIso8601String(),
        message: 'Error: ${e.toString()}',
      );
      alternateTrains[journeyKey] = errorResponse;
    }
  }

  // Get alternate trains for a specific journey
  TrainMissResponse? getAlternateTrainsForJourney(String journeyKey) {
    return alternateTrains[journeyKey];
  }

  // Check if alternate trains are available for a journey
  bool hasAlternateTrainsForJourney(String journeyKey) {
    final response = alternateTrains[journeyKey];
    debugPrint('Checking alternate trains for $journeyKey:');
    debugPrint('  Response exists: ${response != null}');
    if (response != null) {
      debugPrint('  Success: ${response.success}');
      debugPrint('  Data length: ${response.data.length}');
      debugPrint('  Message: ${response.message}');
    }
    return response != null && response.data.isNotEmpty;
  }

  // Manual method to trigger alternate trains fetch
  Future<void> refreshAlternateTrains() async {
    debugPrint('=== MANUALLY REFRESHING ALTERNATE TRAINS ===');
    await fetchAlternateTrainsForAllJourneys();
  }

  // Get detailed info about alternate trains for debugging
  void debugAlternateTrainsInfo() {
    debugPrint('=== ALTERNATE TRAINS DEBUG INFO ===');
    debugPrint('Total journeys with alternate trains: ${alternateTrains.length}');
    
    for (final entry in alternateTrains.entries) {
      final journeyKey = entry.key;
      final response = entry.value;
      
      debugPrint('Journey: $journeyKey');
      debugPrint('  Success: ${response.success}');
      debugPrint('  Total count: ${response.totalCount}');
      debugPrint('  Message: ${response.message}');
      debugPrint('  Data length: ${response.data.length}');
      
      for (int i = 0; i < response.data.length; i++) {
        final train = response.data[i];
        debugPrint('    Train $i: ${train.trainName} (${train.trainNumber})');
        debugPrint('      Route: ${train.source} → ${train.destination}');
        debugPrint('      Time: ${train.departureTime} - ${train.arrivalTime}');
        debugPrint('      Duration: ${train.duration}');
      }
    }
  }

  Future<void> _loadStationCodes() async {
    try {
      debugPrint('Loading station codes from JSON file...');
      final jsonString = await rootBundle.loadString('stationcode.json');
      final jsonData = jsonDecode(jsonString);
      final stations = jsonData['stations'] as List;
      
      for (final station in stations) {
        final code = station['stnCode'] as String;
        final name = station['stnName'] as String;
        final city = station['stnCity'] as String;
        
        // Store code -> name mapping
        stationCodeMap[code] = name;
        
        // Store name -> code mapping (multiple variations)
        final lowerName = name.toLowerCase();
        final lowerCity = city.toLowerCase();
        
        stationNameMap[lowerName] = code;
        stationNameMap[lowerCity] = code;
        
        // Add common variations
        if (name.contains('Junction')) {
          stationNameMap[name.replaceAll(' Junction', '').toLowerCase()] = code;
        }
        if (name.contains('Central')) {
          stationNameMap[name.replaceAll(' Central', '').toLowerCase()] = code;
        }
        if (name.contains('Cantt')) {
          stationNameMap[name.replaceAll(' Cantt', '').toLowerCase()] = code;
        }
      }
      
      isStationCodesLoaded = true;
      debugPrint('Loaded ${stationNameMap.length} station name variations');
      debugPrint('Loaded ${stationCodeMap.length} station codes');
      
      // Debug: Check for specific stations
      debugPrint('Jammu lookup: ${stationNameMap['jammu']}');
      debugPrint('Jammu Tawi lookup: ${stationNameMap['jammu tawi']}');
      debugPrint('Kolkata lookup: ${stationNameMap['kolkata']}');
      debugPrint('Howrah lookup: ${stationNameMap['howrah']}');
      
    } catch (e) {
      debugPrint('Error loading station codes: $e');
      // Fallback to hardcoded map
      _loadFallbackStationCodes();
    }
  }

  void _loadFallbackStationCodes() {
    debugPrint('Loading fallback station codes...');
    final fallbackMap = {
      'howrah': 'HWH',
      'kolkata': 'HWH',
      'jammu': 'JAT',
      'jammu tawi': 'JAT',
      'delhi': 'NDLS',
      'new delhi': 'NDLS',
      'mumbai': 'MMCT',
      'bangalore': 'SBC',
      'chennai': 'MAS',
      'hyderabad': 'HYB',
      'lucknow': 'LKO',
      'varanasi': 'BSB',
      'patna': 'PNBE',
      'guwahati': 'GHY',
      'bhubaneswar': 'BBS',
      'visakhapatnam': 'VSKP',
    };
    
    stationNameMap.addAll(fallbackMap);
    isStationCodesLoaded = true;
  }
}

class SaveResult {
  final bool success;
  final String message;
  final String? filePath;

  SaveResult({required this.success, required this.message, this.filePath});
}

class Accommodation {
  final String? name;
  final String? location;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final int? costPerNight;
  final int? totalCost;

  Accommodation({
    this.name,
    this.location,
    this.checkIn,
    this.checkOut,
    this.costPerNight,
    this.totalCost,
  });

  factory Accommodation.fromJson(Map<String, dynamic> json) {
    // Handle both hotel_name and name
    final hotelNameField = json["hotel_name"] ?? json["name"];
    // Handle both check_in/checkin and check_out/checkout
    final checkInField = json["check_in"] ?? json["checkin"];
    final checkOutField = json["check_out"] ?? json["checkout"];
    // Defensive: if any field is a list, just use the first string or null
    String? safeString(dynamic value) {
      if (value == null) return null;
      if (value is String) return value;
      if (value is List && value.isNotEmpty && value.first is String) return value.first;
      return null;
    }

    return Accommodation(
      name: safeString(hotelNameField),
      location: safeString(json["location"]),
      checkIn: safeString(checkInField) == null ? null : DateTime.tryParse(safeString(checkInField)!),
      checkOut: safeString(checkOutField) == null ? null : DateTime.tryParse(safeString(checkOutField)!),
      costPerNight: json["cost_per_night"],
      totalCost: json["total_cost"],
    );
  }
}
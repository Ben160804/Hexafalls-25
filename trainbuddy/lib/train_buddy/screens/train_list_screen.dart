import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

import 'dart:ui';
import '../models/train.dart';
import '../controllers/train_list_controller.dart';

class TrainListScreen extends StatefulWidget {
  const TrainListScreen({super.key});

  @override
  State<TrainListScreen> createState() => _TrainListScreenState();
}

class _TrainListScreenState extends State<TrainListScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final ValueNotifier<double> _scrollProgress = ValueNotifier(0.0);
  final ScrollController _scrollController = ScrollController();
  final TrainListController _trainListController = Get.put(TrainListController());
  bool _hasAnimated = false;
  late String journeyDate;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Get journey date from arguments
    final args = Get.arguments;
    if (args is Map && args['date'] != null) {
      journeyDate = args['date'];
    } else {
      journeyDate = '';
    }

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_hasAnimated) {
        setState(() {
          _hasAnimated = true;
        });
      }
    });

    // Animate in elements when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasAnimated) {
        _controller.forward();
      }
    });

    // Listen to scroll for parallax effect
    _scrollController.addListener(() {
      if (_scrollController.position.hasContentDimensions) {
        final progress = _scrollController.offset / 100;
        _scrollProgress.value = progress.clamp(0.0, 1.0);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    _scrollProgress.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trainData = _trainListController.trainData.value;
    final errorMessage = _trainListController.errorMessage.value;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            // Animated logo
            _hasAnimated
                ? Icon(
                    Icons.train_rounded,
                    color: Colors.white,
                    size: 28,
                  )
                : Icon(
                    Icons.train_rounded,
                    color: Colors.white,
                    size: 28,
                  )
                    .animate(controller: _controller)
                    .slide(begin: const Offset(-1, 0), end: Offset.zero, curve: Curves.easeOutQuint)
                    .then()
                    .shimmer(delay: 400.ms, duration: 1800.ms),
            const SizedBox(width: 8),
            _hasAnimated
                ? const Text(
                    'Available Trains',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  )
                : const Text(
                    'Available Trains',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 24,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black26,
                          blurRadius: 4,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  )
                      .animate(controller: _controller)
                      .fadeIn(duration: 600.ms, curve: Curves.easeOutQuint)
                      .slideX(begin: -0.2, end: 0, curve: Curves.easeOutQuint),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Get.back(),
        ),
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFFF86A3C), Color(0xFFF86A3C)],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          // Animated background as a separate widget
          Positioned.fill(
            child: _AnimatedBackground(scrollProgress: _scrollProgress),
          ),

          // Bottom curved container
          Positioned(
            top: 120,
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFF5F7FA),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(32),
                  topRight: Radius.circular(32),
                ),
              ),
            ).animate(controller: _controller)
                .slideY(begin: 0.2, end: 0, duration: 800.ms, curve: Curves.easeOutQuart),
          ),

          // Main content (animations here will NOT retrigger on scroll)
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (errorMessage != null) ...[
                  Padding(
                    padding: const EdgeInsets.all(32.0),
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              spreadRadius: 0,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, color: Color(0xFFF86A3C), size: 48),
                            const SizedBox(height: 16),
                            Text(
                              errorMessage,
                              style: const TextStyle(
                                color: Color(0xFF1F2937),
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ] else if (trainData != null) ...[
                // Move summary into white area
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _hasAnimated
                              ? Text(
                                  '${trainData.data.length} Trains Found',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFF86A3C),
                                  ),
                                )
                              : Text(
                                  '${trainData.data.length} Trains Found',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFF86A3C),
                                  ),
                                )
                                    .animate(controller: _controller)
                                    .fadeIn(duration: 600.ms)
                                    .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuint),
                          const SizedBox(height: 6),
                          _hasAnimated
                              ? Text(
                                  '${trainData.data.isNotEmpty ? trainData.data[0].source : "Source"} to ${trainData.data.isNotEmpty ? trainData.data[0].destination : "Destination"}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1F2937),
                                  ),
                                )
                              : Text(
                                  '${trainData.data.isNotEmpty ? trainData.data[0].source : "Source"} to ${trainData.data.isNotEmpty ? trainData.data[0].destination : "Destination"}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF1F2937),
                                  ),
                                )
                                    .animate(controller: _controller)
                                    .fadeIn(delay: 200.ms, duration: 600.ms)
                                    .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuint),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Trains listing
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: Scrollbar(
                      thumbVisibility: true,
                      controller: _scrollController,
                      child: ListView.builder(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.only(top: 8, bottom: 20),
                        itemCount: trainData.data.length,
                        itemBuilder: (context, index) {
                          final train = trainData.data[index];
                          return _buildTrainCard(context, train, index);
                        },
                      ),
                    ),
                  ),
                ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _parseRunningDays(String runningDays) {
    if (runningDays.length != 7) return 'Running days: Not specified';
    
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final runningDayNames = <String>[];
    
    for (int i = 0; i < 7; i++) {
      if (runningDays[i] == '1') {
        runningDayNames.add(days[i]);
      }
    }
    
    if (runningDayNames.isEmpty) return 'Not running on any day';
    if (runningDayNames.length == 7) return 'Running daily';
    
    return 'Runs on: ${runningDayNames.join(', ')}';
  }

  Widget _buildTrainCard(BuildContext context, TrainData train, int index) {
    String displayDate;
    if (journeyDate.isNotEmpty) {
      try {
        // Assuming journeyDate is in 'yyyyMMdd' format
        final parsedDate = DateFormat('yyyyMMdd').parse(journeyDate);
        displayDate = DateFormat('MMM dd, yyyy').format(parsedDate);
      } catch (e) {
        // Fallback if parsing fails
        displayDate = journeyDate; 
      }
    } else {
      displayDate = DateFormat('MMM dd, yyyy').format(DateTime.now());
    }

    Widget card = Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF86A3C).withOpacity(0.1),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              // Add train selection logic here
              Get.toNamed('/train-details', arguments: train);
            },
            splashColor: const Color(0xFFF86A3C).withOpacity(0.1),
            highlightColor: const Color(0xFFF86A3C).withOpacity(0.05),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Train name and number
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              train.trainName ?? 'Unknown Train',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Train No: ${train.trainNumber}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF86A3C).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          train.trainType ?? 'Unknown Type',
                          style: const TextStyle(
                            color: Color(0xFFF86A3C),
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 20),

                  // Running days information
                  if (train.runningDays != null && train.runningDays!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.calendar_today,
                            size: 16,
                            color: Color(0xFF1F2937),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _parseRunningDays(train.runningDays!),
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Journey details with enhanced visuals
                  Row(
                    children: [
                      // Departure section
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Source station
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF86A3C).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.train,
                                    color: Color(0xFFF86A3C),
                                    size: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    train.source ?? 'Unknown',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF1F2937),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),

                            // Departure time
                            Padding(
                              padding: const EdgeInsets.only(left: 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    train.departureTime ?? '--:--',
                                    style: const TextStyle(
                                      color: Color(0xFF1F2937),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (train.sourceDelay != null && train.sourceDelay! > 0)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Predicted delay for $displayDate: ${train.sourceDelay!.toStringAsFixed(0)} min',
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Journey time indicator
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              train.duration ?? '--:--',
                              style: TextStyle(
                                color: Colors.grey[700],
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                height: 2,
                                width: 60,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF86A3C).withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(1),
                                ),
                              ),
                              Icon(
                                Icons.arrow_forward,
                                color: const Color(0xFFF86A3C),
                                size: 18,
                              ),
                            ],
                          ),
                        ],
                      ),

                      // Arrival section
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            // Destination station
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Text(
                                    train.destination ?? 'Unknown',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF1F2937),
                                    ),
                                    textAlign: TextAlign.end,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF86A3C).withOpacity(0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.location_on,
                                    color: Color(0xFFF86A3C),
                                    size: 16,
                                  ),
                                ),
                              ],
                            ),

                            // Arrival time
                            Padding(
                              padding: const EdgeInsets.only(right: 16.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    train.arrivalTime ?? '--:--',
                                    style: const TextStyle(
                                      color: Color(0xFF1F2937),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (train.destinationDelay != null && train.destinationDelay! > 0)
                                    Container(
                                      margin: const EdgeInsets.only(top: 4),
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.red.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: Text(
                                        'Predicted delay for $displayDate: ${train.destinationDelay!.toStringAsFixed(0)} min',
                                        style: const TextStyle(
                                          color: Colors.red,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),
                  const Divider(height: 1, color: Color(0xFFEEEEEE)),
                  const SizedBox(height: 16),

                  // Train features
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Left side - tags
                      Expanded(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (train.hasPantry == true)
                              _buildFeatureTag(
                                Icons.restaurant,
                                'Pantry',
                                Colors.green,
                              ),
                            if (train.isLimitedRun == true)
                              _buildFeatureTag(
                                Icons.info_outline,
                                'Limited Run',
                                Colors.orange,
                              ),
                          ],
                        ),
                      ),

                      // Right side - buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton(
                            onPressed: () {
                              Get.toNamed('/train-details', arguments: train);
                            },
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: const Color(0xFFF86A3C),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              'View Details',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          // Remove the SizedBox and Predict Delay button
                        ],
                      ),
                    ],
                  ),

                  // Class badges
                  if (train.availableClasses.isNotEmpty) ...[
                    const SizedBox(height: 16),
                   /* Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: train.availableClasses.map((className) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF86A3C).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: const Color(0xFFF86A3C).withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            className,
                            style: const TextStyle(
                              color: Color(0xFFF86A3C),
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),*/
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
    // Only animate the first 6 cards if _hasAnimated is false
    if (!_hasAnimated && index < 6) {
      return card
          .animate(controller: _controller)
          .fadeIn(
            delay: Duration(milliseconds: 300 + (index * 100)),
            duration: const Duration(milliseconds: 600),
          )
          .slideY(begin: 0.2, end: 0)
          .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1));
    } else {
      return card;
    }
  }

  Widget _buildFeatureTag(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: color,
            size: 14,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedBackground extends StatelessWidget {
  final ValueNotifier<double> scrollProgress;
  const _AnimatedBackground({required this.scrollProgress});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<double>(
      valueListenable: scrollProgress,
      builder: (context, value, child) {
        return Stack(
          children: [
            // Moving gradient background
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: const [Color(0xFFF86A3C), Color(0xFFF86A3C)],
                    stops: [0.0 - (0.2 * value), 1.0 - (0.3 * value)],
                  ),
                ),
              ),
            ),
            // Floating circles background
            Positioned(
              top: -50 + (value * 20),
              left: -20 + (value * 10),
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.05),
                ),
              ),
            ),
            Positioned(
              top: 50 - (value * 30),
              right: -80 + (value * 20),
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.08),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
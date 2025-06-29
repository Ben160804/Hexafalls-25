import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:developer' as developer;
import 'dart:ui';
import '../models/train.dart';
import '../models/train_details.dart';
import '../controllers/train_details_controller.dart';

class TrainDetailsScreen extends StatefulWidget {
  const TrainDetailsScreen({super.key});

  @override
  State<TrainDetailsScreen> createState() => _TrainDetailsScreenState();
}

class _TrainDetailsScreenState extends State<TrainDetailsScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final ValueNotifier<double> _scrollProgress = ValueNotifier(0.0);
  final ScrollController _scrollController = ScrollController();
  late final TrainDetailsController controller;
  late final TrainData train;
  bool _hasAnimated = false;

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    train = Get.arguments as TrainData;
    controller = Get.put(TrainDetailsController());

    developer.log(
      'Building TrainDetailsScreen for train: ${train.trainName} (${train.trainNumber})',
      name: 'TrainDetailsScreen',
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_hasAnimated) {
        setState(() {
          _hasAnimated = true;
        });
      }
    });

    // Listen to scroll for parallax effect
    _scrollController.addListener(() {
      if (_scrollController.position.hasContentDimensions) {
        final progress = _scrollController.offset / 100;
        _scrollProgress.value = progress.clamp(0.0, 1.0);
      }
    });

    // Animate in elements when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasAnimated) {
        _controller.forward();
      }

      // Fetch train details when screen loads
      if (train.trainName != null && train.trainNumber != null) {
        developer.log(
          'Initiating train details fetch',
          name: 'TrainDetailsScreen',
        );
        controller.fetchTrainDetails(
          trainName: train.trainName!,
          trainNumber: train.trainNumber!,
          date: _formatDate(DateTime.now()),
        );
      } else {
        developer.log(
          'Invalid train data: name or number is null',
          name: 'TrainDetailsScreen',
          error: 'Invalid Data',
        );
        controller.errorMessage.value = 'Invalid train information';
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            // Animated train icon
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
                ? Text(
              train.trainName ?? 'Train Details',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
            )
                : Text(
              train.trainName ?? 'Train Details',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black26,
                    blurRadius: 4,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              overflow: TextOverflow.ellipsis,
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
          // Animated background
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

          // Main content
          SafeArea(
            child: Obx(() {
              developer.log(
                'Screen state: Loading: ${controller.isLoading.value}, Error: ${controller.errorMessage.value}, Has Details: ${controller.trainDetails.value != null}',
                name: 'TrainDetailsScreen',
              );

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header info card - train number
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
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _hasAnimated
                                ? Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Train #${train.trainNumber}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFF86A3C),
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
                            )
                                : Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Train #${train.trainNumber}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFFF86A3C),
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
                            ).animate(controller: _controller)
                                .fadeIn(duration: 600.ms)
                                .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuint),
                            const SizedBox(height: 6),
                            _hasAnimated
                                ? Text(
                              '${train.source ?? "Source"} to ${train.destination ?? "Destination"}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1F2937),
                              ),
                            )
                                : Text(
                              '${train.source ?? "Source"} to ${train.destination ?? "Destination"}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Color(0xFF1F2937),
                              ),
                            ).animate(controller: _controller)
                                .fadeIn(delay: 200.ms, duration: 600.ms)
                                .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuint),

                            if (train.duration != null) ...[
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 16,
                                    color: Colors.grey[600],
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Journey Duration: ${train.duration}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Main content area
                  Expanded(
                    child: _getMainContent(),
                  ),
                ],
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _getMainContent() {
    if (controller.isLoading.value) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF86A3C)),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Text(
                'Loading train details...',
                style: TextStyle(
                  color: Color(0xFF1F2937),
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (controller.errorMessage.isNotEmpty) {
      developer.log(
        'Showing error state: ${controller.errorMessage.value}',
        name: 'TrainDetailsScreen',
        error: controller.errorMessage.value,
      );
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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
                const Icon(
                  Icons.error_outline,
                  color: Color(0xFFF86A3C),
                  size: 48,
                ),
                const SizedBox(height: 12),
                Text(
                  controller.errorMessage.value,
                  style: const TextStyle(
                    color: Color(0xFF1F2937),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    if (train.trainName != null && train.trainNumber != null) {
                      developer.log(
                        'Retrying train details fetch',
                        name: 'TrainDetailsScreen',
                      );
                      controller.fetchTrainDetails(
                        trainName: train.trainName!,
                        trainNumber: train.trainNumber!,
                        date: _formatDate(DateTime.now()),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFF86A3C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final details = controller.trainDetails.value;
    if (details == null || details.data == null) {
      developer.log(
        'No train details available',
        name: 'TrainDetailsScreen',
      );
      return Center(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: const Text(
            'No details available',
            style: TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    developer.log(
      'Rendering train details with ${details.data!.schedule.length} stations',
      name: 'TrainDetailsScreen',
    );

    return RefreshIndicator(
      onRefresh: () async {
        if (train.trainName != null && train.trainNumber != null) {
          developer.log(
            'Refreshing train details',
            name: 'TrainDetailsScreen',
          );
          await controller.fetchTrainDetails(
            trainName: train.trainName!,
            trainNumber: train.trainNumber!,
            date: _formatDate(DateTime.now()),
          );
        }
      },
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTrainInfoCard(details.data!.trainInfo),
            _buildScheduleCard(details.data!.schedule),
          ],
        ),
      ),
    );
  }

  Widget _buildTrainInfoCard(TrainInfo? info) {
    if (info == null) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 12),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'Train information not available',
            style: TextStyle(
              color: Color(0xFF1F2937),
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF86A3C).withOpacity(0.1),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: Color(0xFFF86A3C),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Train Information',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildInfoRow(
              Icons.airline_seat_recline_normal_rounded,
              'Available Classes',
              info.availableClasses ?? 'Not specified'
          ),
          const Divider(height: 24, thickness: 1, color: Color(0xFFEEEEEE)),
          _buildInfoRow(
              Icons.calendar_today_rounded,
              'Running Days',
              info.runningDays ?? 'Not specified'
          ),
          const Divider(height: 24, thickness: 1, color: Color(0xFFEEEEEE)),
          _buildInfoRow(
            Icons.restaurant_rounded,
            'Pantry Car',
            (info.hasPantry ?? false) ? 'Available' : 'Not Available',
            iconColor: (info.hasPantry ?? false) ? Colors.green : Colors.red,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value, {Color? iconColor}) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: (iconColor ?? const Color(0xFFF86A3C)).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: iconColor ?? const Color(0xFFF86A3C),
            size: 16,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildScheduleCard(List<Schedule> schedule) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFF86A3C).withOpacity(0.1),
            blurRadius: 12,
            spreadRadius: 2,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.timeline_rounded,
                color: Color(0xFFF86A3C),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Station Schedule',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1F2937),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: schedule.length,
            itemBuilder: (context, index) {
              final station = schedule[index];
              return _buildStationRow(
                station,
                index == schedule.length - 1,
                index == 0,  // is first station
                index == schedule.length - 1, // is last station
                index,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStationRow(Schedule station, bool isLast, bool isFirst, bool isDestination, int index) {
    // Calculate predicted arrival time
    String getPredictedTime(String? scheduledTime, double? delay) {
      if (scheduledTime == null || delay == null) return '--:--';
      try {
        final parts = scheduledTime.split(':');
        if (parts.length != 2) return '--:--';

        int hours = int.parse(parts[0]);
        int minutes = int.parse(parts[1]);

        // Add delay minutes
        minutes += delay.round();
        hours += minutes ~/ 60;
        minutes = minutes % 60;
        hours = hours % 24;

        return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
      } catch (e) {
        return '--:--';
      }
    }

    return Container(
  padding: const EdgeInsets.symmetric(vertical: 12),
  child: Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Column(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isFirst || isDestination
                  ? const Color(0xFFF86A3C)
                  : const Color(0xFFF86A3C).withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: isFirst || isDestination
                    ? const Color(0xFFF86A3C)
                    : const Color(0xFFF86A3C).withOpacity(0.5),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                station.stationNumber?.toString() ?? '-',
                style: TextStyle(
                  color: isFirst || isDestination
                      ? Colors.white
                      : const Color(0xFFF86A3C),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          if (!isLast)
            Container(
              width: 2,
              height: 70,
              color: const Color(0xFFF86A3C).withOpacity(0.3),
            ),
        ],
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Colors.grey.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          station.name ?? 'Unknown Station',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: isFirst
                                ? Colors.green.shade700
                                : isDestination
                                    ? Colors.red.shade700
                                    : const Color(0xFF1F2937),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.business,
                              size: 12,
                              color: Colors.grey[600],
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'Platform: ${station.platform ?? 'TBD'}',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  ...[  // Wrap conditionals in a spread operator
                    if (isFirst)
                      _buildStatusBadge('Departure', Colors.green)
                    else if (isDestination)
                      _buildStatusBadge('Arrival', Colors.red)
                    else
                      _buildStatusBadge('Stop', Colors.orange)
                  ],
                ],
              ),
              const SizedBox(height: 12),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Scheduled Arrival',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule,
                              size: 14,
                              color: Color(0xFF1F2937),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              station.arrival ?? '--:--',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Predicted Arrival',
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.schedule,
                                  size: 14,
                                  color: Color(0xFF1F2937),
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    getPredictedTime(station.arrival, station.predictedDelay),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 13,
                                      color: Color(0xFF1F2937),
                                    ),
                                  ),
                                ),
                                if (station.predictedDelay != null && station.predictedDelay != 0)
                                  Padding(
                                    padding: const EdgeInsets.only(left: 8),
                                    child: Text(
                                      '(${(station.predictedDelay ?? 0) > 0 ? '+' : ''}${station.predictedDelay?.toStringAsFixed(1)} min)',
                                      style: TextStyle(
                                        color: (station.predictedDelay ?? 0) > 0
                                            ? Colors.red
                                            : Colors.green,
                                        fontSize: 12,
                                      ),
                                    ), 
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                /* if (station.predictedDelay != null && station.predictedDelay != 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: (station.predictedDelay ?? 0) > 0
                            ? Colors.red.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            (station.predictedDelay ?? 0) > 0
                                ? Icons.watch_later_outlined
                                : Icons.thumb_up_alt_outlined,
                            size: 14,
                            color: (station.predictedDelay ?? 0) > 0
                                ? Colors.red
                                : Colors.green,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${(station.predictedDelay ?? 0) > 0 ? '+' : ''}${station.predictedDelay?.toStringAsFixed(1)} min',
                            style: TextStyle(
                              color: (station.predictedDelay ?? 0) > 0
                                  ? Colors.red
                                  : Colors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),*/
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Scheduled Departure',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(
                              Icons.schedule,
                              size: 14,
                              color: Color(0xFF1F2937),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              station.departure ?? '--:--',
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 13,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Predicted Departure',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              const Icon(
                                Icons.schedule,
                                size: 14,
                                color: Color(0xFF1F2937),
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  getPredictedTime(station.departure, station.predictedDelay),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFF1F2937),
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (station.predictedDelay != null && station.predictedDelay != 0)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: Text(
                                    '(${(station.predictedDelay ?? 0) > 0 ? '+' : ''}${station.predictedDelay?.toStringAsFixed(1)} min)',
                                    style: TextStyle(
                                      color: (station.predictedDelay ?? 0) > 0
                                          ? Colors.red
                                          : Colors.green,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),),
                ],
              ),
              if (!isFirst && !isDestination && station.arrival != null && station.departure != null) ...[
    const SizedBox(height: 12),
    Row(
    children: [
    Icon(
    Icons.hourglass_bottom,
    size: 14,
    color: Colors.grey[600],
    ),
    const SizedBox(width: 4),
    Text(
    'Halt time: ${_calculateHaltTime(station.arrival!, station.departure!)}',
    style: TextStyle(
    fontSize: 12,
    color: Colors.grey[600],
    ),
    ),
    ],
    ),
    ],
    const SizedBox(height: 8),
    Row(
    children: [
    const SizedBox(width: 4),
    Flexible(
      child: Text(
        'Predicted departure: ${_calculatePredictedDeparture(station.arrival!, station.predictedDelay, _calculateHaltTime(station.arrival!, station.departure!))}',
        style: TextStyle(
          fontSize: 12,
          color: Colors.grey[600],
          fontWeight: FontWeight.bold,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    ),
    ],
    ),
    ],
    ),
    ),
      )
    ],
    ),
    );

  }

  String _calculateHaltTime(String arrival, String departure) {
    try {
      final arrivalParts = arrival.split(':');
      final departureParts = departure.split(':');

      if (arrivalParts.length != 2 || departureParts.length != 2) {
        return 'N/A';
      }

      int arrivalHours = int.parse(arrivalParts[0]);
      int arrivalMinutes = int.parse(arrivalParts[1]);
      int departureHours = int.parse(departureParts[0]);
      int departureMinutes = int.parse(departureParts[1]);

      // Convert to minutes since midnight
      int arrivalTotalMinutes = arrivalHours * 60 + arrivalMinutes;
      int departureTotalMinutes = departureHours * 60 + departureMinutes;

      // Handle crossing midnight
      if (departureTotalMinutes < arrivalTotalMinutes) {
        departureTotalMinutes += 24 * 60; // Add a day
      }

      int diffMinutes = departureTotalMinutes - arrivalTotalMinutes;

      if (diffMinutes < 1) {
        return '< 1 min';
      } else if (diffMinutes < 60) {
        return '$diffMinutes min';
      } else {
        int hours = diffMinutes ~/ 60;
        int remainingMinutes = diffMinutes % 60;
        return '$hours h ${remainingMinutes > 0 ? '$remainingMinutes min' : ''}';
      }
    } catch (e) {
      return 'N/A';
    }
  }

  String _calculatePredictedDeparture(String arrival, double? predictedDelay, String haltTime) {
    try {
      if (predictedDelay == null) return 'N/A';
      
      final arrivalParts = arrival.split(':');
      if (arrivalParts.length != 2) return 'N/A';
      
      int arrivalHours = int.parse(arrivalParts[0]);
      int arrivalMinutes = int.parse(arrivalParts[1]);
      
      // Calculate predicted arrival time by adding delay
      int delayMinutes = predictedDelay.round();
      int predictedArrivalMinutes = arrivalHours * 60 + arrivalMinutes + delayMinutes;
      
      // Parse halt time to get minutes
      int haltMinutes = 0;
      if (haltTime.contains('h')) {
        final parts = haltTime.split('h');
        haltMinutes += int.parse(parts[0].trim()) * 60;
        if (parts.length > 1 && parts[1].contains('min')) {
          haltMinutes += int.parse(parts[1].replaceAll('min', '').trim());
        }
      } else if (haltTime.contains('min')) {
        haltMinutes = int.parse(haltTime.replaceAll('min', '').trim());
      }
      
      // Calculate predicted departure
      int predictedDepartureMinutes = predictedArrivalMinutes + haltMinutes;
      
      // Convert back to hours:minutes format
      int hours = (predictedDepartureMinutes ~/ 60) % 24;
      int minutes = predictedDepartureMinutes % 60;
      
      return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
    } catch (e) {
      return 'N/A';
    }
  }

  Widget _buildStatusBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

// Animated background with parallax effect
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
            // Top gradient background
            Container(
              height: 200 - (value * 20).clamp(0.0, 30.0),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF86A3C), Color(0xFFF86A3C)],
                ),
              ),
            ),

            // Background decorative elements
            Positioned(
              top: 10 - (value * 5),
              right: 20 - (value * 10),
              child: Opacity(
                opacity: 0.3,
                child: Transform.rotate(
                  angle: -0.2,
                  child: Icon(
                    Icons.train_rounded,
                    size: 60,
                    color: Colors.white.withOpacity(0.7),
                  ),
                ),
              ),
            ),

            // More decorative elements
            Positioned(
              top: 70 - (value * 10),
              left: 40 - (value * 20),
              child: Opacity(
                opacity: 0.2,
                child: Icon(
                  Icons.route_rounded,
                  size: 40,
                  color: Colors.white.withOpacity(0.7),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
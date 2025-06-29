import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:developer' as developer;
import 'dart:ui';
import 'dart:async';
import '../models/train_model.dart';
import '../controllers/train_detail_controller.dart';
import 'package:intl/intl.dart';

class ParticularTrainScreen extends StatefulWidget {
  final String trainName;
  final String trainNumber;
  final String date;

  const ParticularTrainScreen({
    super.key,
    required this.trainName,
    required this.trainNumber,
    required this.date,
  });

  @override
  State<ParticularTrainScreen> createState() => _ParticularTrainScreenState();
}

class _ParticularTrainScreenState extends State<ParticularTrainScreen> 
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final AnimationController _mainController;
  late final AnimationController _scrollController;
  late final AnimationController _parallaxController;
  
  final ValueNotifier<double> _scrollProgress = ValueNotifier(0.0);
  final ScrollController _scrollControllerListener = ScrollController();
  late final TrainDetailsController controller;
  bool _hasAnimated = false;

  // Debouncing variables
  Timer? _scrollDebounceTimer;
  bool _isRefreshing = false;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    
    // Initialize multiple animation controllers
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    
    _scrollController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _parallaxController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    controller = Get.put(TrainDetailsController());

    developer.log(
      'Building ParticularTrainScreen for train: ${widget.trainName} (${widget.trainNumber}) on ${widget.date}',
      name: 'ParticularTrainScreen',
    );

    _mainController.addStatusListener((status) {
      if (status == AnimationStatus.completed && !_hasAnimated) {
        setState(() {
          _hasAnimated = true;
        });
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_hasAnimated) {
        _mainController.forward();
      }

      // Fetch train details when screen loads
      developer.log(
        'Initiating train details fetch',
        name: 'ParticularTrainScreen',
      );
      controller.fetchTrainDetails(
        trainName: widget.trainName,
        trainNumber: widget.trainNumber,
        date: widget.date,
      );
    });

    // Debounced scroll listener for better performance
    _scrollControllerListener.addListener(_debouncedScrollListener);
  }

  void _debouncedScrollListener() {
    if (_scrollDebounceTimer?.isActive ?? false) {
      _scrollDebounceTimer!.cancel();
    }
    
    _scrollDebounceTimer = Timer(const Duration(milliseconds: 16), () {
      if (_scrollControllerListener.position.hasContentDimensions) {
        final progress = _scrollControllerListener.offset / 150;
        _scrollProgress.value = progress.clamp(0.0, 1.0);
        
        // Parallax effect
        _parallaxController.value = progress;
      }
    });
  }

  Future<void> _onRefresh() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Refresh train details
    await controller.fetchTrainDetails(
      trainName: widget.trainName,
      trainNumber: widget.trainNumber,
      date: widget.date,
    );
    
    setState(() {
      _isRefreshing = false;
    });
  }

  @override
  void dispose() {
    _mainController.dispose();
    _scrollController.dispose();
    _parallaxController.dispose();
    _scrollControllerListener.dispose();
    _scrollProgress.dispose();
    _scrollDebounceTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Required for AutomaticKeepAliveClientMixin
    
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth >= 600;
    final padding = screenWidth * 0.05;
    final fontScale = isTablet ? 1.2 : 1.0;
    final iconSize = isTablet ? 28.0 : 22.0;
    final titleFontSize = 22.0 * fontScale;
    final subtitleFontSize = 16.0 * fontScale;
    final sectionTitleFontSize = 18.0 * fontScale;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      extendBodyBehindAppBar: true,
      appBar: _buildGlassmorphismAppBar(titleFontSize, iconSize, padding),
      body: Stack(
        children: [
          _buildParallaxBackground(screenWidth),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderSection(padding, fontScale, subtitleFontSize),
                SizedBox(height: padding * 1.5),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _onRefresh,
                    color: const Color(0xFF00E676),
                    backgroundColor: const Color(0xFF1E1E1E),
                    child: SingleChildScrollView(
                      controller: _scrollControllerListener,
                      physics: const BouncingScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding),
                      child: _buildTrainDetailsContent(screenWidth, fontScale, sectionTitleFontSize, subtitleFontSize, iconSize, padding),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildScrollIndicator(padding, fontScale),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildGlassmorphismAppBar(double titleFontSize, double iconSize, double padding) {
    return AppBar(
      elevation: 0,
      backgroundColor: Colors.transparent,
      flexibleSpace: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF000000).withOpacity(0.8),
                  const Color(0xFF1E1E1E).withOpacity(0.6),
                ],
              ),
              border: Border(
                bottom: BorderSide(
                  color: const Color(0xFF00E676).withOpacity(0.2),
                  width: 1,
                ),
              ),
            ),
          ),
        ),
      ),
      title: Row(
        children: [
          // Animated train icon
          _hasAnimated
              ? Icon(
                  Icons.train_rounded,
                  color: const Color(0xFF00E676),
                  size: iconSize,
                )
              : Icon(
                  Icons.train_rounded,
                  color: const Color(0xFF00E676),
                  size: iconSize,
                )
                  .animate(controller: _mainController)
                  .slide(begin: const Offset(-1, 0), end: Offset.zero, curve: Curves.easeOutQuint)
                  .then()
                  .shimmer(delay: 400.ms, duration: 1800.ms),
          const SizedBox(width: 8),
          Flexible(
            child: _hasAnimated
                ? Text(
                    widget.trainName,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: titleFontSize,
                      color: const Color(0xFFFFFFFF),
                      shadows: [
                        Shadow(
                          color: const Color(0xFF00E676).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                  )
                : Text(
                    widget.trainName,
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: titleFontSize,
                      color: const Color(0xFFFFFFFF),
                      shadows: [
                        Shadow(
                          color: const Color(0xFF00E676).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    overflow: TextOverflow.ellipsis,
                  )
                    .animate(controller: _mainController)
                    .fadeIn(duration: 600.ms, curve: Curves.easeOutQuint)
                    .slideX(begin: -0.2, end: 0, curve: Curves.easeOutQuint),
          ),
        ],
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Color(0xFF00E676), size: 22),
        onPressed: () => Get.back(),
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.refresh, color: const Color(0xFF00E676), size: iconSize),
          onPressed: () {
            HapticFeedback.lightImpact();
            _onRefresh();
          },
          tooltip: 'Refresh',
        ).animate(controller: _mainController)
            .fadeIn(duration: 500.ms)
            .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
      ],
    );
  }

  Widget _buildParallaxBackground(double screenWidth) {
    return AnimatedBuilder(
      animation: _parallaxController,
      builder: (context, child) {
        return Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF000000),
                  const Color(0xFF1E1E1E).withOpacity(0.9),
                ],
              ),
            ),
            child: Stack(
              children: [
                // Parallax circle 1
                Positioned(
                  top: -60 + (_parallaxController.value * 30),
                  left: -screenWidth * 0.3 + (_parallaxController.value * 20),
                  child: Container(
                    width: screenWidth * 0.55,
                    height: screenWidth * 0.55,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF00E676).withOpacity(0.3),
                          const Color(0xFF69F0AE).withOpacity(0.1),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 1200.ms, delay: 300.ms),
                ),
                // Parallax circle 2
                Positioned(
                  bottom: -100 + (_parallaxController.value * 40),
                  right: -screenWidth * 0.35 - (_parallaxController.value * 15),
                  child: Container(
                    width: screenWidth * 0.65,
                    height: screenWidth * 0.65,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF00C853).withOpacity(0.2),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 1200.ms, delay: 500.ms),
                ),
                // Parallax circle 3
                Positioned(
                  top: 100 - (_parallaxController.value * 20),
                  right: screenWidth * 0.05 + (_parallaxController.value * 10),
                  child: Container(
                    width: screenWidth * 0.45,
                    height: screenWidth * 0.45,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          const Color(0xFF69F0AE).withOpacity(0.15),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ).animate().fadeIn(duration: 1200.ms, delay: 700.ms),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeaderSection(double padding, double fontScale, double subtitleFontSize) {
    return Padding(
      padding: EdgeInsets.only(left: padding, top: padding / 2, right: padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Train Status & Schedule',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: 32.0 * fontScale,
              fontWeight: FontWeight.w800,
              color: const Color(0xFFFFFFFF),
              letterSpacing: -0.5,
              shadows: [
                Shadow(
                  color: const Color(0xFF00E676).withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
          ).animate(controller: _mainController)
              .fadeIn(duration: 700.ms)
              .slideY(begin: 0.2, end: 0),
          SizedBox(height: padding / 2),
          Text(
            'Real-time updates for ${widget.trainName}',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: subtitleFontSize,
              color: const Color(0xFFE0E0E0),
              fontWeight: FontWeight.w400,
            ),
          ).animate(controller: _mainController)
              .fadeIn(duration: 700.ms, delay: 200.ms)
              .slideY(begin: 0.2, end: 0),
        ],
      ),
    );
  }

  Widget _buildScrollIndicator(double padding, double fontScale) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + padding,
      right: padding,
      child: ValueListenableBuilder<double>(
        valueListenable: _scrollProgress,
        builder: (context, value, child) {
          return AnimatedOpacity(
            opacity: value > 0.1 ? 1.0 : 0.0,
            duration: const Duration(milliseconds: 300),
            child: Container(
              width: 4,
              height: 60 * fontScale,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    const Color(0xFF00E676).withOpacity(0.3),
                    const Color(0xFF00E676),
                    const Color(0xFF00E676).withOpacity(0.3),
                  ],
                ),
              ),
              child: FractionallySizedBox(
                alignment: Alignment.topCenter,
                heightFactor: value,
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(2),
                    color: const Color(0xFF00E676),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildTrainDetailsContent(double screenWidth, double fontScale, double sectionTitleFontSize, double subtitleFontSize, double iconSize, double padding) {
    final spacing = screenWidth * 0.08;
    
    return Obx(() {
      if (controller.isLoading.value) {
        return Column(
          children: [
            SizedBox(height: spacing * 2),
            const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E676)),
              ),
            ),
            SizedBox(height: spacing),
            Text(
              'Loading train details...',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: subtitleFontSize,
                color: const Color(0xFFE0E0E0),
              ),
            ),
          ],
        );
      }

      if (controller.errorMessage.value.isNotEmpty) {
        return Column(
          children: [
            SizedBox(height: spacing * 2),
            _buildSectionCard(
              'Error',
              Icons.error_outline,
              [
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 64,
                        color: const Color(0xFFF44336),
                      ),
                      SizedBox(height: spacing),
                      Text(
                        'Error Loading Train Details',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: sectionTitleFontSize,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFF44336),
                        ),
                      ),
                      SizedBox(height: spacing / 2),
                      Text(
                        controller.errorMessage.value,
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: subtitleFontSize,
                          color: const Color(0xFFE0E0E0),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: spacing),
                      ElevatedButton(
                        onPressed: () {
                          controller.fetchTrainDetails(
                            trainName: widget.trainName,
                            trainNumber: widget.trainNumber,
                            date: widget.date,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF00E676),
                          padding: EdgeInsets.symmetric(horizontal: spacing, vertical: spacing / 2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Retry',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: subtitleFontSize,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF000000),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              fontScale: fontScale,
              sectionTitleFontSize: sectionTitleFontSize,
              subtitleFontSize: subtitleFontSize,
              iconSize: iconSize,
              padding: padding,
            ),
          ],
        );
      }

      final trainDetails = controller.trainDetails.value;
      if (trainDetails == null || trainDetails.data == null) {
        return Column(
          children: [
            SizedBox(height: spacing * 2),
            _buildSectionCard(
              'No Data',
              Icons.info_outline,
              [
                Center(
                  child: Text(
                    'No train details available',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: subtitleFontSize,
                      color: const Color(0xFFE0E0E0),
                    ),
                  ),
                ),
              ],
              fontScale: fontScale,
              sectionTitleFontSize: sectionTitleFontSize,
              subtitleFontSize: subtitleFontSize,
              iconSize: iconSize,
              padding: padding,
            ),
          ],
        );
      }

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTrainInfoCard(trainDetails, fontScale, sectionTitleFontSize, subtitleFontSize, iconSize, padding),
          SizedBox(height: spacing),
          _buildScheduleCard(trainDetails.data!.schedule, fontScale, sectionTitleFontSize, subtitleFontSize, iconSize, padding),
          if (trainDetails.data!.trainInfo != null) ...[
            SizedBox(height: spacing),
            _buildTrainInfoDetailsCard(trainDetails.data!.trainInfo!, fontScale, sectionTitleFontSize, subtitleFontSize, iconSize, padding),
          ],
          SizedBox(height: spacing * 2),
        ],
      );
    });
  }

  Widget _buildTrainInfoCard(TrainDetails trainDetails, double fontScale, double sectionTitleFontSize, double subtitleFontSize, double iconSize, double padding) {
    return _buildSectionCard(
      'Train Information',
      Icons.train,
      [
        Row(
          children: [
            Expanded(
              child: _buildInfoChip(
                icon: Icons.train,
                label: 'Train Name',
                value: widget.trainName,
                fontScale: fontScale,
                subtitleFontSize: subtitleFontSize,
              ),
            ),
            SizedBox(width: padding),
            Expanded(
              child: _buildInfoChip(
                icon: Icons.confirmation_number,
                label: 'Train Number',
                value: widget.trainNumber,
                fontScale: fontScale,
                subtitleFontSize: subtitleFontSize,
              ),
            ),
          ],
        ),
        SizedBox(height: padding),
        Row(
          children: [
            Expanded(
              child: _buildInfoChip(
                icon: Icons.calendar_today,
                label: 'Date',
                value: widget.date,
                fontScale: fontScale,
                subtitleFontSize: subtitleFontSize,
              ),
            ),
            SizedBox(width: padding),
            Expanded(
              child: _buildInfoChip(
                icon: Icons.schedule,
                label: 'Status',
                value: trainDetails.status ?? 'Unknown',
                fontScale: fontScale,
                subtitleFontSize: subtitleFontSize,
              ),
            ),
          ],
        ),
      ],
      fontScale: fontScale,
      sectionTitleFontSize: sectionTitleFontSize,
      subtitleFontSize: subtitleFontSize,
      iconSize: iconSize,
      padding: padding,
    ).animate(controller: _mainController)
        .fadeIn(delay: 400.ms, duration: 700.ms)
        .slideY(begin: 0.1, end: 0)
        .then()
        .shimmer(color: const Color(0xFF69F0AE), duration: 1000.ms);
  }

  Widget _buildScheduleCard(List<Schedule> schedule, double fontScale, double sectionTitleFontSize, double subtitleFontSize, double iconSize, double padding) {
    return _buildSectionCard(
      'Route Schedule',
      Icons.route,
      [
        ...schedule.asMap().entries.map((entry) {
          final station = entry.value;
          final index = entry.key;
          final isLast = index == schedule.length - 1;
          
          return _buildStationCard(station, index, isLast, fontScale, subtitleFontSize, padding);
        }).toList(),
      ],
      fontScale: fontScale,
      sectionTitleFontSize: sectionTitleFontSize,
      subtitleFontSize: subtitleFontSize,
      iconSize: iconSize,
      padding: padding,
    ).animate(controller: _mainController)
        .fadeIn(delay: 500.ms, duration: 700.ms)
        .slideY(begin: 0.1, end: 0)
        .then()
        .shimmer(color: const Color(0xFF69F0AE), duration: 1000.ms);
  }

  Widget _buildStationCard(Schedule station, int index, bool isLast, double fontScale, double subtitleFontSize, double padding) {
    final isSource = station.isSource ?? false;
    final isDestination = station.isDestination ?? false;
    
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : padding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline
          Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: isSource || isDestination 
                      ? const Color(0xFF00E676) 
                      : const Color(0xFF2196F3),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 3,
                  ),
                ),
              ),
              if (!isLast)
                Container(
                  width: 2,
                  height: 40,
                  color: const Color(0xFFE0E0E0),
                ),
            ],
          ),
          SizedBox(width: padding),
          // Station details
          Expanded(
            child: Container(
              padding: EdgeInsets.all(padding),
              decoration: BoxDecoration(
                color: (isSource || isDestination) 
                    ? const Color(0xFF00E676).withOpacity(0.1)
                    : Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(padding * 1.5),
                border: Border.all(
                  color: (isSource || isDestination) 
                      ? const Color(0xFF00E676)
                      : Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              station.name ?? 'Unknown Station',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: subtitleFontSize,
                                fontWeight: FontWeight.bold,
                                color: (isSource || isDestination) 
                                    ? const Color(0xFF00E676)
                                    : const Color(0xFFFFFFFF),
                              ),
                            ),
                            if (station.stationCode != null) ...[
                              SizedBox(height: 4),
                              Text(
                                'Code: ${station.stationCode}',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: subtitleFontSize * 0.8,
                                  color: const Color(0xFFE0E0E0),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (isSource)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: padding / 2, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E676),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'START',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: subtitleFontSize * 0.7,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF000000),
                            ),
                          ),
                        ),
                      if (isDestination)
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: padding / 2, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF00E676),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'END',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: subtitleFontSize * 0.7,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF000000),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: padding),
                  Row(
                    children: [
                      if (station.departure != null) ...[
                        Expanded(
                          child: _buildTimeChip(
                            icon: Icons.departure_board,
                            label: 'Departure',
                            time: station.departure!,
                            day: station.departureDay,
                            fontScale: fontScale,
                            subtitleFontSize: subtitleFontSize,
                          ),
                        ),
                      ],
                      if (station.arrival != null) ...[
                        if (station.departure != null) SizedBox(width: padding / 2),
                        Expanded(
                          child: _buildTimeChip(
                            icon: Icons.share_arrival_time_sharp,
                            label: 'Arrival',
                            time: station.arrival!,
                            day: station.arrivalDay,
                            fontScale: fontScale,
                            subtitleFontSize: subtitleFontSize,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (station.platform != null || station.predictedDelay != null) ...[
                    SizedBox(height: padding),
                    Row(
                      children: [
                        if (station.platform != null) ...[
                          Expanded(
                            child: _buildDetailChip(
                              icon: Icons.train,
                              label: 'Platform',
                              value: station.platform!,
                              fontScale: fontScale,
                              subtitleFontSize: subtitleFontSize,
                            ),
                          ),
                        ],
                        if (station.predictedDelay != null) ...[
                          if (station.platform != null) SizedBox(width: padding / 2),
                          Expanded(
                            child: _buildDetailChip(
                              icon: Icons.schedule,
                              label: 'Delay',
                              value: '${station.predictedDelay!.toStringAsFixed(1)} min',
                              isDelay: true,
                              fontScale: fontScale,
                              subtitleFontSize: subtitleFontSize,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  if (station.distance != null) ...[
                    SizedBox(height: padding / 2),
                    Text(
                      'Distance: ${station.distance} km',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: subtitleFontSize * 0.8,
                        color: const Color(0xFFE0E0E0),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainInfoDetailsCard(TrainInfo trainInfo, double fontScale, double sectionTitleFontSize, double subtitleFontSize, double iconSize, double padding) {
    return _buildSectionCard(
      'Additional Information',
      Icons.info_outline,
      [
        Row(
          children: [
            if (trainInfo.availableClasses != null) ...[
              Expanded(
                child: _buildInfoChip(
                  icon: Icons.airline_seat_recline_normal,
                  label: 'Classes',
                  value: trainInfo.availableClasses!,
                  fontScale: fontScale,
                  subtitleFontSize: subtitleFontSize,
                ),
              ),
            ],
            if (trainInfo.runningDays != null) ...[
              if (trainInfo.availableClasses != null) SizedBox(width: padding),
              Expanded(
                child: _buildInfoChip(
                  icon: Icons.calendar_view_week,
                  label: 'Running Days',
                  value: trainInfo.runningDays!,
                  fontScale: fontScale,
                  subtitleFontSize: subtitleFontSize,
                ),
              ),
            ],
          ],
        ),
        if (trainInfo.hasPantry != null) ...[
          SizedBox(height: padding),
          Row(
            children: [
              Icon(
                trainInfo.hasPantry! ? Icons.restaurant : Icons.no_food,
                color: trainInfo.hasPantry! ? const Color(0xFF00E676) : const Color(0xFFE0E0E0),
                size: iconSize,
              ),
              SizedBox(width: padding / 2),
              Text(
                trainInfo.hasPantry! ? 'Pantry Car Available' : 'No Pantry Car',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: subtitleFontSize,
                  color: trainInfo.hasPantry! ? const Color(0xFF00E676) : const Color(0xFFE0E0E0),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ],
      fontScale: fontScale,
      sectionTitleFontSize: sectionTitleFontSize,
      subtitleFontSize: subtitleFontSize,
      iconSize: iconSize,
      padding: padding,
    ).animate(controller: _mainController)
        .fadeIn(delay: 600.ms, duration: 700.ms)
        .slideY(begin: 0.1, end: 0)
        .then()
        .shimmer(color: const Color(0xFF69F0AE), duration: 1000.ms);
  }

  Widget _buildSectionCard(
      String title,
      IconData icon,
      List<Widget> children, {
        required double fontScale,
        required double sectionTitleFontSize,
        required double subtitleFontSize,
        required double iconSize,
        required double padding,
      }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(padding * 2),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF2C2F33).withOpacity(0.8),
                const Color(0xFF1E1E1E).withOpacity(0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(padding * 2),
            border: Border.all(
              color: const Color(0xFF00E676).withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00E676).withOpacity(0.1),
                blurRadius: padding * 2,
                offset: const Offset(0, 4),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: padding,
                offset: const Offset(0, 2),
              ),
              BoxShadow(
                color: const Color(0xFF00E676).withOpacity(0.05),
                blurRadius: padding * 4,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.all(padding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(padding / 2),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [const Color(0xFF00E676).withOpacity(0.1), const Color(0xFF69F0AE).withOpacity(0.1)],
                        ),
                        borderRadius: BorderRadius.circular(padding),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF00E676).withOpacity(0.2),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: const Color(0xFF00E676), size: iconSize),
                    ),
                    SizedBox(width: padding / 2),
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: sectionTitleFontSize,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFFFFFFFF),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: padding),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label, required String value, required double fontScale, required double subtitleFontSize}) {
    return Container(
      padding: EdgeInsets.all(subtitleFontSize * 0.75),
      decoration: BoxDecoration(
        color: const Color(0xFF00E676).withOpacity(0.1),
        borderRadius: BorderRadius.circular(subtitleFontSize * 0.75),
        border: Border.all(color: const Color(0xFF00E676).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF00E676), size: subtitleFontSize),
          SizedBox(height: subtitleFontSize * 0.5),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: subtitleFontSize * 0.7,
              color: const Color(0xFFE0E0E0),
            ),
          ),
          SizedBox(height: subtitleFontSize * 0.25),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: subtitleFontSize * 0.8,
              fontWeight: FontWeight.bold,
              color: const Color(0xFFFFFFFF),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildTimeChip({required IconData icon, required String label, required String time, int? day, required double fontScale, required double subtitleFontSize}) {
    return Container(
      padding: EdgeInsets.all(subtitleFontSize * 0.5),
      decoration: BoxDecoration(
        color: const Color(0xFF2196F3).withOpacity(0.1),
        borderRadius: BorderRadius.circular(subtitleFontSize * 0.5),
        border: Border.all(color: const Color(0xFF2196F3).withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF2196F3), size: subtitleFontSize * 0.8),
          SizedBox(height: subtitleFontSize * 0.25),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: subtitleFontSize * 0.6,
              color: const Color(0xFFE0E0E0),
            ),
          ),
          SizedBox(height: subtitleFontSize * 0.125),
          Text(
            time,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: subtitleFontSize * 0.7,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF2196F3),
            ),
          ),
          if (day != null && day > 1) ...[
            SizedBox(height: subtitleFontSize * 0.125),
            Text(
              '+${day - 1}',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: subtitleFontSize * 0.5,
                color: const Color(0xFFE0E0E0),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDetailChip({required IconData icon, required String label, required String value, bool isDelay = false, required double fontScale, required double subtitleFontSize}) {
    return Container(
      padding: EdgeInsets.all(subtitleFontSize * 0.5),
      decoration: BoxDecoration(
        color: isDelay 
            ? const Color(0xFFFF5722).withOpacity(0.1)
            : const Color(0xFF9C27B0).withOpacity(0.1),
        borderRadius: BorderRadius.circular(subtitleFontSize * 0.5),
        border: Border.all(
          color: isDelay 
              ? const Color(0xFFFF5722).withOpacity(0.3)
              : const Color(0xFF9C27B0).withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon, 
            color: isDelay ? const Color(0xFFFF5722) : const Color(0xFF9C27B0), 
            size: subtitleFontSize * 0.8
          ),
          SizedBox(height: subtitleFontSize * 0.25),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: subtitleFontSize * 0.6,
              color: const Color(0xFFE0E0E0),
            ),
          ),
          SizedBox(height: subtitleFontSize * 0.125),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: subtitleFontSize * 0.7,
              fontWeight: FontWeight.bold,
              color: isDelay ? const Color(0xFFFF5722) : const Color(0xFF9C27B0),
            ),
          ),
        ],
      ),
    );
  }
}

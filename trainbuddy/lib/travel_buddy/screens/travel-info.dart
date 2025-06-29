import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:trainbuddy/chatbot/screens/chat_screen.dart';
import 'package:trainbuddy/travel_buddy/controllers/travel-info-controller.dart';
import 'package:trainbuddy/travel_buddy/screens/travel-plan.dart';

class TravelInfoScreen extends StatefulWidget {
  const TravelInfoScreen({super.key});

  @override
  State<TravelInfoScreen> createState() => _TravelInfoScreenState();
}

class _TravelInfoScreenState extends State<TravelInfoScreen> 
    with TickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late final AnimationController _mainController;
  late final AnimationController _scrollController;
  late final AnimationController _parallaxController;
  
  final ValueNotifier<double> _scrollProgress = ValueNotifier(0.0);
  final ScrollController _scrollControllerListener = ScrollController();
  final TravelInfoController _travelInfoController = Get.put(TravelInfoController());

  final TextEditingController _sourceController = TextEditingController();
  final TextEditingController _destinationController = TextEditingController();
  final TextEditingController _travelDatesController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  final TextEditingController _adultsController = TextEditingController();
  final TextEditingController _childrenController = TextEditingController();

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _mainController.forward();
    });

    // Debounced scroll listener for better performance
    _scrollControllerListener.addListener(_debouncedScrollListener);
    _setupTextControllerListeners();
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

  void _setupTextControllerListeners() {
    _sourceController.addListener(() {
      _travelInfoController.updateTravelInfo(source: _sourceController.text);
    });
    _destinationController.addListener(() {
      _travelInfoController.updateTravelInfo(destination: _destinationController.text);
    });
    _travelDatesController.addListener(() {
      _travelInfoController.updateTravelInfo(travelDates: _travelDatesController.text);
    });
    _budgetController.addListener(() {
      final budget = double.tryParse(_budgetController.text) ?? 0.0;
      _travelInfoController.updateTravelInfo(budget: budget);
    });
    _adultsController.addListener(() {
      final adults = int.tryParse(_adultsController.text) ?? 0;
      _travelInfoController.updateTravelInfo(numberOfAdults: adults);
    });
    _childrenController.addListener(() {
      final children = int.tryParse(_childrenController.text) ?? 0;
      _travelInfoController.updateTravelInfo(numberOfChildren: children);
    });
  }

  Future<void> _onRefresh() async {
    if (_isRefreshing) return;
    
    setState(() {
      _isRefreshing = true;
    });

    // Haptic feedback
    HapticFeedback.lightImpact();

    // Simulate refresh delay
    await Future.delayed(const Duration(milliseconds: 800));
    
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
    _sourceController.dispose();
    _destinationController.dispose();
    _travelDatesController.dispose();
    _budgetController.dispose();
    _adultsController.dispose();
    _childrenController.dispose();
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
                      child: _buildTravelInfoForm(screenWidth, fontScale, sectionTitleFontSize, subtitleFontSize, iconSize, padding),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildScrollIndicator(padding, fontScale),
        ],
      ),
      floatingActionButton: _buildQuickActionFAB(padding, subtitleFontSize),
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
          Flexible(
            child: Text(
              'Plan Journey',
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
            ).animate(controller: _mainController)
                .fadeIn(duration: 600.ms)
                .slideX(begin: -0.2, end: 0),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.info_outline, color: const Color(0xFF00E676), size: iconSize),
          onPressed: () {
            HapticFeedback.lightImpact();
            _showTravelTips(context, 1.0, 16.0, padding, iconSize);
          },
          tooltip: 'Travel Tips',
        ).animate(controller: _mainController)
            .fadeIn(duration: 500.ms)
            .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
        IconButton(
          icon: Icon(Icons.smart_toy_rounded, color: const Color(0xFF00E676), size: iconSize),
          onPressed: () {
            HapticFeedback.lightImpact();
            Get.to(() => ChatScreen());
          },
          tooltip: 'AI Assistant',
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
            'Design Your Adventure',
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
            'Shape your dream trip with us.',
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

  Widget _buildQuickActionFAB(double padding, double subtitleFontSize) {
    return FloatingActionButton.extended(
      onPressed: () {
        HapticFeedback.mediumImpact();
        _showQuickActions(context, padding, subtitleFontSize);
      },
      backgroundColor: const Color(0xFF00E676),
      foregroundColor: const Color(0xFF000000),
      elevation: 8,
      icon: const Icon(Icons.flash_on),
      label: Text(
        'Quick Book',
        style: TextStyle(
          fontFamily: 'Poppins',
          fontWeight: FontWeight.w600,
          fontSize: subtitleFontSize * 0.9,
        ),
      ),
    ).animate(controller: _mainController)
        .fadeIn(delay: 1000.ms, duration: 700.ms)
        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1))
        .then()
        .shimmer(color: const Color(0xFF69F0AE), duration: 1200.ms);
  }

  Widget _buildTravelInfoForm(double screenWidth, double fontScale, double sectionTitleFontSize, double subtitleFontSize, double iconSize, double padding) {
    final spacing = screenWidth * 0.08;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionCard(
          'Where Are You Going?',
          Icons.location_on,
          [
            _buildInputField(
              controller: _sourceController,
              label: 'From',
              hint: 'Starting city',
              icon: Icons.my_location,
              fontScale: fontScale,
              subtitleFontSize: subtitleFontSize,
              padding: screenWidth * 0.035,
            ),
            SizedBox(height: spacing / 2),
            _buildInputField(
              controller: _destinationController,
              label: 'To',
              hint: 'Destination city',
              icon: Icons.location_on,
              fontScale: fontScale,
              subtitleFontSize: subtitleFontSize,
              padding: screenWidth * 0.035,
            ),
            SizedBox(height: spacing / 2),
            _buildInputField(
              controller: _travelDatesController,
              label: 'Travel Dates',
              hint: 'Select your dates',
              icon: Icons.calendar_today,
              keyboardType: TextInputType.none,
              onTap: () => _selectDateRange(context, fontScale, subtitleFontSize, padding),
              fontScale: fontScale,
              subtitleFontSize: subtitleFontSize,
              padding: screenWidth * 0.035,
            ),
          ],
          fontScale: fontScale,
          sectionTitleFontSize: sectionTitleFontSize,
          subtitleFontSize: subtitleFontSize,
          iconSize: iconSize,
          padding: screenWidth * 0.05,
        ).animate(controller: _mainController)
            .fadeIn(delay: 400.ms, duration: 700.ms)
            .slideY(begin: 0.1, end: 0)
            .then()
            .shimmer(color: const Color(0xFF69F0AE), duration: 1000.ms),
        SizedBox(height: spacing),
        _buildSectionCard(
          'Trip Details',
          Icons.flight_takeoff,
          [
            Obx(() => _buildSliderField(
              'Duration',
              '${_travelInfoController.duration.value} days',
              1,
              30,
              _travelInfoController.duration.value.toDouble(),
                  (value) => _travelInfoController.updateTravelInfo(duration: value.round()),
              Icons.schedule,
              fontScale: fontScale,
              subtitleFontSize: subtitleFontSize,
              iconSize: iconSize,
            )),
            SizedBox(height: spacing / 2),
            _buildInputField(
              controller: _adultsController,
              label: 'Adults',
              hint: 'Number of adults',
              icon: Icons.person,
              keyboardType: TextInputType.number,
              fontScale: fontScale,
              subtitleFontSize: subtitleFontSize,
              padding: screenWidth * 0.035,
            ),
            SizedBox(height: spacing / 2),
            _buildInputField(
              controller: _childrenController,
              label: 'Children',
              hint: 'Number of children',
              icon: Icons.child_care,
              keyboardType: TextInputType.number,
              fontScale: fontScale,
              subtitleFontSize: subtitleFontSize,
              padding: screenWidth * 0.035,
            ),
            SizedBox(height: spacing / 2),
            _buildInputField(
              controller: _budgetController,
              label: 'Budget (₹)',
              hint: 'Your total budget',
              icon: Icons.currency_rupee,
              keyboardType: TextInputType.number,
              fontScale: fontScale,
              subtitleFontSize: subtitleFontSize,
              padding: screenWidth * 0.035,
            ),
            SizedBox(height: spacing / 2),
            Obx(() => _buildDropdownField(
              'Trip Type',
              _travelInfoController.tripType.value,
              ['Solo', 'Nature', 'Cultural', 'Religious', 'family', 'Adventure'],
                  (value) => _travelInfoController.updateTravelInfo(tripType: value),
              Icons.explore,
              fontScale: fontScale,
              subtitleFontSize: subtitleFontSize,
              iconSize: iconSize,
              padding: screenWidth * 0.035,
            )),
          ],
          fontScale: fontScale,
          sectionTitleFontSize: sectionTitleFontSize,
          subtitleFontSize: subtitleFontSize,
          iconSize: iconSize,
          padding: screenWidth * 0.05,
        ).animate(controller: _mainController)
            .fadeIn(delay: 500.ms, duration: 700.ms)
            .slideY(begin: 0.1, end: 0)
            .then()
            .shimmer(color: const Color(0xFF69F0AE), duration: 1000.ms),
        SizedBox(height: spacing),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _submitTravelInfo(fontScale, subtitleFontSize, padding),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              padding: EdgeInsets.symmetric(vertical: screenWidth * 0.05),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.04)),
              elevation: 0,
            ),
            child: Container(
              height: screenWidth * 0.12,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFF00E676), const Color(0xFF00C853)],
                ),
                borderRadius: BorderRadius.circular(screenWidth * 0.04),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E676).withOpacity(0.5),
                    blurRadius: screenWidth * 0.075,
                    offset: Offset(0, 0),
                  ),
                  BoxShadow(
                    color: const Color(0xFF00C853).withOpacity(0.8),
                    blurRadius: screenWidth * 0.0125,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Text(
                  'Plan My Adventure',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: subtitleFontSize * 1.1,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF000000),
                  ),
                ),
              ),
            ),
          ).animate(controller: _mainController)
              .fadeIn(delay: 700.ms, duration: 700.ms)
              .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1))
              .then()
              .shimmer(color: const Color(0xFF69F0AE), duration: 1200.ms),
        ),
        SizedBox(height: spacing * 2),
      ],
    );
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onTap,
    required double fontScale,
    required double subtitleFontSize,
    required double padding,
  }) {
    return StatefulBuilder(
      builder: (context, setState) {
        bool isFocused = false;
        
        return Focus(
          onFocusChange: (hasFocus) {
            setState(() {
              isFocused = hasFocus;
            });
            if (hasFocus) {
              HapticFeedback.selectionClick();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isFocused 
                  ? [const Color(0xFF00E676).withOpacity(0.1), const Color(0xFF69F0AE).withOpacity(0.05)]
                  : [Colors.white.withOpacity(0.05), Colors.white.withOpacity(0.02)],
              ),
              borderRadius: BorderRadius.circular(padding * 2),
              border: Border.all(
                color: isFocused 
                  ? const Color(0xFF00E676).withOpacity(0.5)
                  : Colors.white.withOpacity(0.1),
                width: isFocused ? 2 : 1,
              ),
              boxShadow: isFocused ? [
                BoxShadow(
                  color: const Color(0xFF00E676).withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ] : [],
            ),
            child: TextField(
              controller: controller,
              style: TextStyle(
                fontFamily: 'Poppins',
                color: const Color(0xFFFFFFFF),
                fontWeight: FontWeight.w500,
                fontSize: subtitleFontSize,
              ),
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(
                  fontFamily: 'Poppins',
                  color: isFocused 
                    ? const Color(0xFF00E676)
                    : Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.w500,
                  fontSize: subtitleFontSize * 0.9,
                ),
                hintText: hint,
                hintStyle: TextStyle(
                  fontFamily: 'Poppins',
                  color: const Color(0xFFE0E0E0).withOpacity(0.5),
                  fontSize: subtitleFontSize * 0.9,
                ),
                prefixIcon: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  child: Icon(
                    icon, 
                    color: isFocused 
                      ? const Color(0xFF00E676)
                      : const Color(0xFF69F0AE), 
                    size: 20.0 * fontScale
                  ),
                ),
                filled: false,
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: padding, horizontal: padding),
              ),
              keyboardType: keyboardType,
              onTap: onTap,
            ),
          ),
        );
      },
    ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.98, 0.98), end: const Offset(1, 1));
  }

  Widget _buildDropdownField(
      String label,
      String currentValue,
      List<String> options,
      Function(String) onChanged,
      IconData icon, {
        required double fontScale,
        required double subtitleFontSize,
        required double iconSize,
        required double padding,
      }) {
    return DropdownButtonFormField<String>(
      value: currentValue,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          fontFamily: 'Poppins',
          color: Colors.white.withOpacity(0.7),
          fontWeight: FontWeight.w500,
          fontSize: subtitleFontSize * 0.9,
        ),
        prefixIcon: Icon(icon, color: Color(0xFF69F0AE), size: iconSize),
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(padding * 2),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(padding * 2),
          borderSide: const BorderSide(color: Color(0xFF00E676), width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: padding, vertical: padding),
      ),
      items: options.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            value,
            style: TextStyle(
              fontFamily: 'Poppins',
              color: Color(0xFFFFFFFF),
              fontWeight: FontWeight.w500,
              fontSize: subtitleFontSize,
            ),
          ),
        );
      }).toList(),
      onChanged: (String? newValue) {
        if (newValue != null) {
          onChanged(newValue);
        }
      },
      dropdownColor: const Color(0xFF1E1E1E),
      style: TextStyle(
        fontFamily: 'Poppins',
        color: Color(0xFFFFFFFF),
        fontSize: subtitleFontSize,
      ),
    ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.98, 0.98), end: const Offset(1, 1));
  }

  Widget _buildSliderField(
      String label,
      String value,
      double min,
      double max,
      double currentValue,
      Function(double) onChanged,
      IconData icon, {
        required double fontScale,
        required double subtitleFontSize,
        required double iconSize,
      }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: Color(0xFF00E676), size: iconSize),
            SizedBox(width: 8.0 * fontScale),
            Text(
              'Duration',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: subtitleFontSize,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFFFFFF),
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: subtitleFontSize,
                fontWeight: FontWeight.w600,
                color: Color(0xFF00E676),
              ),
            ),
          ],
        ),
        SizedBox(height: 8.0 * fontScale),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF00E676),
            inactiveTrackColor: const Color(0xFF00E676).withOpacity(0.2),
            thumbColor: const Color(0xFF69F0AE),
            overlayColor: const Color(0xFF69F0AE).withOpacity(0.3),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
            trackHeight: 4,
          ),
          child: Slider(
            value: currentValue,
            min: min,
            max: max,
            divisions: (max - min).round(),
            onChanged: onChanged,
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }

  Future<void> _selectDateRange(BuildContext context, double fontScale, double subtitleFontSize, double padding) async {
    final screenWidth = MediaQuery.of(context).size.width;

    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 2),
      initialDateRange: DateTimeRange(
        start: DateTime.now(),
        end: DateTime.now().add(const Duration(days: 7)),
      ),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF00E676),
              onPrimary: Color(0xFF000000),
              surface: Color(0xFF000000),
              onSurface: Color(0xFFFFFFFF),
              secondary: Color(0xFF69F0AE),
              onSecondary: Color(0xFF000000),
              background: Color(0xFF000000),
              onBackground: Color(0xFFFFFFFF),
              outline: Color(0xFF00E676),
            ),
            dialogBackgroundColor: const Color(0xFF000000),
            canvasColor: const Color(0xFF000000),
            scaffoldBackgroundColor: const Color(0xFF000000),
            cardTheme: const CardTheme(
              color: Color(0xFF000000),
              elevation: 0,
              margin: EdgeInsets.zero,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF69F0AE),
                textStyle: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: subtitleFontSize * 0.9,
                ),
              ),
            ),
            elevatedButtonTheme: ElevatedButtonThemeData(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00E676),
                foregroundColor: const Color(0xFF000000),
                textStyle: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: subtitleFontSize * 0.9,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12 * fontScale),
                ),
                elevation: 0,
              ),
            ),
            textTheme: TextTheme(
              headlineSmall: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20.0 * fontScale,
                fontWeight: FontWeight.w700,
                color: Color(0xFF000000),
                shadows: [
                  Shadow(
                    color: Color(0xFF00E676),
                    blurRadius: 5,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
              titleMedium: TextStyle(
                fontFamily: 'Poppins',
                fontSize: subtitleFontSize,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFFFFFF),
              ),
              bodyMedium: TextStyle(
                fontFamily: 'Poppins',
                fontSize: subtitleFontSize * 0.9,
                fontWeight: FontWeight.w500,
                color: Color(0xFFFFFFFF),
              ),
              bodySmall: TextStyle(
                fontFamily: 'Poppins',
                fontSize: subtitleFontSize * 0.8,
                fontWeight: FontWeight.w400,
                color: Color(0xFFE0E0E0),
              ),
              labelLarge: TextStyle(
                fontFamily: 'Poppins',
                fontSize: subtitleFontSize * 0.9,
                fontWeight: FontWeight.w600,
                color: Color(0xFFFFFFFF),
              ),
            ),
            dialogTheme: DialogTheme(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20 * fontScale),
              ),
              backgroundColor: const Color(0xFF000000),
              surfaceTintColor: Colors.transparent,
              elevation: 15,
              shadowColor: const Color(0xFF00E676).withOpacity(0.3),
            ),
            dataTableTheme: const DataTableThemeData(
              decoration: BoxDecoration(
                color: Color(0xFF000000),
              ),
            ),
            dividerTheme: DividerThemeData(
              color: const Color(0xFF00E676).withOpacity(0.3),
              thickness: 1,
            ),
            iconTheme: IconThemeData(
              color: const Color(0xFF69F0AE),
              size: 24.0 * fontScale,
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: const Color(0xFF1E1E1E),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12 * fontScale),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12 * fontScale),
                borderSide: const BorderSide(color: Color(0xFF00E676), width: 2),
              ),
              labelStyle: TextStyle(
                fontFamily: 'Poppins',
                color: Color(0xFFE0E0E0),
                fontWeight: FontWeight.w500,
                fontSize: subtitleFontSize * 0.9,
              ),
              hintStyle: TextStyle(
                fontFamily: 'Poppins',
                color: Color(0xFFE0E0E0),
                fontSize: subtitleFontSize * 0.9,
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 12 * fontScale, horizontal: 16 * fontScale),
            ),
          ),
          child: Container(
            width: screenWidth * 0.9,
            decoration: BoxDecoration(
              color: const Color(0xFF000000),
              borderRadius: BorderRadius.circular(20 * fontScale),
              border: Border.all(
                color: const Color(0xFF00E676).withOpacity(0.3),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E676).withOpacity(0.2),
                  blurRadius: 20 * fontScale,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: child!,
          ).animate()
              .fadeIn(duration: 500.ms)
              .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1))
              .then()
              .shimmer(color: const Color(0xFF69F0AE), duration: 1000.ms),
        );
      },
    );

    if (picked != null) {
      final formatter = DateFormat('MMM dd, yyyy');
      _travelDatesController.text =
      '${formatter.format(picked.start)} - ${formatter.format(picked.end)}';
      final days = picked.end.difference(picked.start).inDays + 1;
      _travelInfoController.updateTravelInfo(duration: days);
    }
  }

  void _submitTravelInfo(double fontScale, double subtitleFontSize, double padding) {
    final screenWidth = MediaQuery.of(context).size.width;

    // Validate inputs
    if (_sourceController.text.isEmpty) {
      Get.snackbar(
        'Missing Info',
        'Please enter your starting city',
        backgroundColor: const Color(0xFF69F0AE),
        colorText: Color(0xFFFFFFFF),
        snackPosition: SnackPosition.TOP,
        icon: const Icon(Icons.error, color: Color(0xFFFFFFFF)),
        duration: const Duration(seconds: 3),
        borderRadius: 12 * fontScale,
        margin: EdgeInsets.all(screenWidth * 0.04),
        boxShadows: [
          BoxShadow(
            color: const Color(0xFF69F0AE).withOpacity(0.3),
            blurRadius: 6 * fontScale,
            offset: const Offset(0, 2),
          ),
        ],
        titleText: Text(
          'Missing Info',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: subtitleFontSize,
            fontWeight: FontWeight.w600,
            color: Color(0xFFFFFFFF),
          ),
        ),
        messageText: Text(
          'Please enter your starting city',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: subtitleFontSize * 0.9,
            color: Color(0xFFFFFFFF),
          ),
        ),
      );
      return;
    }

    if (_destinationController.text.isEmpty) {
      Get.snackbar(
        'Missing Info',
        'Please enter your destination city',
        backgroundColor: const Color(0xFF69F0AE),
        colorText: Color(0xFFFFFFFF),
        snackPosition: SnackPosition.TOP,
        icon: const Icon(Icons.error, color: Color(0xFFFFFFFF)),
        duration: const Duration(seconds: 3),
        borderRadius: 12 * fontScale,
        margin: EdgeInsets.all(screenWidth * 0.04),
        boxShadows: [
          BoxShadow(
            color: const Color(0xFF69F0AE).withOpacity(0.3),
            blurRadius: 6 * fontScale,
            offset: const Offset(0, 2),
          ),
        ],
        titleText: Text(
          'Missing Info',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: subtitleFontSize,
            fontWeight: FontWeight.w600,
            color: Color(0xFFFFFFFF),
          ),
        ),
        messageText: Text(
          'Please enter your destination city',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: subtitleFontSize * 0.9,
            color: Color(0xFFFFFFFF),
          ),
        ),
      );
      return;
    }

    if (_travelDatesController.text.isEmpty) {
      Get.snackbar(
        'Missing Info',
        'Please select your travel dates',
        backgroundColor: const Color(0xFF69F0AE),
        colorText: Color(0xFFFFFFFF),
        snackPosition: SnackPosition.TOP,
        icon: const Icon(Icons.error, color: Color(0xFFFFFFFF)),
        duration: const Duration(seconds: 3),
        borderRadius: 12 * fontScale,
        margin: EdgeInsets.all(screenWidth * 0.04),
        boxShadows: [
          BoxShadow(
            color: const Color(0xFF69F0AE).withOpacity(0.3),
            blurRadius: 6 * fontScale,
            offset: const Offset(0, 2),
          ),
        ],
        titleText: Text(
          'Missing Info',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: subtitleFontSize,
            fontWeight: FontWeight.w600,
            color: Color(0xFFFFFFFF),
          ),
        ),
        messageText: Text(
          'Please select your travel dates',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: subtitleFontSize * 0.9,
            color: Color(0xFFFFFFFF),
          ),
        ),
      );
      return;
    }

    if (_adultsController.text.isEmpty || int.tryParse(_adultsController.text)! < 1) {
      Get.snackbar(
        'Missing Info',
        'Please enter at least one adult',
        backgroundColor: const Color(0xFF69F0AE),
        colorText: Color(0xFFFFFFFF),
        snackPosition: SnackPosition.TOP,
        icon: const Icon(Icons.error, color: Color(0xFFFFFFFF)),
        duration: const Duration(seconds: 3),
        borderRadius: 12 * fontScale,
        margin: EdgeInsets.all(screenWidth * 0.04),
        boxShadows: [
          BoxShadow(
            color: const Color(0xFF69F0AE).withOpacity(0.3),
            blurRadius: 6 * fontScale,
            offset: const Offset(0, 2),
          ),
        ],
        titleText: Text(
          'Missing Info',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: subtitleFontSize,
            fontWeight: FontWeight.w600,
            color: Color(0xFFFFFFFF),
          ),
        ),
        messageText: Text(
          'Please enter at least one adult',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: subtitleFontSize * 0.9,
            color: Color(0xFFFFFFFF),
          ),
        ),
      );
      return;
    }

    // Parse travelDates to extract start_date in YYYY-MM-DD format
    String startDate;
    try {
      final dateParts = _travelDatesController.text.split(' - ');
      if (dateParts.length != 2) throw FormatException('Invalid date range format');
      final inputFormatter = DateFormat('MMM dd, yyyy');
      final outputFormatter = DateFormat('yyyy-MM-dd');
      final start = inputFormatter.parse(dateParts[0]);
      startDate = outputFormatter.format(start);
    } catch (e) {
      Get.snackbar(
        'Invalid Date Format',
        'Please select valid travel dates',
        backgroundColor: const Color(0xFF69F0AE),
        colorText: Color(0xFFFFFFFF),
        snackPosition: SnackPosition.TOP,
        icon: const Icon(Icons.error, color: Color(0xFFFFFFFF)),
        duration: const Duration(seconds: 3),
        borderRadius: 12 * fontScale,
        margin: EdgeInsets.all(screenWidth * 0.04),
        boxShadows: [
          BoxShadow(
            color: const Color(0xFF69F0AE).withOpacity(0.3),
            blurRadius: 6 * fontScale,
            offset: const Offset(0, 2),
          ),
        ],
        titleText: Text(
          'Invalid Date Format',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: subtitleFontSize,
            fontWeight: FontWeight.w600,
            color: Color(0xFFFFFFFF),
          ),
        ),
        messageText: Text(
          'Please select valid travel dates',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: subtitleFontSize * 0.9,
            color: Color(0xFFFFFFFF),
          ),
        ),
      );
      return;
    }

    // Update travelDates in controller to use start_date
    _travelInfoController.updateTravelInfo(travelDates: startDate);

    // Get JSON data from controller
    final travelInfoJson = _travelInfoController.toJson();

    // Print JSON data for debugging
    print('Travel Info Submitted (JSON):');
    print(travelInfoJson);

    // Show loading dialog
    Get.dialog(
      Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00E676)),
        ),
      ),
      barrierDismissible: false,
    );

    // Show success snackbar after a short delay to ensure it's visible on TravelDetailsScreen
    Future.delayed(const Duration(seconds: 2), () {

      Get.snackbar(
        'Trip Planned!',
        'Your adventure is ready to go!',
        backgroundColor: const Color(0xFF00E676),
        colorText: const Color(0xFF000000),
        snackPosition: SnackPosition.TOP,
        icon: const Icon(Icons.check_circle, color: Color(0xFF000000)),
        duration: const Duration(seconds: 3),
        borderRadius: 12 * fontScale,
        margin: EdgeInsets.all(screenWidth * 0.04),
        boxShadows: [
          BoxShadow(
            color: const Color(0xFF69F0AE).withOpacity(0.3),
            blurRadius: 6 * fontScale,
            offset: const Offset(0, 2),
          ),
        ],
        titleText: Text(
          'Trip Planned!',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: subtitleFontSize,
            fontWeight: FontWeight.w600,
            color: Color(0xFF000000),
          ),
        ),
        messageText: Text(
          'Your adventure is ready to go!',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: subtitleFontSize * 0.9,
            color: Color(0xFF000000),
          ),
        ),
      );
    });

    // Navigate to TravelDetailsScreen immediately
    Get.to(() => TravelDetailsScreen(travelInfo: travelInfoJson));
  }

  void _showTravelTips(BuildContext context, double fontScale, double subtitleFontSize, double padding, double iconSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          height: screenHeight * 0.75,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xFF1E1E1E), const Color(0xFF1E1E1E).withOpacity(0.9)],
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(padding * 2),
              topRight: Radius.circular(padding * 2),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF69F0AE).withOpacity(0.2),
                blurRadius: 8 * fontScale,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Column(
            children: [
              Center(
                child: Padding(
                  padding: EdgeInsets.only(top: padding),
                  child: Container(
                    height: 4,
                    width: 40 * fontScale,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10 * fontScale),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(padding),
                child: Text(
                  'Travel Tips',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22.0 * fontScale,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFFFFFFF),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  children: [
                    _buildTipItem(
                      'Plan Smart',
                      'Book early for the best deals and availability.',
                      Icons.schedule,
                      const Color(0xFF00E676),
                      fontScale: fontScale,
                      subtitleFontSize: subtitleFontSize,
                      padding: padding,
                      iconSize: iconSize,
                    ),
                    _buildTipItem(
                      'Budget Like a Pro',
                      'Set aside 20% extra for unexpected adventures.',
                      Icons.account_balance_wallet,
                      const Color(0xFF69F0AE),
                      fontScale: fontScale,
                      subtitleFontSize: subtitleFontSize,
                      padding: padding,
                      iconSize: iconSize,
                    ),
                    _buildTipItem(
                      'Pack Light',
                      'Keep it minimal to travel with ease.',
                      Icons.luggage,
                      const Color(0xFF00E676),
                      fontScale: fontScale,
                      subtitleFontSize: subtitleFontSize,
                      padding: padding,
                      iconSize: iconSize,
                    ),
                    _buildTipItem(
                      'Stay Connected',
                      'Share your itinerary with a friend for safety.',
                      Icons.contact_phone,
                      const Color(0xFF69F0AE),
                      fontScale: fontScale,
                      subtitleFontSize: subtitleFontSize,
                      padding: padding,
                      iconSize: iconSize,
                    ),
                  ].animate(interval: 150.ms)
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.1, end: 0)
                      .then()
                      .shimmer(color: const Color(0xFF69F0AE), duration: 1000.ms),
                ),
              ),
            ],
          ),
        ).animate()
            .slideY(begin: 1, end: 0, duration: 700.ms, curve: Curves.easeOutQuint)
            .then()
            .shimmer(color: const Color(0xFF00E676), duration: 1000.ms),
      ),
    );
  }

  Widget _buildTipItem(
      String title,
      String description,
      IconData icon,
      Color color, {
        required double fontScale,
        required double subtitleFontSize,
        required double padding,
        required double iconSize,
      }) {
    return Padding(
      padding: EdgeInsets.only(bottom: padding),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Colors.white.withOpacity(0.05), const Color(0xFF1E1E1E).withOpacity(0.05)],
          ),
          borderRadius: BorderRadius.circular(padding * 1.5),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 6 * fontScale,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(padding),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(padding / 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
                  ),
                  borderRadius: BorderRadius.circular(padding),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: iconSize,
                ),
              ),
              SizedBox(width: padding),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: subtitleFontSize,
                        color: Color(0xFFFFFFFF),
                      ),
                    ),
                    SizedBox(height: padding / 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white.withOpacity(0.7),
                        fontSize: subtitleFontSize * 0.9,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showQuickActions(BuildContext context, double padding, double subtitleFontSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          height: screenHeight * 0.6,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [const Color(0xFF1E1E1E), const Color(0xFF1E1E1E).withOpacity(0.9)],
            ),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(padding * 2),
              topRight: Radius.circular(padding * 2),
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF69F0AE).withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, -1),
              ),
            ],
          ),
          child: Column(
            children: [
              Center(
                child: Padding(
                  padding: EdgeInsets.only(top: padding),
                  child: Container(
                    height: 4,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(padding),
                child: Text(
                  'Quick Actions',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 22.0,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFFFFFF),
                  ),
                ),
              ),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 2,
                  padding: EdgeInsets.all(padding),
                  mainAxisSpacing: padding,
                  crossAxisSpacing: padding,
                  children: [
                    _buildQuickActionCard(
                      'Popular Routes',
                      Icons.trending_up,
                      const Color(0xFF2196F3),
                      () {
                        HapticFeedback.lightImpact();
                        Get.back();
                        // Navigate to popular routes
                      },
                      padding: padding,
                      subtitleFontSize: subtitleFontSize,
                    ),
                    _buildQuickActionCard(
                      'Last Search',
                      Icons.history,
                      const Color(0xFFFF9800),
                      () {
                        HapticFeedback.lightImpact();
                        Get.back();
                        // Load last search
                      },
                      padding: padding,
                      subtitleFontSize: subtitleFontSize,
                    ),
                    _buildQuickActionCard(
                      'Nearby Stations',
                      Icons.location_on,
                      const Color(0xFFE91E63),
                      () {
                        HapticFeedback.lightImpact();
                        Get.back();
                        // Show nearby stations
                      },
                      padding: padding,
                      subtitleFontSize: subtitleFontSize,
                    ),
                    _buildQuickActionCard(
                      'Emergency',
                      Icons.emergency,
                      const Color(0xFFF44336),
                      () {
                        HapticFeedback.lightImpact();
                        Get.back();
                        // Emergency booking
                      },
                      padding: padding,
                      subtitleFontSize: subtitleFontSize,
                    ),
                  ].animate(interval: 100.ms)
                      .fadeIn(duration: 500.ms)
                      .slideY(begin: 0.1, end: 0)
                      .then()
                      .shimmer(color: const Color(0xFF69F0AE), duration: 1000.ms),
                ),
              ),
            ],
          ),
        ).animate()
            .slideY(begin: 1, end: 0, duration: 700.ms, curve: Curves.easeOutQuint)
            .then()
            .shimmer(color: const Color(0xFF00E676), duration: 1000.ms),
      ),
    );
  }

  Widget _buildQuickActionCard(
      String title,
      IconData icon,
      Color color,
      VoidCallback onTap, {
        required double padding,
        required double subtitleFontSize,
      }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(padding * 1.5),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color.withOpacity(0.1), color.withOpacity(0.05)],
            ),
            borderRadius: BorderRadius.circular(padding * 1.5),
            border: Border.all(
              color: color.withOpacity(0.3),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(padding),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [color.withOpacity(0.2), color.withOpacity(0.1)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              SizedBox(height: padding),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w600,
                  fontSize: subtitleFontSize * 0.9,
                  color: const Color(0xFFFFFFFF),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
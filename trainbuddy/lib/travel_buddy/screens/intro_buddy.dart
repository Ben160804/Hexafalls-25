import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'package:trainbuddy/travel_buddy/screens/travel-info.dart';

class IntroBuddyScreen extends StatefulWidget {
  const IntroBuddyScreen({super.key});

  @override
  State<IntroBuddyScreen> createState() => _IntroBuddyScreenState();
}

class _IntroBuddyScreenState extends State<IntroBuddyScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final ValueNotifier<double> _scrollProgress = ValueNotifier(0.0);
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
    });

    _scrollController.addListener(() {
      if (_scrollController.position.hasContentDimensions) {
        final progress = _scrollController.offset / 150;
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
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth >= 600;
    final padding = screenWidth * 0.05; // 5% of screen width
    final fontScale = isTablet ? 1.2 : 1.0;
    final iconSize = isTablet ? 28.0 : 22.0;
    final titleFontSize = 22.0 * fontScale;
    final subtitleFontSize = 16.0 * fontScale;
    final sectionTitleFontSize = 18.0 * fontScale;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Row(
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
              ),
              child: Icon(
                Icons.flight_takeoff,
                color: const Color(0xFF00E676),
                size: iconSize + 4,
              ),
            ).animate(controller: _controller)
                .fadeIn(duration: 500.ms)
                .then()
                .shimmer(color: const Color(0xFF69F0AE), duration: 1000.ms),
            SizedBox(width: padding / 2),
            Flexible(
              child: Text(
                'Journease',
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
              ).animate(controller: _controller)
                  .fadeIn(duration: 600.ms)
                  .slideX(begin: -0.2, end: 0),
            ),
          ],
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF000000).withOpacity(0.9),
                const Color(0xFF1E1E1E).withOpacity(0.7),
              ],
            ),
          ),
        ),
      ),
      body: Stack(
        children: [
          ValueListenableBuilder<double>(
            valueListenable: _scrollProgress,
            builder: (context, value, child) {
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
                      Positioned(
                        top: -60 + (value * 30),
                        left: -screenWidth * 0.3,
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
                      Positioned(
                        bottom: -100 + (value * 40),
                        right: -screenWidth * 0.35,
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
                      Positioned(
                        top: 100 - (value * 20),
                        right: screenWidth * 0.05,
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
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: EdgeInsets.only(left: padding, top: padding / 2, right: padding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your AI Travel',
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
                      ).animate(controller: _controller)
                          .fadeIn(duration: 700.ms)
                          .slideY(begin: 0.2, end: 0),
                      Text(
                        'Companion',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 32.0 * fontScale,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF00E676),
                          letterSpacing: -0.5,
                          shadows: [
                            Shadow(
                              color: const Color(0xFF00E676).withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                      ).animate(controller: _controller)
                          .fadeIn(duration: 700.ms, delay: 200.ms)
                          .slideY(begin: 0.2, end: 0),
                      SizedBox(height: padding / 2),
                      Text(
                        'Plan your perfect journey with AI-powered assistance',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: subtitleFontSize,
                          color: const Color(0xFFE0E0E0),
                          fontWeight: FontWeight.w400,
                        ),
                      ).animate(controller: _controller)
                          .fadeIn(duration: 700.ms, delay: 400.ms)
                          .slideY(begin: 0.2, end: 0),
                    ],
                  ),
                ),
                SizedBox(height: padding * 1.5),
                Expanded(
                  child: SingleChildScrollView(
                    controller: _scrollController,
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding),
                    child: _buildIntroContent(screenWidth, fontScale, sectionTitleFontSize, subtitleFontSize, iconSize, padding),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIntroContent(double screenWidth, double fontScale, double sectionTitleFontSize, double subtitleFontSize, double iconSize, double padding) {
    final spacing = screenWidth * 0.08;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionCard(
          'Welcome to Journease',
          Icons.flight_takeoff,
          [
            _buildInfoItem(
              'Smart Travel Planning',
              'Get personalized travel recommendations, real-time updates, and intelligent assistance for your journey.',
              Icons.psychology,
              const Color(0xFF00E676),
              fontScale: fontScale,
              subtitleFontSize: subtitleFontSize,
              iconSize: iconSize,
              padding: screenWidth * 0.035,
            ),
          ],
          fontScale: fontScale,
          sectionTitleFontSize: sectionTitleFontSize,
          subtitleFontSize: subtitleFontSize,
          iconSize: iconSize,
          padding: screenWidth * 0.05,
        ).animate(controller: _controller)
            .fadeIn(delay: 400.ms, duration: 700.ms)
            .slideY(begin: 0.1, end: 0)
            .then()
            .shimmer(color: const Color(0xFF69F0AE), duration: 1000.ms),
        SizedBox(height: spacing),
        _buildSectionCard(
          'What We Offer',
          Icons.star,
          [

            _buildInfoItem(
              'Hotel Recommendations',
              'Get personalized accommodation suggestions based on your preferences and budget.',
              Icons.hotel,
              const Color(0xFFFF9800),
              fontScale: fontScale,
              subtitleFontSize: subtitleFontSize,
              iconSize: iconSize,
              padding: screenWidth * 0.035,
            ),
            SizedBox(height: spacing / 2),
            _buildInfoItem(
              'Itinerary Planning',
              'Create detailed day-by-day travel plans with AI-powered optimization.',
              Icons.schedule,
              const Color(0xFFE91E63),
              fontScale: fontScale,
              subtitleFontSize: subtitleFontSize,
              iconSize: iconSize,
              padding: screenWidth * 0.035,
            ),
            SizedBox(height: spacing / 2),
            _buildInfoItem(
              'AI Assistant',
              '24/7 intelligent travel support with real-time updates and emergency assistance.',
              Icons.smart_toy_rounded,
              const Color(0xFF00E676),
              fontScale: fontScale,
              subtitleFontSize: subtitleFontSize,
              iconSize: iconSize,
              padding: screenWidth * 0.035,
            ),
          ],
          fontScale: fontScale,
          sectionTitleFontSize: sectionTitleFontSize,
          subtitleFontSize: subtitleFontSize,
          iconSize: iconSize,
          padding: screenWidth * 0.05,
        ).animate(controller: _controller)
            .fadeIn(delay: 500.ms, duration: 700.ms)
            .slideY(begin: 0.1, end: 0)
            .then()
            .shimmer(color: const Color(0xFF69F0AE), duration: 1000.ms),
        SizedBox(height: spacing),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => Get.offAll(() => const TravelInfoScreen()),
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
                    offset: const Offset(0, 0),
                  ),
                  BoxShadow(
                    color: const Color(0xFF00C853).withOpacity(0.8),
                    blurRadius: screenWidth * 0.0125,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.rocket_launch,
                      color: const Color(0xFF000000),
                      size: subtitleFontSize * 1.2,
                    ),
                    SizedBox(width: padding / 2),
                    Text(
                      'Get Started',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: subtitleFontSize * 1.1,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF000000),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate(controller: _controller)
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
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF2C2F33), const Color(0xFF1E1E1E)],
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
    );
  }

  Widget _buildInfoItem(
      String title,
      String description,
      IconData icon,
      Color color, {
        required double fontScale,
        required double subtitleFontSize,
        required double iconSize,
        required double padding,
      }) {
    return Row(
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
                  fontSize: subtitleFontSize,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFFFFFFF),
                ),
              ),
              SizedBox(height: padding / 4),
              Text(
                description,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: subtitleFontSize * 0.85,
                  color: const Color(0xFFE0E0E0),
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.1, end: 0);
  }
}

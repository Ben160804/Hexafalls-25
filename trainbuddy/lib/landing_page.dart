import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:trainbuddy/train_buddy/screens/dashboard.dart';


class LandingScreen extends StatefulWidget {
  const LandingScreen({super.key});

  @override
  State<LandingScreen> createState() => _LandingScreenState();
}

class _LandingScreenState extends State<LandingScreen> with SingleTickerProviderStateMixin {
  bool isHoveringLeft = false;
  bool isHoveringRight = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final textScaleFactor = size.width / 1440; // Base width for scaling

    return Scaffold(
      body: Row(
        children: [
          // Left rectangle (What We Do)
          Expanded(
            child: buildRectangleSection(
              context: context,
              isHovering: isHoveringLeft,
              onHoverEnter: () => setState(() {
                isHoveringLeft = true;
                _controller.forward();
              }),
              onHoverExit: () => setState(() {
                isHoveringLeft = false;
                _controller.reverse();
              }),
              onTap: () => Get.toNamed('/'),
              title: 'TRAIN BUDDY',
              description: 'Plan your train journeys with ease using our smart tools and services.',
              textColor: Colors.white,
              overlayColor: Colors.black.withOpacity(0.6),
              imagePath: 'assets/images/train.png',
              textScaleFactor: textScaleFactor,
              scaleAnimation: _scaleAnimation,
            ),
          ),
          // Right rectangle (Latest Work)
          Expanded(
            child: buildRectangleSection(
              context: context,
              isHovering: isHoveringRight,
              onHoverEnter: () => setState(() {
                isHoveringRight = true;
                _controller.forward();
              }),
              onHoverExit: () => setState(() {
                isHoveringRight = false;
                _controller.reverse();
              }),
              onTap: () => Get.toNamed('/travelinfo'),
              title: 'TRAVEL BUDDY',
              description: 'Check out our latest features and updates for seamless travel planning.',
              textColor: Colors.black87,
              overlayColor: Colors.white.withOpacity(0.4),
              imagePath: 'assets/images/travel.png',
              textScaleFactor: textScaleFactor,
              scaleAnimation: _scaleAnimation,
            ),
          ),
        ],
      ),
    );
  }

  Widget buildRectangleSection({
    required BuildContext context,
    required bool isHovering,
    required VoidCallback onHoverEnter,
    required VoidCallback onHoverExit,
    required VoidCallback onTap,
    required String title,
    required String description,
    required Color textColor,
    required Color overlayColor,
    required String imagePath,
    required double textScaleFactor,
    required Animation<double> scaleAnimation,
  }) {
    return MouseRegion(
      onEnter: (_) => onHoverEnter(),
      onExit: (_) => onHoverExit(),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Transform.scale(
              scale: isHovering ? scaleAnimation.value : 1.0,
              child: Container(
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(imagePath),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      overlayColor,
                      BlendMode.srcOver,
                    ),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isHovering ? 0.3 : 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                padding: EdgeInsets.symmetric(
                  horizontal: 30 * textScaleFactor,
                  vertical: 20 * textScaleFactor,
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 48 * textScaleFactor,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              color: textColor.withOpacity(0.3),
                              offset: const Offset(2, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 16 * textScaleFactor),
                      Text(
                        description,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 32 * textScaleFactor,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}


import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:trainbuddy/chatbot/screens/chat_screen.dart';
import 'dart:ui';
import '../controllers/train_finder_controller.dart';
import '../models/station.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final ValueNotifier<double> _scrollProgress = ValueNotifier(0.0);
  final ScrollController _scrollController = ScrollController();
  final TrainFinderController _trainFinderController = Get.put(TrainFinderController());

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Animate in elements when screen loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.forward();
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
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        title: Row(
          children: [
            // Animated logo
            Icon(
              Icons.train_rounded,
              color: Colors.white,
              size: 28,
            ).animate(controller: _controller)
                .slide(begin: const Offset(-1, 0), end: Offset.zero, curve: Curves.easeOutQuint)
                .then()
                .shimmer(delay: 400.ms, duration: 1800.ms),
            const SizedBox(width: 8),
            const Text(
              'TrainBuddy',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
                color: Colors.white,
              ),
            ).animate(controller: _controller)
                .fadeIn(duration: 600.ms, curve: Curves.easeOutQuint)
                .slideX(begin: -0.2, end: 0, curve: Curves.easeOutQuint),
          ],
        ),
        actions: [
          // Notification bell with badge
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.only(right: 16.0,bottom: 8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: FloatingActionButton(onPressed: (){
                    Get.to(ChatScreen());
                  },
                    child: Icon(Icons.smart_toy_rounded,
                      color: Colors.white,
                      size: 24,),
                    backgroundColor: Color(0xFFF86A3C) ,
                  ),
                ).animate(controller: _controller)
                    .fadeIn(delay: 200.ms, duration: 400.ms)
                    .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 16.0),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                        onPressed: () {
                          _showAnimatedModal(context);
                        },
                      ),
                    ).animate(controller: _controller)
                        .fadeIn(delay: 200.ms, duration: 400.ms)
                        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        width: 10,
                        height: 10,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF5252),
                          shape: BoxShape.circle,
                        ),
                      ).animate(controller: _controller)
                          .fadeIn(delay: 600.ms)
                          .scale(begin: const Offset(0, 0), end: const Offset(1, 1), curve: Curves.elasticOut),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
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
          // Animated background elements
          ValueListenableBuilder<double>(
            valueListenable: _scrollProgress,
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
          ),

          // Bottom curved container
          Positioned(
            top: 180,
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome message and train search form
                Padding(
                  padding: const EdgeInsets.only(left: 24.0, top: 8.0, right: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome to TrainBuddy',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                          fontWeight: FontWeight.w500,
                        ),
                      ).animate(controller: _controller)
                          .fadeIn(duration: 600.ms)
                          .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuint),
                      const SizedBox(height: 4),
                      Text(
                        'Your Journey, Simplified',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ).animate(controller: _controller)
                          .fadeIn(delay: 200.ms, duration: 600.ms)
                          .slideY(begin: 0.2, end: 0, curve: Curves.easeOutQuint),
                      const SizedBox(height: 16),
                      _buildTrainSearchForm(),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Services heading
                Padding(
                  padding: const EdgeInsets.only(left: 24.0, right: 24.0),
                  child: Text(
                    'Services',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1F2937),
                    ),
                  ).animate(controller: _controller)
                      .fadeIn(delay: 300.ms, duration: 600.ms)
                      .slideY(begin: 0.2, end: 0),
                ),

                const SizedBox(height: 16),

                // Dashboard grid with interactive tiles
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20.0),
                    child: NotificationListener<ScrollNotification>(
                      onNotification: (notification) {
                        if (notification is ScrollUpdateNotification) {
                          final progress = _scrollController.offset / 100;
                          _scrollProgress.value = progress.clamp(0.0, 1.0);
                        }
                        return false;
                      },
                      child: _buildGridView(),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrainSearchForm() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              _buildStationInputField(
                nameController: _trainFinderController.sourceNameController,
                codeController: _trainFinderController.sourceCodeController,
                label: 'From',
                hint: 'Enter source station',
                icon: Icons.location_on,
                suggestions: _trainFinderController.sourceSuggestions,
                onSuggestionSelected: _trainFinderController.selectSourceStation,
              ),
              const SizedBox(height: 12),
              _buildStationInputField(
                nameController: _trainFinderController.destinationNameController,
                codeController: _trainFinderController.destinationCodeController,
                label: 'To',
                hint: 'Enter destination station',
                icon: Icons.location_on,
                suggestions: _trainFinderController.destinationSuggestions,
                onSuggestionSelected: _trainFinderController.selectDestinationStation,
              ),
              const SizedBox(height: 12),
              _buildInputField(
                controller: _trainFinderController.dateController,
                label: 'Date',
                hint: 'Tap to select date',
                icon: Icons.calendar_today,
                keyboardType: TextInputType.none,
                onTap: () => _selectDate(context),
              ),
              const SizedBox(height: 16),
              Obx(() {
                if (_trainFinderController.errorMessage.value != null) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      _trainFinderController.errorMessage.value!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  );
                }
                return const SizedBox.shrink();
              }),
              SizedBox(
                width: double.infinity,
                child: Obx(() => ElevatedButton(
                  onPressed: _trainFinderController.isLoading.value
                      ? null
                      : _trainFinderController.searchTrains,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: const Color(0xFFF86A3C),
                    disabledBackgroundColor: const Color(0xFFF86A3C),
                    foregroundColor: Colors.white,
                    disabledForegroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    overlayColor:
                      const Color(0xFFF86A3C).withOpacity(0.1),

                  ),
                  child: _trainFinderController.isLoading.value
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          'Search Trains',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStationInputField({
    required TextEditingController nameController,
    required TextEditingController codeController,
    required String label,
    required String hint,
    required IconData icon,
    required RxList<Station> suggestions,
    required Function(Station) onSuggestionSelected,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          style: TextStyle(color: Color(0xFF1F2937)), // Changed to dark gray
          controller: nameController,
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(color: Color(0xFF1F2937)), // Darker label
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey.shade600), // Darker hint
            prefixIcon: Icon(icon, color: Color(0xFF1F2937)), // Darker icon
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.blue.shade300),
            ),
          ),
        ),
        Obx(() {
          if (suggestions.isEmpty) return SizedBox.shrink();
          return Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 10,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Scrollbar(
              thumbVisibility: true,
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: suggestions.length,
                itemBuilder: (context, index) {
                  final station = suggestions[index];
                  return ListTile(
                    title: Text(
                      '${station.name} (${station.code})',
                      style: TextStyle(
                        color: Color(0xFF1F2937), // Dark gray text
                        fontSize: 14,
                      ),
                    ),
                    onTap: () => onSuggestionSelected(station),
                  );
                },
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    VoidCallback? onTap,
  }) {
    return TextField(
      controller: controller,
      style: TextStyle(color: Color(0xFF1F2937)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Color(0xFF1F2937)),
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade600),
        prefixIcon: Icon(icon, color: Color(0xFF1F2937)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Color(0xFFF86A3C)),
        ),
      ),
      keyboardType: keyboardType,
      onTap: onTap, // Add this line to pass the onTap callback
    );
  }

  Widget _buildGridView() {
    final tiles = _buildTiles();

    return GridView.count(
      controller: _scrollController,
      physics: const BouncingScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 16,
      crossAxisSpacing: 16,
      children: List.generate(
        tiles.length,
            (index) => tiles[index].animate(controller: _controller)
            .fadeIn(
          delay: Duration(milliseconds: 300 + (index * 100)),
          duration: const Duration(milliseconds: 600),
        )
            .slideY(begin: 0.2, end: 0)
            .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),
      ),
    );
  }

  // Tile data
  final List<String> titles = [
    'Food Booking',
    'Live Location',
    'Settings',
  ];

  final List<IconData> icons = [
    Icons.restaurant_outlined,
    Icons.location_on_outlined,
    Icons.settings_outlined,
  ];

  final List<Color> colors = [
    const Color(0xFFF86A3C),
    const Color(0xFFF86A3C),
    const Color(0xFFF86A3C),
  ];

  final List<String> descriptions = [
    'Order meals for your journey',
    'Track trains in real-time',
    'Manage your preferences',
  ];

  final List<bool> isComingSoon = [
    false,
    true,
    true
  ];

  final List<VoidCallback?> actions = [
    () => Get.toNamed('/food-booking'),
    null,
    null
  ];

  List<Widget> _buildTiles() {
    List<Widget> tiles = [];

    for (int i = 0; i < titles.length; i++) {
      tiles.add(
        _buildDashboardTile(
          context,
          titles[i],
          icons[i],
          colors[i],
          descriptions[i],
          actions[i],
          isComingSoon[i],
        ),
      );
    }

    return tiles;
  }

  Widget _buildDashboardTile(
    BuildContext context,
    String title,
    IconData icon,
    Color color,
    String description,
    VoidCallback? onTap,
    bool isComingSoon,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 1.0, end: 1.0),
        duration: const Duration(milliseconds: 200),
        builder: (context, value, child) {
          return Transform.scale(
            scale: value,
            child: Container(
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
                    onTap: onTap,
                    splashColor: const Color(0xFFF86A3C).withOpacity(0.1),
                    highlightColor: const Color(0xFFF86A3C).withOpacity(0.05),
                    child: Stack(
                      children: [
                        // Background design element
                        Positioned(
                          right: -20,
                          bottom: -20,
                          child: Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),

                        // Content
                        Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildIconContainer(icon, color),
                              const Spacer(),
                              Text(
                                title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1F2937),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),

                        // Coming Soon badge
                        if (isComingSoon)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Coming Soon',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ).animate()
                .custom(
              duration: 250.ms,
              builder: (context, value, child) => Transform.scale(
                scale: 0.95 + (0.05 * value),
                child: child,
              ),
              curve: Curves.easeInOut,
              begin: 0,
              end: 1,
            ),
          );
        },
      ),
    );
  }

  Widget _buildIconContainer(IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF86A3C).withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(
        icon,
        size: 28,
        color: const Color(0xFFF86A3C),
      ),
    ).animate()
        .shimmer(delay: const Duration(seconds: 2), duration: const Duration(milliseconds: 1800))
        .then()
        .shimmer(delay: const Duration(seconds: 10), duration: const Duration(milliseconds: 1800));
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
    );
    if (picked != null) {
      _trainFinderController.dateController.text = 
          DateFormat('yyyyMMdd').format(picked);
    }
  }

  void _showAnimatedModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Container(
                    height: 5,
                    width: 40,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),

              const Padding(
                padding: EdgeInsets.all(20.0),
                child: Text(
                  "Notifications",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    _buildNotificationItem(
                      "Train Delay Alert",
                      "Your train (12345) has been delayed by 20 minutes.",
                      const Color(0xFFFF5252),
                      Icons.access_time,
                      "10 min ago",
                    ),
                    _buildNotificationItem(
                      "Food Order Confirmed",
                      "Your food order has been confirmed and will be delivered to your seat.",
                      const Color(0xFF4CAF50),
                      Icons.restaurant,
                      "2 hours ago",
                    ),
                    _buildNotificationItem(
                      "Platform Change",
                      "Your train will now depart from Platform 5 instead of Platform 3.",
                      const Color(0xFF2196F3),
                      Icons.transfer_within_a_station,
                      "Yesterday",
                    ),
                  ].animate(interval: 100.ms)
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.1, end: 0),
                ),
              ),
            ],
          ),
        ).animate()
            .slideY(begin: 1, end: 0, duration: 500.ms, curve: Curves.easeOutQuint),
      ),
    );
  }

  Widget _buildNotificationItem(
      String title,
      String message,
      Color color,
      IconData icon,
      String time,
      ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Container(
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
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      message,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      time,
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 12,
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
}
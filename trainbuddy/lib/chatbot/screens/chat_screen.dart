import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:ui';
import 'package:markdown_widget/markdown_widget.dart';
import 'package:trainbuddy/chatbot/controllers/chat_screen_controller.dart';
import 'package:trainbuddy/chatbot/models/message_model.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> with TickerProviderStateMixin {
  final ChatController chatController = Get.put(ChatController());
  late final AnimationController _controller;
  late final AnimationController _typingController;
  final ValueNotifier<double> _scrollProgress = ValueNotifier(0.0);
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  final ValueNotifier<bool> _hasText = ValueNotifier(false);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _typingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
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

    ever(chatController.messages, (_) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients && chatController.messages.isNotEmpty) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    });

    chatController.messageController.addListener(() {
      _hasText.value = chatController.messageController.text.trim().isNotEmpty;
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _typingController.dispose();
    _scrollController.dispose();
    _scrollProgress.dispose();
    _focusNode.dispose();
    _hasText.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    final isTablet = screenWidth >= 600;
    final padding = screenWidth * 0.05;
    final fontScale = isTablet ? 1.2 : 1.0;
    final iconSize = isTablet ? 28.0 : 22.0;
    final titleFontSize = 22.0 * fontScale;
    final subtitleFontSize = 16.0 * fontScale;

    return Scaffold(
      backgroundColor: const Color(0xFF000000),
      resizeToAvoidBottomInset: true,
      extendBodyBehindAppBar: false, // Changed to false to prevent content overlap
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: const Color(0xFF00E676), size: iconSize),
          onPressed: () => Get.back(),
        ).animate(controller: _controller)
            .fadeIn(duration: 500.ms)
            .slideX(begin: -0.2, end: 0),
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
                Icons.smart_toy_rounded,
                color: const Color(0xFF00E676),
                size: iconSize + 4,
              ),
            ).animate(controller: _controller)
                .fadeIn(duration: 500.ms)
                .then()
                .shimmer(color: const Color(0xFF69F0AE), duration: 1000.ms),
            SizedBox(width: padding / 2),
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'AI Travel Assistant',
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
                  Obx(() => Text(
                    chatController.isLoading.value ? 'Typing...' : 'Online',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: subtitleFontSize * 0.8,
                      color: const Color(0xFFE0E0E0),
                      fontWeight: FontWeight.w400,
                    ),
                  )).animate(controller: _controller)
                      .fadeIn(delay: 100.ms, duration: 600.ms)
                      .slideX(begin: -0.2, end: 0),
                ],
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: const Color(0xFF00E676), size: iconSize),
            onPressed: () => _showChatOptions(context, fontScale, subtitleFontSize, padding, iconSize),
          ).animate(controller: _controller)
              .fadeIn(duration: 500.ms)
              .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
        ],
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
            top: true,
            bottom: false,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [const Color(0xFF2C2F33), const Color(0xFF1E1E1E)],
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(padding * 2),
                        topRight: Radius.circular(padding * 2),
                      ),
                    ),
                    child: Obx(() {
                      if (chatController.messages.isEmpty) {
                        return SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding),
                            child: Column(
                              children: [
                                SizedBox(height: padding * 2),
                                Container(
                                  padding: EdgeInsets.all(padding * 1.5),
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
                                    ],
                                  ),
                                  child: Column(
                                    children: [
                                      Container(
                                        padding: EdgeInsets.all(padding),
                                        decoration: BoxDecoration(
                                          gradient: LinearGradient(
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                            colors: [const Color(0xFF00E676).withOpacity(0.1), const Color(0xFF69F0AE).withOpacity(0.1)],
                                          ),
                                          borderRadius: BorderRadius.circular(padding),
                                        ),
                                        child: Icon(
                                          Icons.waving_hand,
                                          color: const Color(0xFF00E676),
                                          size: iconSize + 4,
                                        ),
                                      ),
                                      SizedBox(height: padding),
                                      Text(
                                        'Hello! I\'m your AI Travel Assistant',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: subtitleFontSize * 1.2,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFFFFFFFF),
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                      SizedBox(height: padding / 2),
                                      Text(
                                        'Ask me anything about your travel plans, destinations, or booking assistance!',
                                        style: TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: subtitleFontSize * 0.9,
                                          color: const Color(0xFFE0E0E0),
                                          fontWeight: FontWeight.w400,
                                        ),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ).animate(controller: _controller)
                                    .fadeIn(delay: 400.ms, duration: 700.ms)
                                    .slideY(begin: 0.2, end: 0)
                                    .then()
                                    .shimmer(color: const Color(0xFF69F0AE), duration: 1000.ms),
                                SizedBox(height: padding * 2),
                                _buildQuickActions(fontScale, subtitleFontSize, iconSize, padding),
                                SizedBox(height: padding * 4),
                              ],
                            ),
                          ),
                        );
                      }
                      return ListView.builder(
                        controller: _scrollController,
                        physics: const BouncingScrollPhysics(),
                        padding: EdgeInsets.fromLTRB(padding, padding, padding, padding * 2),
                        itemCount: chatController.messages.length,
                        itemBuilder: (context, index) {
                          final message = chatController.messages[index];
                          return _buildMessageBubble(message, index, fontScale, subtitleFontSize, iconSize, padding);
                        },
                      );
                    }),
                  ),
                ),
                Obx(() => chatController.isLoading.value
                    ? _buildTypingIndicator(fontScale, subtitleFontSize, iconSize, padding)
                    : const SizedBox.shrink()),
                _buildInputField(fontScale, subtitleFontSize, iconSize, padding),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(double fontScale, double subtitleFontSize, double iconSize, double padding) {
    final quickActions = [
      {'text': 'Find trains', 'icon': Icons.train},
      {'text': 'Book hotels', 'icon': Icons.hotel},
      {'text': 'Weather info', 'icon': Icons.wb_sunny},
      {'text': 'Local guides', 'icon': Icons.explore},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: padding / 2),
          child: Text(
            'Quick Actions',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontSize: subtitleFontSize,
              fontWeight: FontWeight.w600,
              color: const Color(0xFFFFFFFF),
            ),
          ),
        ),
        SizedBox(height: padding),
        Wrap(
          spacing: padding,
          runSpacing: padding,
          children: quickActions.map((action) {
            return GestureDetector(
              onTap: () => _sendQuickMessage(action['text'] as String),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 0.75),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [const Color(0xFF2C2F33), const Color(0xFF1E1E1E)],
                  ),
                  borderRadius: BorderRadius.circular(padding * 1.5),
                  border: Border.all(color: const Color(0xFF00E676).withOpacity(0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF00E676).withOpacity(0.1),
                      blurRadius: padding,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      action['icon'] as IconData,
                      size: iconSize,
                      color: const Color(0xFF00E676),
                    ),
                    SizedBox(width: padding / 2),
                    Text(
                      action['text'] as String,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: subtitleFontSize * 0.9,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFFFFFFFF),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList().animate(interval: 150.ms)
              .fadeIn(delay: 600.ms, duration: 500.ms)
              .slideY(begin: 0.1, end: 0)
              .then()
              .shimmer(color: const Color(0xFF69F0AE), duration: 1000.ms),
        ),
      ],
    );
  }

  Widget _buildMessageBubble(Message message, int index, double fontScale, double subtitleFontSize, double iconSize, double padding) {
    final isMe = message.sender == 'User';

    return Container(
      margin: EdgeInsets.only(bottom: padding),
      child: Row(
        mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            Container(
              width: iconSize + 8,
              height: iconSize + 8,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFF00E676).withOpacity(0.1), const Color(0xFF69F0AE).withOpacity(0.1)],
                ),
                borderRadius: BorderRadius.circular(padding),
              ),
              child: Icon(
                Icons.smart_toy,
                color: const Color(0xFF00E676),
                size: iconSize,
              ),
            ),
            SizedBox(width: padding / 2),
          ],
          Flexible(
            child: Container(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
                minWidth: 50 * fontScale,
              ),
              padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 0.75),
              decoration: BoxDecoration(
                gradient: isMe
                    ? const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFF00E676), Color(0xFF00C853)],
                )
                    : LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFF2C2F33), const Color(0xFF1E1E1E)],
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(padding * 2),
                  topRight: Radius.circular(padding * 2),
                  bottomLeft: Radius.circular(isMe ? padding * 2 : padding * 0.4),
                  bottomRight: Radius.circular(isMe ? padding * 0.4 : padding * 2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF00E676).withOpacity(0.2),
                    blurRadius: padding * 1.5,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (!isMe) ...[
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: 0,
                        maxHeight: 500,
                      ),
                      child: MarkdownWidget(
                        data: message.content,
                        config: MarkdownConfig(
                          configs: [
                            PConfig(
                              textStyle: TextStyle(
                                fontFamily: 'Poppins',
                                color: const Color(0xFFFFFFFF),
                                fontSize: subtitleFontSize * 0.9,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            H1Config(
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: const Color(0xFF00E676),
                                fontSize: subtitleFontSize * 1.3,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            H2Config(
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: const Color(0xFF00E676),
                                fontSize: subtitleFontSize * 1.2,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            H3Config(
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                color: const Color(0xFF00E676),
                                fontSize: subtitleFontSize * 1.1,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            CodeConfig(
                              style: TextStyle(
                                fontFamily: 'monospace',
                                color: const Color(0xFF00E676),
                                fontSize: subtitleFontSize * 0.8,
                                backgroundColor: const Color(0xFF2C2F33),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ] else ...[
                    Text(
                      message.content,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        color: const Color(0xFF000000),
                        fontSize: subtitleFontSize * 0.9,
                        height: 1.4,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                  SizedBox(height: padding / 2),
                  Text(
                    _formatTime(message.timestamp),
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      color: isMe ? const Color(0xFF000000).withOpacity(0.7) : const Color(0xFFE0E0E0),
                      fontSize: subtitleFontSize * 0.7,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isMe) ...[
            SizedBox(width: padding / 2),
            Container(
              width: iconSize + 8,
              height: iconSize + 8,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [const Color(0xFF2C2F33), const Color(0xFF1E1E1E)],
                ),
                borderRadius: BorderRadius.circular(padding),
              ),
              child: Icon(
                Icons.person,
                color: const Color(0xFF00E676),
                size: iconSize,
              ),
            ),
          ],
        ],
      ),
    ).animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: 0.1, end: 0, curve: Curves.easeOut)
        .then()
        .shimmer(color: const Color(0xFF69F0AE), duration: 1000.ms);
  }

  Widget _buildTypingIndicator(double fontScale, double subtitleFontSize, double iconSize, double padding) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding),
      child: Row(
        children: [
          Container(
            width: iconSize + 8,
            height: iconSize + 8,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [const Color(0xFF00E676).withOpacity(0.1), const Color(0xFF69F0AE).withOpacity(0.1)],
              ),
              borderRadius: BorderRadius.circular(padding),
            ),
            child: Icon(
              Icons.smart_toy,
              color: const Color(0xFF00E676),
              size: iconSize,
            ),
          ),
          SizedBox(width: padding / 2),
          Container(
            padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding * 0.75),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [const Color(0xFF2C2F33), const Color(0xFF1E1E1E)],
              ),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(padding * 2),
                topRight: Radius.circular(padding * 2),
                bottomLeft: Radius.circular(padding * 0.4),
                bottomRight: Radius.circular(padding * 2),
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E676).withOpacity(0.2),
                  blurRadius: padding * 1.5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(0, fontScale, padding),
                SizedBox(width: padding / 2),
                _buildTypingDot(200, fontScale, padding),
                SizedBox(width: padding / 2),
                _buildTypingDot(400, fontScale, padding),
              ],
            ),
          ),
        ],
      ),
    ).animate(onPlay: (controller) => controller.repeat())
        .fadeIn(duration: 400.ms);
  }

  Widget _buildTypingDot(int delay, double fontScale, double padding) {
    return Container(
      width: 8 * fontScale,
      height: 8 * fontScale,
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(4 * fontScale),
      ),
    ).animate(onPlay: (controller) => controller.repeat(reverse: true))
        .scale(
      delay: delay.ms,
      duration: 600.ms,
      begin: const Offset(1, 1),
      end: const Offset(1.5, 1.5),
    );
  }

  Widget _buildInputField(double fontScale, double subtitleFontSize, double iconSize, double padding) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: padding, vertical: padding),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [const Color(0xFF2C2F33), const Color(0xFF1E1E1E)],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(padding * 2),
          topRight: Radius.circular(padding * 2),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E676).withOpacity(0.2),
            blurRadius: padding * 2,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(padding * 2),
                  border: Border.all(color: const Color(0xFF00E676).withOpacity(0.3)),
                ),
                child: TextField(
                  controller: chatController.messageController,
                  focusNode: _focusNode,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    color: const Color(0xFFFFFFFF),
                    fontSize: subtitleFontSize * 0.9,
                    fontWeight: FontWeight.w500,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Ask me about travel...',
                    hintStyle: TextStyle(
                      fontFamily: 'Poppins',
                      color: const Color(0xFFE0E0E0),
                      fontSize: subtitleFontSize * 0.9,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: padding,
                      vertical: padding * 0.75,
                    ),
                    prefixIcon: Icon(
                      Icons.message,
                      color: const Color(0xFF69F0AE),
                      size: iconSize,
                    ),
                  ),
                  maxLines: null,
                  textCapitalization: TextCapitalization.sentences,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            SizedBox(width: padding / 2),
            ValueListenableBuilder<bool>(
              valueListenable: _hasText,
              builder: (context, hasText, child) {
                return Obx(() => Container(
                  decoration: BoxDecoration(
                    gradient: hasText
                        ? const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF00E676), Color(0xFF00C853)],
                    )
                        : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [const Color(0xFF2C2F33), const Color(0xFF1E1E1E)],
                    ),
                    borderRadius: BorderRadius.circular(padding * 2),
                  ),
                  child: chatController.isLoading.value
                      ? Container(
                    width: iconSize + 16,
                    height: iconSize + 16,
                    padding: EdgeInsets.all(padding / 2),
                    child: CircularProgressIndicator(
                      strokeWidth: 2 * fontScale,
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF69F0AE)),
                    ),
                  )
                      : IconButton(
                    icon: Icon(
                      Icons.send_rounded,
                      color: hasText ? const Color(0xFF000000) : const Color(0xFFE0E0E0),
                      size: iconSize,
                    ),
                    onPressed: hasText ? _sendMessage : null,
                  ),
                ));
              },
            ),
          ],
        ),
      ),
    ).animate(controller: _controller)
        .slideY(begin: 1, end: 0, delay: 400.ms, duration: 700.ms)
        .then()
        .shimmer(color: const Color(0xFF69F0AE), duration: 1000.ms);
  }

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else {
      return '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
    }
  }

  void _sendMessage() {
    if (chatController.messageController.text.trim().isNotEmpty) {
      chatController.sendMessage(chatController.messageController.text.trim());
      chatController.messageController.clear();
      _focusNode.unfocus();
    }
  }

  void _sendQuickMessage(String message) {
    chatController.sendMessage(message);
  }

  void _showChatOptions(BuildContext context, double fontScale, double subtitleFontSize, double padding, double iconSize) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.35,
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
                  'Chat Options',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: subtitleFontSize * 1.2,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFFFFFFFF),
                  ),
                ),
              ),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: padding),
                  children: [
                    _buildOptionItem(
                      'Clear Chat',
                      Icons.delete_outline,
                      const Color(0xFFFF5252),
                          () {
                        Get.back();
                        chatController.messages.clear();
                      },
                      fontScale: fontScale,
                      subtitleFontSize: subtitleFontSize,
                      padding: padding,
                      iconSize: iconSize,
                    ),
                    _buildOptionItem(
                      'Help & Tips',
                      Icons.help_outline,
                      const Color(0xFF00E676),
                          () {
                        Get.back();
                        _sendQuickMessage('How can you help me?');
                      },
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

  Widget _buildOptionItem(
      String title,
      IconData icon,
      Color color,
      VoidCallback onTap, {
        required double fontScale,
        required double subtitleFontSize,
        required double padding,
        required double iconSize,
      }) {
    return Padding(
      padding: EdgeInsets.only(bottom: padding),
      child: GestureDetector(
        onTap: onTap,
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
                Text(
                  title,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: subtitleFontSize,
                    color: const Color(0xFFFFFFFF),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import '../../core/utils/responsive_layout.dart';
import '../../core/values/app_colors.dart';
import '../../core/values/app_constants.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_text_field.dart';
import 'auth_controller.dart';

/// Premium, modern authentication screen for Ayushka Organic Cattle & Dairy Management.
/// Features an immersive full-bleed photographic showcase of authentic Indian Cattle breeds
/// and a refined, elevated auth card with warm organic accents.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late final AuthController controller;
  final FocusNode _passwordFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    controller = Get.find<AuthController>();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    _passwordFocusNode.dispose();
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent &&
        (event.logicalKey == LogicalKeyboardKey.enter ||
         event.logicalKey == LogicalKeyboardKey.numpadEnter)) {
      controller.login();
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ResponsiveLayout(
        mobile: _buildMobileView(context),
        desktop: _buildDesktopView(context),
      ),
    );
  }

  // -------------------------------------------------------------
  // DESKTOP & WEB 50/50 SPLIT VIEW
  // -------------------------------------------------------------
  Widget _buildDesktopView(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        // Left Half: Full-Bleed Cinematic Photography & Dairy Storytelling
        const Expanded(
          flex: 5,
          child: _AuthVisualHero(),
        ),

        // Right Half: Warm, Modern, Balanced Auth Station
        Expanded(
          flex: 5,
          child: Container(
            color: isDark ? const Color(0xFF131D13) : const Color(0xFFF7F8F4),
            child: Stack(
              children: [
                // Subtle Ambient Organic Glow in Top-Right
                Positioned(
                  top: -80,
                  right: -80,
                  child: Container(
                    width: 320,
                    height: 320,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          AppColors.primaryLight.withValues(alpha: isDark ? 0.08 : 0.12),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),

                // Center Content: Elevated Sign-In Card & Footer
                Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 40),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 440),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildFormCard(context),
                          const SizedBox(height: 24),
                          // Subtle Footer
                          Text(
                            '© 2026 Ayushka • Organic Living & Happiness. All rights reserved.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------
  // MOBILE & TABLET SINGLE-COLUMN VIEW
  // -------------------------------------------------------------
  Widget _buildMobileView(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenHeight = MediaQuery.of(context).size.height;
    final screenWidth = MediaQuery.of(context).size.width;
    final double bannerHeight = screenHeight < 680 ? 150 : (screenWidth < 360 ? 170 : 210);

    return Container(
      color: isDark ? const Color(0xFF131D13) : const Color(0xFFF7F8F4),
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Mobile Top Hero Banner
              Stack(
                children: [
                  Container(
                    height: bannerHeight,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
                      image: DecorationImage(
                        image: AssetImage('assets/images/gir_cattle_herd.jpg'),
                        fit: BoxFit.cover,
                        alignment: Alignment.center,
                      ),
                    ),
                  ),
                  Container(
                    height: bannerHeight,
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.3),
                          const Color(0xFF141F14).withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 16,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Image.asset(
                          AppConstants.logoPath,
                          height: screenWidth < 360 ? 42 : 52,
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Form Card
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: screenWidth < 360 ? 12 : 20,
                  vertical: 10,
                ),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Column(
                    children: [
                      _buildFormCard(context),
                      const SizedBox(height: 20),
                      Text(
                        '© 2026 Ayushka • Organic Living & Happiness. All rights reserved.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // ELEVATED LUXURY AUTHENTICATION FORM CARD
  // -------------------------------------------------------------
  Widget _buildFormCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 650;
    final horizontalPad = isMobile ? (screenWidth < 360 ? 18.0 : 24.0) : 36.0;
    final verticalPad = isMobile ? 24.0 : 34.0;

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.enter): controller.login,
        const SingleActivator(LogicalKeyboardKey.numpadEnter): controller.login,
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: horizontalPad, vertical: verticalPad),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isDark ? AppColors.borderDark : const Color(0xFFE2E8DC),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF223318).withValues(alpha: isDark ? 0.25 : 0.07),
              blurRadius: 36,
              offset: const Offset(0, 14),
            ),
            BoxShadow(
              color: const Color(0xFF223318).withValues(alpha: isDark ? 0.15 : 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Form(
          key: controller.formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Heading & Subtitle
              Text(
                'Sign In',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: isDark ? AppColors.textPrimaryDark : const Color(0xFF1E2D17),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Welcome back! Enter credentials to access Ayushka farm station.',
                style: TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  color: isDark ? AppColors.textSecondaryDark : const Color(0xFF657A59),
                ),
              ),
              const SizedBox(height: 24),

              // Username / Email Field
              CustomTextField(
                label: 'Username / Email',
                hint: 'Enter your username or email',
                controller: controller.userIdController,
                validator: controller.validateUserId,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.next,
                prefixIcon: const Icon(Icons.person_outline_rounded, size: 20, color: AppColors.primary),
                onSubmitted: (_) {
                  if (controller.passwordController.text.trim().isNotEmpty) {
                    controller.login();
                  } else {
                    _passwordFocusNode.requestFocus();
                  }
                },
              ),
              const SizedBox(height: 18),

              // Password Field
              CustomTextField(
                label: 'Password',
                hint: 'Enter your password',
                controller: controller.passwordController,
                focusNode: _passwordFocusNode,
                validator: controller.validatePassword,
                isPassword: true,
                textInputAction: TextInputAction.done,
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: AppColors.primary),
                onSubmitted: (_) => controller.login(),
              ),
              const SizedBox(height: 14),

              // Remember Me
              Row(
                children: [
                  Obx(
                    () => SizedBox(
                      height: 22,
                      width: 22,
                      child: Checkbox(
                        value: controller.rememberMe.value,
                        onChanged: controller.toggleRememberMe,
                        activeColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Remember me',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.textSecondaryDark : const Color(0xFF4A5F40),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),

              // Primary Action Button
              Obx(
                () => CustomButton(
                  text: 'Sign In',
                  onPressed: controller.login,
                  isLoading: controller.isLoading.value,
                  icon: Icons.arrow_forward_rounded,
                  height: 50,
                  borderRadius: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// =============================================================================
// FULL-BLEED CINEMATIC VISUAL SHOWCASE (LEFT DESKTOP PANEL)
// =============================================================================
class _AuthVisualHero extends StatefulWidget {
  const _AuthVisualHero();

  @override
  State<_AuthVisualHero> createState() => _AuthVisualHeroState();
}

class _AuthVisualHeroState extends State<_AuthVisualHero> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  Timer? _autoPlayTimer;

  final List<Map<String, String>> _slides = const [
    {
      'image': 'assets/images/gir_cattle_herd.jpg',
      'tag': 'GIR CATTLE HERD',
      'title': 'Indigenous Gir Cattle Herd',
      'subtitle': 'Vast herd of pedigree Gir cattle & calves grazing freely in open pastures.',
      'badge1': '🌿 100% Organic Pasture',
      'badge2': '🥛 Pure A2 Vedic Milk',
      'badge3': '🏷️ Herd Telemetry',
    },
    {
      'image': 'assets/images/vedic_gaushala_herd.jpg',
      'tag': 'VEDIC GAUSHALA',
      'title': 'Traditional Dairy Gaushala',
      'subtitle': 'Ethical open-air shelter with balanced green fodder & cruelty-free care.',
      'badge1': '🌾 Fresh Green Fodder',
      'badge2': '🩺 Daily Health Sync',
      'badge3': '🛡️ Zero Hormones',
    },
    {
      'image': 'assets/images/sahiwal_gir_herd.jpg',
      'tag': 'FREE-RANGE PASTURE',
      'title': 'Sahiwal & Gir Pasture Cattle Herd',
      'subtitle': 'Free-range grazing supporting natural vitality, high immunity, and premium milk.',
      'badge1': '🧈 High Fat & SNF',
      'badge2': '🧬 Pedigree Tracked',
      'badge3': '🧪 Lab Certified Purity',
    },
    {
      'image': 'assets/images/gir_pasture_herd.jpg',
      'tag': 'SUNSET GRAZING',
      'title': 'Vedic Godhuli Evening Herd',
      'subtitle': 'Calves and mothers resting peacefully across organic natural farmland.',
      'badge1': '🐄 Healthy Cattle Herd',
      'badge2': '🌱 Chemical-Free Soil',
      'badge3': '✨ 100% Desi Breed',
    },
  ];

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (_pageController.hasClients) {
        final next = (_currentIndex + 1) % _slides.length;
        _pageController.animateToPage(
          next,
          duration: const Duration(milliseconds: 700),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void _goTo(int index) {
    if (_pageController.hasClients) {
      _pageController.animateToPage(
        index,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _prev() {
    final prev = (_currentIndex - 1 + _slides.length) % _slides.length;
    _goTo(prev);
  }

  void _next() {
    final next = (_currentIndex + 1) % _slides.length;
    _goTo(next);
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentSlide = _slides[_currentIndex];

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. Full-Bleed Photographic Carousel
        PageView.builder(
          controller: _pageController,
          itemCount: _slides.length,
          onPageChanged: (index) => setState(() => _currentIndex = index),
          itemBuilder: (context, index) {
            final slide = _slides[index];
            return Image.asset(
              slide['image']!,
              fit: BoxFit.cover,
              alignment: Alignment.center,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) => Container(
                color: const Color(0xFF2E3E21),
                child: const Center(
                  child: Icon(Icons.pets_rounded, color: Colors.white30, size: 64),
                ),
              ),
            );
          },
        ),

        // 2. Cinematic Gradient Overlay (Top vignette + deep forest base)
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: 0.30),
                Colors.transparent,
                Colors.black.withValues(alpha: 0.16),
                const Color(0xFF141F14).withValues(alpha: 0.88),
              ],
              stops: const [0.0, 0.22, 0.65, 1.0],
            ),
          ),
        ),

        // 3. Top-Left Floating Brand Emblem
        Positioned(
          top: 36,
          left: 40,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.96),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 18,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Image.asset(
              AppConstants.logoPath,
              height: 50,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),

        // 4. Bottom Floating Glassmorphism Showcase Card & Controls
        Positioned(
          left: 24,
          right: 24,
          bottom: 24,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Slide Tag Badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            currentSlide['tag']!,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        // Live Farm Badge
                        Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF4CAF50),
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Text(
                              'LIVE TELEMETRY',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    // Slide Title
                    Text(
                      currentSlide['title']!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Slide Subtitle
                    Text(
                      currentSlide['subtitle']!,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.88),
                        fontSize: 12,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // 3 Stat Chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _buildGlassChip(currentSlide['badge1']!),
                        _buildGlassChip(currentSlide['badge2']!),
                        _buildGlassChip(currentSlide['badge3']!),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Navigation: Animated Dots + Manual Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Dots
                        Row(
                          children: List.generate(
                            _slides.length,
                            (index) => MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: GestureDetector(
                                onTap: () => _goTo(index),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.only(right: 6),
                                  height: 6,
                                  width: _currentIndex == index ? 24 : 6,
                                  decoration: BoxDecoration(
                                    color: _currentIndex == index
                                        ? Colors.white
                                        : Colors.white.withValues(alpha: 0.35),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Arrow Buttons
                        Row(
                          children: [
                            _buildNavBtn(
                              icon: Icons.chevron_left_rounded,
                              onTap: _prev,
                            ),
                            const SizedBox(width: 8),
                            _buildNavBtn(
                              icon: Icons.chevron_right_rounded,
                              onTap: _next,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGlassChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.22),
        ),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildNavBtn({required IconData icon, required VoidCallback onTap}) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
      ),
    );
  }
}

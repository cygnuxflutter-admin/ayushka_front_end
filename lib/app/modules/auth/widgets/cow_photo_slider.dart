import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/values/app_colors.dart';

class CowSlideItem {
  final String imagePath;
  final String title;
  final String subtitle;
  final String tag;

  const CowSlideItem({
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.tag,
  });
}

/// Automatic photo slider showcasing authentic Indian Cattle breeds (Gir, Sahiwal, Grazing herd).
class CowPhotoSlider extends StatefulWidget {
  final double height;

  const CowPhotoSlider({super.key, this.height = 240});

  @override
  State<CowPhotoSlider> createState() => _CowPhotoSliderState();
}

class _CowPhotoSliderState extends State<CowPhotoSlider> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  Timer? _autoPlayTimer;

  final List<CowSlideItem> _slides = const [
    CowSlideItem(
      imagePath: 'assets/images/gir_cattle_herd.jpg',
      title: 'Indigenous Gir Cattle Herd',
      subtitle: 'Pure A2 Vedic Milk • Open Saurashtra Gujarat Pasture',
      tag: 'GIR HERD',
    ),
    CowSlideItem(
      imagePath: 'assets/images/vedic_gaushala_herd.jpg',
      title: 'Vedic Gaushala Dairy Farm',
      subtitle: 'Ethical herd shelter with fresh organic green fodder feeding',
      tag: 'VEDIC GAUSHALA',
    ),
    CowSlideItem(
      imagePath: 'assets/images/sahiwal_gir_herd.jpg',
      title: 'Sahiwal & Gir Pasture Cattle Herd',
      subtitle: 'Free-range grazing supporting vitality and premium butterfat',
      tag: 'PASTURE HERD',
    ),
    CowSlideItem(
      imagePath: 'assets/images/gir_pasture_herd.jpg',
      title: 'Vedic Godhuli Evening Herd',
      subtitle: 'Natural herd habitat with healthy mother cows and calves',
      tag: 'FREE RANGE',
    ),
  ];

  @override
  void initState() {
    super.initState();
    _startAutoPlay();
  }

  void _startAutoPlay() {
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (timer) {
      if (_pageController.hasClients) {
        final nextIndex = (_currentIndex + 1) % _slides.length;
        _pageController.animateToPage(
          nextIndex,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  void _prevSlide() {
    if (_pageController.hasClients) {
      final prevIndex = (_currentIndex - 1 + _slides.length) % _slides.length;
      _pageController.animateToPage(
        prevIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  void _nextSlide() {
    if (_pageController.hasClients) {
      final nextIndex = (_currentIndex + 1) % _slides.length;
      _pageController.animateToPage(
        nextIndex,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // PageView Carousel
            PageView.builder(
              controller: _pageController,
              itemCount: _slides.length,
              onPageChanged: (index) {
                setState(() => _currentIndex = index);
              },
              itemBuilder: (context, index) {
                final slide = _slides[index];
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    // Cow Photo Image
                    Image.asset(
                      slide.imagePath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: const Color(0xFF384C28),
                          child: const Center(
                            child: Icon(Icons.pets_rounded, color: Colors.white, size: 48),
                          ),
                        );
                      },
                    ),

                    // Gradient Overlay for Text Readability
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.black.withValues(alpha: 0.1),
                            Colors.black.withValues(alpha: 0.4),
                            Colors.black.withValues(alpha: 0.85),
                          ],
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),

                    // Top Tag Badge
                    Positioned(
                      top: 14,
                      left: 14,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.88),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.white.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          slide.tag,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                    ),

                    // Bottom Content (Title & Subtitle)
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            slide.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(color: Colors.black54, blurRadius: 4),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            slide.subtitle,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 12,
                              height: 1.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),

            // Left & Right Arrow Navigation Controls
            Positioned(
              left: 6,
              top: 0,
              bottom: 0,
              child: Center(
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: InkWell(
                    onTap: _prevSlide,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chevron_left_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 6,
              top: 0,
              bottom: 0,
              child: Center(
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: InkWell(
                    onTap: _nextSlide,
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.35),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.chevron_right_rounded, color: Colors.white, size: 20),
                    ),
                  ),
                ),
              ),
            ),

            // Indicator Dots (Top Right)
            Positioned(
              top: 14,
              right: 14,
              child: Row(
                children: List.generate(_slides.length, (index) {
                  final isActive = _currentIndex == index;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    height: 6,
                    width: isActive ? 18 : 6,
                    decoration: BoxDecoration(
                      color: isActive ? Colors.white : Colors.white.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

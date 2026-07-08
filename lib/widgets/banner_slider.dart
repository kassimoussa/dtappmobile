import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/banner.dart';
import '../services/banner_service.dart';
import '../constants/app_theme.dart';
import '../utils/responsive_size.dart';

class BannerSlider extends StatefulWidget {
  const BannerSlider({super.key});

  @override
  State<BannerSlider> createState() => _BannerSliderState();
}

class _BannerSliderState extends State<BannerSlider> {
  static const int _maxPages = 10000;

  List<PromoBanner> _banners = [];
  bool _isLoading = true;
  late final PageController _pageController;
  Timer? _autoScrollTimer;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: _maxPages ~/ 2);
    _loadBanners();
  }

  @override
  void dispose() {
    _autoScrollTimer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _loadBanners() async {
    try {
      final banners = await BannerService.getBanners();
      if (mounted) {
        setState(() {
          _banners = banners;
          _isLoading = false;
        });
        if (_banners.length > 1) {
          _startAutoScroll();
        }
      }
    } catch (e) {
      debugPrint('Erreur chargement bannières: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _startAutoScroll() {
    _autoScrollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted || !_pageController.hasClients) return;
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _onBannerTap(PromoBanner banner) async {
    if (banner.link == null || banner.link!.isEmpty) return;
    final uri = Uri.tryParse(banner.link!);
    if (uri != null && await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return SizedBox(
        height: ResponsiveSize.getHeight(120),
        child: const Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.dtBlue),
          ),
        ),
      );
    }

    if (_banners.isEmpty) return const SizedBox.shrink();

    final double sliderHeight = ResponsiveSize.getHeight(100);

    return Column(
      children: [
        SizedBox(
          height: sliderHeight,
          child: PageView.builder(
            controller: _pageController,
            itemCount: _maxPages,
            itemBuilder: (context, index) {
              final banner = _banners[index % _banners.length];
              return GestureDetector(
                onTap: () => _onBannerTap(banner),
                child: Container(
                  margin: EdgeInsets.symmetric(
                    horizontal: ResponsiveSize.getWidth(4),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(
                      ResponsiveSize.getWidth(AppTheme.radiusM),
                    ),
                    child: CachedNetworkImage(
                      imageUrl: banner.imageUrl,
                      fit: BoxFit.fill,
                      width: double.infinity,
                      height: sliderHeight,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppTheme.dtBlue,
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: Icon(
                            Icons.image_not_supported_outlined,
                            color: Colors.grey[400],
                            size: ResponsiveSize.getFontSize(40),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

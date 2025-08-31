import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:math' as math;

class WebViewScreen extends StatefulWidget {
  final String url;
  final String title;
  final Color themeColor;

  const WebViewScreen({
    super.key,
    required this.url,
    required this.title,
    required this.themeColor,
  });

  @override
  State<WebViewScreen> createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> with SingleTickerProviderStateMixin {
  late final WebViewController controller;
  bool isLoading = true;
  double loadingProgress = 0.0;
  String currentUrl = '';
  bool _isNavigationVisible = true; // Start visible then auto-hide
  late AnimationController _animationController;
  bool _initialLoadComplete = false;
  bool _adBlockerEnabled = true; // Ad blocker enabled by default
  String _initialUrlDomain = '';
  bool _userInteracting = false;
  
  // List of ad-related domains to block
  final List<String> _adDomains = [
    'doubleclick.net',
    'googlesyndication.com',
    'adservice.google.com',
    'adserver',
    'analytics',
    'banner',
    'advert',
    'popup',
    'tracker',
    'track',
    'ads.',
    'ad.',
  ];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    // Extract domain from initial URL
    _initialUrlDomain = _extractDomain(widget.url);
    
    // Start with navigation visible, then animate to hidden after a delay
    _animationController.value = 1.0;
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() {
          _isNavigationVisible = false;
          _animationController.reverse();
        });
      }
    });
    
    // Initialize WebView with advanced settings for faster performance
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.white)
      ..enableZoom(true)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                loadingProgress = progress / 100;
                // Ensure we're showing loading state while progress is happening
                isLoading = progress < 100;
              });
            }
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                isLoading = true;
                currentUrl = url;
              });
              
              // Auto-detect and go back for unknown URLs
              if (_shouldGoBackFromUrl(url)) {
                _showGoBackDialog(url);
              }
              
              // Only inject ad blocker
              if (_adBlockerEnabled) {
                _injectAdBlocker();
              }
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              // Re-apply ad blocker if enabled
              if (_adBlockerEnabled) {
                _injectAdBlocker();
              }
              
              setState(() {
                isLoading = false;
                currentUrl = url;
                _initialLoadComplete = true;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (mounted) {
              print("WebView Error: ${error.description} (${error.errorCode})");
              
              // Only show errors if they're critical
              if (error.errorCode >= 400) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error loading page: ${error.description}'),
                    backgroundColor: Colors.red,
                    duration: const Duration(seconds: 2),
                  ),
                );
              }
              
              setState(() {
                isLoading = false;
              });
            }
          },
          // URL filtering for ad blocking
          onNavigationRequest: (NavigationRequest request) {
            // Block ad-related URLs if ad blocker is enabled
            if (_adBlockerEnabled && _isAdUrl(request.url)) {
              print("Blocked ad request: ${request.url}");
              return NavigationDecision.prevent;
            }
            
            // Check if we should navigate or show a warning
            if (_shouldGoBackFromUrl(request.url)) {
              // Show an alert instead of immediately going back
              Future.delayed(Duration.zero, () => _showGoBackDialog(request.url));
              return NavigationDecision.navigate; // Still allow, but we'll handle with dialog
            }
            
            return NavigationDecision.navigate;
          },
        ),
      );
    
    _configureWebView();
  }
  
  void _configureWebView() async {
    // Set advanced settings for the WebView
    await controller.clearCache();
    
    // Load the URL
    controller.loadRequest(Uri.parse(widget.url));
  }
  
  // Extract domain from URL
  String _extractDomain(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.host;
    } catch (e) {
      // If parsing fails, return original URL
      return url;
    }
  }
  
  // Check if URL is from an unknown domain
  bool _shouldGoBackFromUrl(String url) {
    if (_initialUrlDomain.isEmpty) return false;
    
    final currentDomain = _extractDomain(url);
    
    // Check if the domain is significantly different
    if (!currentDomain.contains(_initialUrlDomain) && 
        !_initialUrlDomain.contains(currentDomain) &&
        currentDomain != _initialUrlDomain) {
      
      // Ignore common trusted domains
      final trustedDomains = [
        'google.com', 
        'youtube.com',
        'facebook.com', 
        'twitter.com',
        'instagram.com',
        'amazonaws.com',
        'cloudfront.net',
        'cloudflare.com',
        'akamaized.net'
      ];
      
      for (final trusted in trustedDomains) {
        if (currentDomain.contains(trusted)) {
          return false;
        }
      }
      
      return true;
    }
    
    return false;
  }
  
  // Show dialog for unknown URLs
  void _showGoBackDialog(String url) {
    final domain = _extractDomain(url);
    
    Future.delayed(Duration.zero, () {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          title: Text('Leaving $domain'),
          content: Text('This link is taking you to $domain, which is outside the current site.\n\nDo you want to continue?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                controller.goBack();
              },
              child: const Text('Go Back'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Continue'),
            ),
          ],
        ),
      );
    });
  }
  
  // Hide navigation bars
  void _hideNavigation() {
    if (_isNavigationVisible) {
      setState(() {
        _isNavigationVisible = false;
        _animationController.reverse();
      });
    }
  }
  
  // Check if a URL is ad-related
  bool _isAdUrl(String url) {
    final String lowerUrl = url.toLowerCase();
    return _adDomains.any((domain) => lowerUrl.contains(domain));
  }
  
  // Inject ad blocker script - simple version that only hides ads
  void _injectAdBlocker() {
    controller.runJavaScript('''
      (function() {
        try {
          // Common ad selectors
          const adSelectors = [
            'div[id*="google_ads"]',
            'div[id*="ad-"]',
            'div[class*="ad-"]',
            'div[class*="ads-"]',
            'div[id*="banner"]',
            'iframe[src*="doubleclick"]',
            'iframe[src*="ads"]',
            'ins.adsbygoogle',
            'div[id*="gpt"]',
            '.advertisement',
            '.adsbygoogle',
            '#ad',
            '.ad-container'
          ];
          
          // Hide ads without removing elements
          adSelectors.forEach(selector => {
            document.querySelectorAll(selector).forEach(el => {
              el.style.display = 'none';
            });
          });
        } catch(e) {
          // Silent fail
        }
      })();
    ''');
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleNavigation() {
    setState(() {
      _isNavigationVisible = !_isNavigationVisible;
      if (_isNavigationVisible) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }
  
  void _toggleAdBlocker() {
    setState(() {
      _adBlockerEnabled = !_adBlockerEnabled;
      if (_adBlockerEnabled) {
        _injectAdBlocker();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ad blocker enabled'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 1),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ad blocker disabled'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 1),
          ),
        );
        controller.reload(); // Reload to show ads
      }
    });
  }
  
  // Fix WebView rendering issues by reloading
  Future<void> _fixBlankScreen() async {
    setState(() {
      isLoading = true;
    });
    
    // Clear cache and cookies for a fresh start
    await controller.clearCache();
    
    // Force a reload without extra JavaScript
    controller.reload();
    
    // Set a timeout to clear loading state in case the reload hangs
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && isLoading) {
        setState(() {
          isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (await controller.canGoBack()) {
          await controller.goBack();
          return false;
        }
        return true;
      },
      child: Scaffold(
        extendBodyBehindAppBar: true, 
        extendBody: true, 
        backgroundColor: Colors.white,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: _isNavigationVisible ? kToolbarHeight : 0,
                child: AnimatedOpacity(
                  opacity: _isNavigationVisible ? 1.0 : 0.0,
                  duration: const Duration(milliseconds: 200),
                  child: AppBar(
                    backgroundColor: widget.themeColor.withOpacity(0.85),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    title: Text(widget.title),
                    leading: IconButton(
                      icon: const Icon(Icons.close),
                      tooltip: 'Close Navigation',
                      onPressed: _hideNavigation,
                    ),
                    actions: [
                      // Ad blocker toggle button
                      IconButton(
                        icon: Icon(_adBlockerEnabled ? Icons.block : Icons.block_flipped),
                        tooltip: _adBlockerEnabled ? 'Disable Ad Blocker' : 'Enable Ad Blocker',
                        onPressed: _toggleAdBlocker,
                      ),
                      IconButton(
                        icon: const Icon(Icons.refresh),
                        onPressed: _fixBlankScreen,
                      ),
                      IconButton(
                        icon: const Icon(Icons.home),
                        onPressed: () {
                          setState(() {
                            isLoading = true;
                          });
                          controller.loadRequest(Uri.parse(widget.url));
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        body: Stack(
          children: [
            // The WebView content
            WebViewWidget(
              controller: controller,
            ),
            
            // Loading indicator overlay
            if (isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Container(
                    width: 70,
                    height: 70, 
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.6),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Loading spinner
                        SizedBox(
                          height: 30,
                          width: 30,
                          child: CircularProgressIndicator(
                            value: loadingProgress > 0 ? loadingProgress : null,
                            strokeWidth: 3.0,
                            color: widget.themeColor,
                            backgroundColor: Colors.white24,
                          ),
                        ),
                        const SizedBox(height: 8),
                        // Percentage text
                        Text(
                          '${(loadingProgress * 100).toInt()}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
        floatingActionButton: AnimatedOpacity(
          opacity: _isNavigationVisible ? 0.0 : 1.0,
          duration: const Duration(milliseconds: 200),
          child: FloatingActionButton(
            backgroundColor: widget.themeColor,
            onPressed: _toggleNavigation,
            child: AnimatedIcon(
              icon: AnimatedIcons.menu_close,
              progress: _animationController,
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
        bottomNavigationBar: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: _isNavigationVisible ? 80 : 0,
              child: AnimatedOpacity(
                opacity: _isNavigationVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: NavigationBar(
                  backgroundColor: widget.themeColor.withOpacity(0.85),
                  height: 80,
                  selectedIndex: 0,
                  destinations: const [
                    NavigationDestination(
                      icon: Icon(Icons.arrow_back),
                      label: 'Back',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.arrow_forward),
                      label: 'Forward',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.open_in_browser),
                      label: 'Open in Browser',
                    ),
                    NavigationDestination(
                      icon: Icon(Icons.close),
                      label: 'Close Menu',
                    ),
                  ],
                  onDestinationSelected: (int index) async {
                    switch (index) {
                      case 0:
                        if (await controller.canGoBack()) {
                          setState(() {
                            isLoading = true;
                          });
                          await controller.goBack();
                        }
                        break;
                      case 1:
                        if (await controller.canGoForward()) {
                          setState(() {
                            isLoading = true;
                          });
                          await controller.goForward();
                        }
                        break;
                      case 2:
                        final Uri url = Uri.parse(currentUrl);
                        if (await canLaunchUrl(url)) {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        }
                        break;
                      case 3:
                        _hideNavigation();
                        break;
                    }
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Future<bool> canLaunchUrl(Uri url) async {
    try {
      return await canLaunch(url.toString());
    } catch (_) {
      return false;
    }
  }

  Future<void> launch(String url) async {
    try {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      // Ignore errors
    }
  }

  Future<bool> canLaunch(String url) async {
    try {
      return url.startsWith('http://') || url.startsWith('https://');
    } catch (e) {
      return false;
    }
  }
} 
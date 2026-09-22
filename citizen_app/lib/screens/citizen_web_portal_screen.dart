import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:geolocator/geolocator.dart';
import '../config/api_config.dart';

class CitizenWebPortalScreen extends StatefulWidget {
  const CitizenWebPortalScreen({super.key});

  @override
  State<CitizenWebPortalScreen> createState() => _CitizenWebPortalScreenState();
}

class _CitizenWebPortalScreenState extends State<CitizenWebPortalScreen> {
  static const MethodChannel _cameraChannel =
      MethodChannel('in.gov.rajasthan.kdakota.enivaran/camera_permission');

  late final WebViewController _controller;
  bool _isLoading = true;
  double _progress = 0;
  double? _cachedLat;
  double? _cachedLng;

  Future<bool> _ensureCameraPermission() async {
    try {
      final bool? granted =
          await _cameraChannel.invokeMethod<bool>('requestCameraPermission');
      return granted ?? false;
    } catch (e) {
      debugPrint('Camera permission channel error: $e');
      return false;
    }
  }

  @override
  void initState() {
    super.initState();
    _ensureCameraPermission();

    final citizenUrl = "${ApiConfig.baseUrl}/auth/login?citizen_app=1";

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFFF8FAFC))
      ..setUserAgent("Mozilla/5.0 (Linux; Android 10; KDA-Citizen-App) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36")
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _progress = progress / 100;
              _isLoading = progress < 100;
            });
          },
          onPageStarted: (String url) {
            _controller.runJavaScript('window.isNativeCitizenApp = true;');
            _injectCitizenAppStyles();
            if (_cachedLat != null && _cachedLng != null) {
              _injectLocationJs(_cachedLat!, _cachedLng!);
            }
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
            _controller.runJavaScript('window.isNativeCitizenApp = true;');
            _injectCitizenAppStyles();
            if (_cachedLat != null && _cachedLng != null) {
              _injectLocationJs(_cachedLat!, _cachedLng!);
            }
            _fetchAndInjectNativeLocation();
          },
          onNavigationRequest: (NavigationRequest request) {
            final path = request.url.toLowerCase();
            // Guard: block any departmental staff access
            if (path.contains("department") || path.contains("admin/dashboard")) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Citizen Only Portal")),
              );
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      );

    if (_controller.platform is AndroidWebViewController) {
      final androidController = _controller.platform as AndroidWebViewController;
      androidController.setGeolocationPermissionsPromptCallbacks(
        onShowPrompt: (request) async {
          return const GeolocationPermissionsResponse(
            allow: true,
            retain: true,
          );
        },
      );
      androidController.setOnPlatformPermissionRequest(
        (request) async {
          await _ensureCameraPermission();
          await request.grant();
        },
      );
    }

    _controller.loadRequest(Uri.parse(citizenUrl));
    _fetchAndInjectNativeLocation();
  }

  void _injectLocationJs(double lat, double lng) {
    _controller.runJavaScript('''
      (function() {
        window.isNativeCitizenApp = true;
        window.nativeCitizenLocation = { lat: $lat, lng: $lng };
        if (navigator.geolocation) {
          navigator.geolocation.getCurrentPosition = function(success, error, options) {
            success({
              coords: {
                latitude: $lat,
                longitude: $lng,
                accuracy: 10,
                altitude: null,
                altitudeAccuracy: null,
                heading: null,
                speed: null
              },
              timestamp: Date.now()
            });
          };
        }
        if (typeof window.onNativeLocationReady === 'function') {
          window.onNativeLocationReady($lat, $lng);
        }
      })();
    ''');
  }

  Future<void> _fetchAndInjectNativeLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.always || permission == LocationPermission.whileInUse) {
        Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 5),
        );
        _cachedLat = position.latitude;
        _cachedLng = position.longitude;
        _injectLocationJs(_cachedLat!, _cachedLng!);
      }
    } catch (e) {
      debugPrint("Native location fetch error: $e");
    }
  }

  void _injectCitizenAppStyles() {
    _controller.runJavaScript(r"""
      (function() {
        window.isNativeCitizenApp = true;
        // 1. Inject CSS to hide all Departmental elements & ensure Landing cards are visible
        var styleId = 'kda-citizen-portal-cleaner';
        if (!document.getElementById(styleId)) {
          var style = document.createElement('style');
          style.id = styleId;
          style.innerHTML = `
            /* Hide all Departmental Login buttons, badges & drawer containers */
            .dept-pro-icon-btn,
            .dept-login-drawer-container,
            a[href*="department"],
            [href*="department_login"],
            [href*="departmentlogin"],
            .mobile-drawer-body a[href*="department"],
            .mobile-drawer-body .border-top {
              display: none !important;
              visibility: hidden !important;
              height: 0 !important;
              padding: 0 !important;
              margin: 0 !important;
              border: none !important;
            }

            /* Hide Install App option in native APK */
            #installPwaBtn, #installAppNavBtn, .install-app-btn,
            a[href*="install"], a[href*="pwa"],
            [id*="install"], [id*="pwa"],
            .pwa-install-trigger, .pwa-install-nav-item, .pwa-install-divider,
            li:has(.pwa-install-trigger),
            [data-i18n="nav_install_app"],
            li:has([data-i18n="nav_install_app"]) {
              display: none !important;
              visibility: hidden !important;
            }

            /* Primary color override */
            :root {
              --primary: #e3861c !important;
              --bs-primary: #e3861c !important;
            }

            /* Exact match #e3861c color styling for requested app elements */
            /* 1. Register Your Complaint Pill Button */
            .mobile-open-auth-trigger,
            .mobile-register-complaint-box .btn,
            button:has([data-i18n="lodge_complaint"]),
            #mobileDropdownLoginBtn {
              background: #e3861c !important;
              background-image: none !important;
              color: #ffffff !important;
              border: none !important;
              box-shadow: 0 4px 16px rgba(227, 134, 28, 0.4) !important;
            }

            /* 2. Mobile Hamburger Menu Toggle Button */
            #mobileMenuToggleBtn,
            .mobile-menu-toggle,
            button:has(#mobileMenuIcon) {
              background: #e3861c !important;
              background-image: none !important;
              color: #ffffff !important;
              border: none !important;
              box-shadow: 0 4px 14px rgba(227, 134, 28, 0.35) !important;
            }

            /* 3. New Complaint Pill Button */
            .btn-register-submit,
            a[href*="register"].btn,
            a:has([data-i18n="list_new_complaint"]) {
              background: #e3861c !important;
              background-image: none !important;
              color: #ffffff !important;
              border: none !important;
              box-shadow: 0 8px 24px rgba(227, 134, 28, 0.35) !important;
            }

            /* 4. Citizen Avatar Pill (Circle 'P' and Chevron) */
            .citizen-avatar,
            .citizen-user-btn .citizen-avatar {
              background: #e3861c !important;
              background-image: none !important;
              color: #ffffff !important;
              box-shadow: 0 3px 10px rgba(227, 134, 28, 0.35) !important;
            }
            .citizen-user-btn i,
            .citizen-user-btn .fa-chevron-down,
            .citizen-user-btn .text-orange {
              color: #e3861c !important;
            }

            /* 5. Profile Form Header (Pawan Kumar Prajapati) & Form Header Banners */
            .citizen-form-header,
            div:has(> .profile-avatar-circle) {
              background: #e3861c !important;
              background-image: none !important;
              color: #ffffff !important;
            }

            /* 6. Chatbot Header (KDA Citizen Assistant & Login Assistant) */
            .kda-chatbot-header,
            .login-chatbot-header,
            .kda-chatbot-panel .kda-chatbot-header,
            .login-chatbot-panel .login-chatbot-header {
              background: #e3861c !important;
              background-image: none !important;
              color: #ffffff !important;
            }

            /* 7. Dashboard Button Text & Icon Color (#e3861c) */
            .btn-hero-secondary,
            .btn-hero-secondary i,
            .btn-hero-secondary span,
            a.btn-hero-secondary,
            a:has([data-i18n="nav_dashboard"]),
            a:has(i.fa-home),
            a:has(i.fa-home) * {
              color: #e3861c !important;
            }
            .btn-hero-secondary {
              border-color: rgba(227, 134, 28, 0.3) !important;
              background: rgba(227, 134, 28, 0.08) !important;
            }

            /* 7b. Back Page Button (#e3861c background, white text & icon) */
            .btn-back-modern,
            a.btn-back-modern,
            a:has([data-i18n="track_back"]) {
              background: #e3861c !important;
              background-color: #e3861c !important;
              background-image: none !important;
              color: #ffffff !important;
              border: 1px solid #e3861c !important;
              border-radius: 30px !important;
              box-shadow: 0 4px 12px rgba(227, 134, 28, 0.25) !important;
            }
            .btn-back-modern i,
            .btn-back-modern span,
            a.btn-back-modern i,
            a.btn-back-modern span,
            a:has([data-i18n="track_back"]) * {
              color: #ffffff !important;
            }
            .btn-back-modern:hover,
            .btn-back-modern:active,
            .btn-back-modern:focus {
              background: #cf7313 !important;
              background-color: #cf7313 !important;
              color: #ffffff !important;
            }

            /* 8. Citizen Role Button / Badge */
            .badge.bg-orange,
            .bg-orange,
            [data-i18n="profile_citizen"],
            .account-info-pill .badge {
              background-color: #e3861c !important;
              background: #e3861c !important;
              background-image: none !important;
              color: #ffffff !important;
            }

            /* 9. Floating Chatbot Toggle Button & Icon */
            .kda-chatbot-toggle,
            #kda-chatbot-toggle,
            .login-chatbot-toggle,
            #login-chatbot-toggle {
              background: #e3861c !important;
              background-color: #e3861c !important;
              background-image: none !important;
              color: #ffffff !important;
              box-shadow: 0 8px 24px rgba(227, 134, 28, 0.35) !important;
            }
            .kda-chatbot-toggle i,
            .login-chatbot-toggle i {
              color: #ffffff !important;
            }

            /* General Orange Helpers */
            .btn-orange {
              background: #e3861c !important;
              background-image: none !important;
              color: #ffffff !important;
              border-color: #e3861c !important;
            }
            .text-orange {
              color: #e3861c !important;
            }

            /* Ensure Landing Hero Cards are fully visible as designed (Image 1) */
            .landing-hero-row,
            .hero-left,
            .hero-card,
            .mobile-register-complaint-box {
              display: block !important;
              visibility: visible !important;
            }

            /* Hide floating chatbot toggle while chatbot modal is open */
            .kda-chatbot-toggle.is-hidden,
            #login-chatbot-toggle.is-hidden,
            body:has(.kda-chatbot-panel.is-open) .kda-chatbot-toggle,
            body:has(.kda-chatbot-panel.is-open) #login-chatbot-toggle,
            body:has(.is-open) .kda-chatbot-toggle {
              display: none !important;
            }

            /* Single row notifications top bar (Strict 1 single horizontal row) */
            div:has(> #mark-all-read),
            div:has(#mark-all-read),
            div.d-flex:has(#mark-all-read),
            div.flex-wrap:has(#mark-all-read),
            .notif-top-bar {
              display: flex !important;
              flex-direction: row !important;
              flex-wrap: nowrap !important;
              align-items: center !important;
              justify-content: space-between !important;
              gap: 4px !important;
              width: 100% !important;
            }

            div:has(> #mark-all-read) > div,
            div:has(#mark-all-read) > div,
            div.d-flex:has(#mark-all-read) > div,
            .notif-top-bar > div {
              display: flex !important;
              align-items: center !important;
              gap: 4px !important;
              min-width: 0 !important;
              flex: 1 1 auto !important;
              overflow: hidden !important;
            }

            div:has(#mark-all-read) .btn-back-modern,
            div:has(#mark-all-read) a.btn,
            div:has(#mark-all-read) a[href*="dashboard"],
            .notif-top-bar .btn-back-modern {
              padding: 4px 8px !important;
              font-size: 11px !important;
              white-space: nowrap !important;
              flex-shrink: 0 !important;
              border-radius: 6px !important;
            }

            div:has(#mark-all-read) h4,
            .notif-top-bar h4 {
              font-size: 14px !important;
              margin-bottom: 0 !important;
              white-space: nowrap !important;
              overflow: visible !important;
              text-overflow: clip !important;
              min-width: 0 !important;
              display: flex !important;
              align-items: center !important;
              gap: 4px !important;
              flex-shrink: 0 !important;
            }

            div:has(#mark-all-read) h4 span,
            .notif-top-bar h4 span {
              white-space: nowrap !important;
              overflow: visible !important;
              text-overflow: clip !important;
            }

            #mark-all-read,
            .btn-outline-orange-pill {
              padding: 4px 8px !important;
              font-size: 11px !important;
              white-space: nowrap !important;
              flex-shrink: 0 !important;
              letter-spacing: -0.2px !important;
              background: #e3861c !important;
              background-color: #e3861c !important;
              background-image: none !important;
              color: #ffffff !important;
              border: 1px solid #e3861c !important;
              box-shadow: 0 3px 10px rgba(227, 134, 28, 0.3) !important;
            }
            #mark-all-read i,
            #mark-all-read span,
            .btn-outline-orange-pill i,
            .btn-outline-orange-pill span {
              color: #ffffff !important;
              margin-right: 2px !important;
            }

            /* SweetAlert Confirm Button & Warning Icon (#e3861c) */
            .swal2-confirm,
            button.swal2-confirm {
              background-color: #e3861c !important;
              background: #e3861c !important;
              border-color: #e3861c !important;
              color: #ffffff !important;
              box-shadow: 0 4px 14px rgba(227, 134, 28, 0.35) !important;
            }
            .swal2-icon.swal2-warning {
              border-color: #e3861c !important;
              color: #e3861c !important;
            }

            /* Dashboard Hero Welcome Badge & Border (#e3861c) */
            .hero-welcome-badge {
              background: rgba(227, 134, 28, 0.12) !important;
              color: #e3861c !important;
              border: 1px solid rgba(227, 134, 28, 0.35) !important;
            }
            .hero-welcome-badge i,
            .hero-welcome-badge span {
              color: #e3861c !important;
            }
            .citizen-hero {
              border-left: 5px solid #e3861c !important;
              border-color: rgba(227, 134, 28, 0.2) !important;
            }

            /* Hero Action Buttons - Single Horizontal Row & Fit Screen */
            .hero-btn-group,
            .citizen-hero div:has(> .btn-register),
            .citizen-hero div:has(> a[href*="register"]) {
              display: flex !important;
              flex-direction: row !important;
              flex-wrap: nowrap !important;
              align-items: center !important;
              gap: 6px !important;
              width: 100% !important;
              max-width: 100% !important;
            }
            .hero-btn-group .btn,
            .citizen-hero .btn-register,
            .citizen-hero .btn-hero-secondary,
            .citizen-hero a[href*="register"],
            .citizen-hero a[href*="complaints"] {
              flex: 1 1 50% !important;
              min-width: 0 !important;
              max-width: 50% !important;
              padding: 5px 3px !important;
              font-size: 10px !important;
              letter-spacing: -0.3px !important;
              white-space: nowrap !important;
              text-align: center !important;
              justify-content: center !important;
              overflow: hidden !important;
              text-overflow: ellipsis !important;
              box-sizing: border-box !important;
            }
            .hero-btn-group .btn i,
            .citizen-hero .btn-register i,
            .citizen-hero .btn-hero-secondary i {
              font-size: 9.5px !important;
              margin-right: 2px !important;
              flex-shrink: 0 !important;
            }
            .hero-btn-group .btn span,
            .citizen-hero .btn-register span,
            .citizen-hero .btn-hero-secondary span {
              overflow: hidden !important;
              text-overflow: ellipsis !important;
              white-space: nowrap !important;
              font-size: 10px !important;
              letter-spacing: -0.3px !important;
            }

            /* Notifications Center Empty State Icon (#e3861c) */
            .empty-icon-circle {
              background: rgba(227, 134, 28, 0.1) !important;
              border: 1.5px solid rgba(227, 134, 28, 0.25) !important;
            }
            .empty-icon-circle i,
            .citizen-empty-state .empty-icon-circle i,
            .fa-bell-slash {
              color: #e3861c !important;
            }

            /* Account Information Dark Mode */
            [data-theme="dark"] .account-info-pill {
              background-color: #0f172a !important;
              border-color: #334155 !important;
            }
            [data-theme="dark"] .account-info-pill .text-dark {
              color: #ffffff !important;
            }
            [data-theme="dark"] .account-info-pill .text-muted {
              color: #94a3b8 !important;
            }
            [data-theme="dark"] .bg-light {
              background-color: #0f172a !important;
              border-color: #334155 !important;
              color: #f8fafc !important;
            }

            /* SweetAlert2 Dark Mode */
            [data-theme="dark"] .swal2-popup,
            html[data-theme="dark"] .swal2-popup {
              background: #1e293b !important;
              color: #f8fafc !important;
              border: 1.5px solid #334155 !important;
            }
            [data-theme="dark"] .swal2-title,
            html[data-theme="dark"] .swal2-title {
              color: #ffffff !important;
            }
            [data-theme="dark"] .swal2-html-container,
            html[data-theme="dark"] .swal2-html-container {
              color: #cbd5e1 !important;
            }

            /* Timeline Dark Mode */
            [data-theme="dark"] .timeline-action {
              color: #f8fafc !important;
            }
            [data-theme="dark"] .timeline-time {
              color: #94a3b8 !important;
            }
            [data-theme="dark"] .timeline-by {
              color: #cbd5e1 !important;
            }
            [data-theme="dark"] .timeline-body {
              background: #0f172a !important;
              color: #e2e8f0 !important;
              border-left-color: #3b82f6 !important;
            }
          `;
          document.head.appendChild(style);
        }

        // 2. DOM cleaning: Remove departmental elements & their drawer containers
        document.querySelectorAll('a[href*="department"], [href*="department_login"], [href*="departmentlogin"], .dept-pro-icon-btn').forEach(function(el) {
          var parent = el.closest('.border-top') || el.parentElement;
          if (parent && (parent.classList.contains('border-top') || parent.classList.contains('pt-3'))) {
            parent.remove();
          } else {
            el.remove();
          }
        });

        // 2b. Hide 'Install App' / 'ऐप इंस्टॉल करें' menu item by class, attribute, and text
        document.querySelectorAll('.pwa-install-trigger, .pwa-install-nav-item, .pwa-install-divider, [data-i18n="nav_install_app"]').forEach(function(el) {
          var parentLi = el.closest('li') || el;
          var nextDivider = parentLi.nextElementSibling;
          if (nextDivider && (nextDivider.classList.contains('citizen-dropdown-divider') || nextDivider.classList.contains('pwa-install-divider') || nextDivider.querySelector('hr'))) {
            nextDivider.remove();
          }
          parentLi.remove();
        });
        var allElements = document.querySelectorAll('a, button, li, .dropdown-item');
        for (var k = 0; k < allElements.length; k++) {
          var txt = (allElements[k].textContent || '').trim();
          if (txt.indexOf('Install') !== -1 || txt.indexOf('इंस्टॉल') !== -1) {
            var parentLi = allElements[k].closest('li') || allElements[k];
            parentLi.style.setProperty('display', 'none', 'important');
            parentLi.style.setProperty('visibility', 'hidden', 'important');
            parentLi.remove();
          }
        }

        // 2c. Dark Mode logout fix: on login page, reset theme if saved as light
        var currentUrl = window.location.href;
        if (currentUrl.includes('/auth/login') || currentUrl.includes('/citizen/dashboard')) {
          var savedTheme = localStorage.getItem('sitetheme') || localStorage.getItem('theme') || 'light';
          if (savedTheme === 'light' || savedTheme === '') {
            document.documentElement.removeAttribute('data-theme');
            document.body.classList.remove('dark-mode');
          }
        }

        // 3. Scan mobile drawer items to purge any Departmental button text
        document.querySelectorAll('.mobile-drawer-body *').forEach(function(el) {
          if (el.textContent && (el.textContent.includes('Departmental Login') || el.textContent.includes('विभागीय लॉगिन'))) {
            var container = el.closest('.border-top') || el.closest('a') || el;
            if (container && container.parentNode) {
              container.remove();
            }
          }
        });

        // 4. Ensure chatbot toggle hides when modal opens and prevent keyboard popup
        var cbToggle = document.getElementById('kda-chatbot-toggle') || document.getElementById('login-chatbot-toggle');
        var cbPanel = document.getElementById('kda-chatbot-panel') || document.getElementById('login-chatbot-panel');
        var cbClose = document.getElementById('kda-chatbot-close') || document.getElementById('login-chatbot-close');
        var cbInput = document.getElementById('kda-chatbot-input') || document.getElementById('login-chatbot-input');
        if (cbToggle && cbPanel) {
          cbToggle.addEventListener('click', function() {
            setTimeout(function() {
              if (cbPanel.classList.contains('is-open')) {
                cbToggle.style.display = 'none';
                cbToggle.classList.add('is-hidden');
                if (cbInput && document.activeElement === cbInput) {
                  cbInput.blur();
                }
              }
            }, 30);
          }, true);
        }
        if (cbClose && cbToggle) {
          cbClose.addEventListener('click', function() {
            setTimeout(function() {
              cbToggle.style.display = '';
              cbToggle.classList.remove('is-hidden');
            }, 30);
          }, true);
        }

        // 5. Force Notifications Top Bar into strictly 1 single horizontal row
        function alignNotificationsSingleLine() {
          var markAllBtn = document.getElementById('mark-all-read');
          if (!markAllBtn) return;
          var parent = markAllBtn.closest('.d-flex') || markAllBtn.parentElement;
          if (!parent) return;

          parent.classList.remove('flex-wrap');
          parent.classList.add('flex-nowrap');
          parent.style.setProperty('display', 'flex', 'important');
          parent.style.setProperty('flex-direction', 'row', 'important');
          parent.style.setProperty('flex-wrap', 'nowrap', 'important');
          parent.style.setProperty('align-items', 'center', 'important');
          parent.style.setProperty('justify-content', 'space-between', 'important');
          parent.style.setProperty('gap', '4px', 'important');
          parent.style.setProperty('width', '100%', 'important');

          var firstDiv = parent.firstElementChild;
          if (firstDiv && firstDiv !== markAllBtn) {
            firstDiv.style.setProperty('display', 'flex', 'important');
            firstDiv.style.setProperty('align-items', 'center', 'important');
            firstDiv.style.setProperty('gap', '4px', 'important');
            firstDiv.style.setProperty('min-width', '0', 'important');
            firstDiv.style.setProperty('flex', '1 1 auto', 'important');
            firstDiv.style.setProperty('overflow', 'hidden', 'important');
          }

          var backBtn = parent.querySelector('a.btn, .btn-back-modern, a[href*="dashboard"]');
          if (backBtn) {
            var backSpan = backBtn.querySelector('span');
            if (backSpan && (backSpan.textContent.includes('पिछले') || backSpan.textContent.length > 5)) {
              backSpan.textContent = 'वापस';
            }
            backBtn.style.setProperty('padding', '3px 8px', 'important');
            backBtn.style.setProperty('font-size', '11px', 'important');
            backBtn.style.setProperty('white-space', 'nowrap', 'important');
            backBtn.style.setProperty('flex-shrink', '0', 'important');
            backBtn.style.setProperty('border-radius', '6px', 'important');
          }

          var h4 = parent.querySelector('h4');
          if (h4) {
            h4.style.setProperty('font-size', '13.5px', 'important');
            h4.style.setProperty('margin-bottom', '0', 'important');
            h4.style.setProperty('white-space', 'nowrap', 'important');
            h4.style.setProperty('overflow', 'visible', 'important');
            h4.style.setProperty('text-overflow', 'clip', 'important');
            h4.style.setProperty('min-width', '0', 'important');
            h4.style.setProperty('display', 'flex', 'important');
            h4.style.setProperty('align-items', 'center', 'important');
            h4.style.setProperty('gap', '3px', 'important');
            h4.style.setProperty('flex-shrink', '0', 'important');
            var h4Span = h4.querySelector('span');
            if (h4Span) {
              h4Span.style.setProperty('overflow', 'visible', 'important');
              h4Span.style.setProperty('text-overflow', 'clip', 'important');
              h4Span.style.setProperty('white-space', 'nowrap', 'important');
            }
          }

          markAllBtn.style.setProperty('padding', '4px 8px', 'important');
          markAllBtn.style.setProperty('font-size', '11px', 'important');
          markAllBtn.style.setProperty('white-space', 'nowrap', 'important');
          markAllBtn.style.setProperty('flex-shrink', '0', 'important');
        }

        // 5b. Force Hero action buttons to fit neatly on 1 horizontal row
        function alignHeroButtons() {
          var heroGroup = document.querySelector('.hero-btn-group');
          if (!heroGroup) return;
          heroGroup.style.setProperty('display', 'flex', 'important');
          heroGroup.style.setProperty('flex-direction', 'row', 'important');
          heroGroup.style.setProperty('flex-wrap', 'nowrap', 'important');
          heroGroup.style.setProperty('align-items', 'center', 'important');
          heroGroup.style.setProperty('gap', '6px', 'important');
          heroGroup.style.setProperty('width', '100%', 'important');

          var btns = heroGroup.querySelectorAll('.btn, a');
          for (var b = 0; b < btns.length; b++) {
            var btn = btns[b];
            btn.style.setProperty('flex', '1 1 50%', 'important');
            btn.style.setProperty('min-width', '0', 'important');
            btn.style.setProperty('max-width', '50%', 'important');
            btn.style.setProperty('padding', '5px 3px', 'important');
            btn.style.setProperty('font-size', '10px', 'important');
            btn.style.setProperty('letter-spacing', '-0.3px', 'important');
            btn.style.setProperty('white-space', 'nowrap', 'important');
            btn.style.setProperty('overflow', 'hidden', 'important');
            btn.style.setProperty('text-overflow', 'ellipsis', 'important');
            btn.style.setProperty('box-sizing', 'border-box', 'important');
            btn.style.setProperty('display', 'inline-flex', 'important');
            btn.style.setProperty('align-items', 'center', 'important');
            btn.style.setProperty('justify-content', 'center', 'important');

            var span = btn.querySelector('span');
            if (span) {
              span.style.setProperty('overflow', 'hidden', 'important');
              span.style.setProperty('text-overflow', 'ellipsis', 'important');
              span.style.setProperty('white-space', 'nowrap', 'important');
              span.style.setProperty('font-size', '10px', 'important');
              span.style.setProperty('letter-spacing', '-0.3px', 'important');
            }
            var icon = btn.querySelector('i');
            if (icon) {
              icon.style.setProperty('font-size', '9.5px', 'important');
              icon.style.setProperty('margin-right', '2px', 'important');
              icon.style.setProperty('flex-shrink', '0', 'important');
            }
          }
        }

        // 6. Force #e3861c solid color on target buttons, toggles, pills & headers
        function enforceAppColors() {
          var bgTargets = document.querySelectorAll('.mobile-open-auth-trigger, #mobileDropdownLoginBtn, #mobileMenuToggleBtn, .mobile-menu-toggle, .btn-register-submit, .citizen-avatar, .citizen-form-header, .btn-orange, a[href*="register"].btn, .kda-chatbot-header, .login-chatbot-header, .bg-orange, .badge.bg-orange, [data-i18n="profile_citizen"], .account-info-pill .badge, .kda-chatbot-toggle, #kda-chatbot-toggle, .login-chatbot-toggle, #login-chatbot-toggle, .btn-back-modern, a.btn-back-modern, a:has([data-i18n="track_back"])');
          for (var i = 0; i < bgTargets.length; i++) {
            bgTargets[i].style.setProperty('background-color', '#e3861c', 'important');
            bgTargets[i].style.setProperty('background', '#e3861c', 'important');
            bgTargets[i].style.setProperty('background-image', 'none', 'important');
            bgTargets[i].style.setProperty('border-color', '#e3861c', 'important');
          }
          var textTargets = document.querySelectorAll('.citizen-user-btn i, .citizen-user-btn .fa-chevron-down, .citizen-user-btn .text-orange, .text-orange, .btn-hero-secondary, .btn-hero-secondary i, .btn-hero-secondary span, a:has(i.fa-home), a:has(i.fa-home) *, a:has([data-i18n="nav_dashboard"]), a:has([data-i18n="nav_dashboard"]) *');
          for (var j = 0; j < textTargets.length; j++) {
            textTargets[j].style.setProperty('color', '#e3861c', 'important');
          }
          var whiteIconTargets = document.querySelectorAll('.kda-chatbot-toggle i, .login-chatbot-toggle i, .badge.bg-orange, [data-i18n="profile_citizen"], .btn-back-modern i, .btn-back-modern span, a.btn-back-modern i, a.btn-back-modern span, a:has([data-i18n="track_back"]) *');
          for (var w = 0; w < whiteIconTargets.length; w++) {
            whiteIconTargets[w].style.setProperty('color', '#ffffff', 'important');
          }
        }

        alignNotificationsSingleLine();
        alignHeroButtons();
        enforceAppColors();
        setTimeout(function() { alignNotificationsSingleLine(); alignHeroButtons(); enforceAppColors(); }, 50);
        setTimeout(function() { alignNotificationsSingleLine(); alignHeroButtons(); enforceAppColors(); }, 200);
        setTimeout(function() { alignNotificationsSingleLine(); alignHeroButtons(); enforceAppColors(); }, 600);
        setTimeout(function() { alignNotificationsSingleLine(); alignHeroButtons(); enforceAppColors(); }, 1200);

        if (window.MutationObserver && !window._notifSingleLineObserverSet) {
          window._notifSingleLineObserverSet = true;
          var obs = new MutationObserver(function() {
            alignNotificationsSingleLine();
            alignHeroButtons();
            enforceAppColors();
          });
          obs.observe(document.body, { childList: true, subtree: true });
        }
      })();
    """);
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (await _controller.canGoBack()) {
          _controller.goBack();
          return false;
        }
        return true;
      },
      child: Scaffold(
        body: SafeArea(
          child: Stack(
            children: [
              WebViewWidget(controller: _controller),
              if (_isLoading)
                LinearProgressIndicator(
                  value: _progress > 0 ? _progress : null,
                  backgroundColor: const Color(0xFFE2E8F0),
                  color: const Color(0xFFE3861C),
                  minHeight: 3,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

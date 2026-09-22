import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../config/api_config.dart';

class DepartmentWebPortalScreen extends StatefulWidget {
  final String? initialUrl;
  const DepartmentWebPortalScreen({super.key, this.initialUrl});

  @override
  State<DepartmentWebPortalScreen> createState() => _DepartmentWebPortalScreenState();
}

class _DepartmentWebPortalScreenState extends State<DepartmentWebPortalScreen> {
  static const _printChannel = MethodChannel('in.gov.rajasthan.kdakota.enivaran/print');
  late final WebViewController _controller;
  bool _isLoading = true;
  double _progress = 0;
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();

    final targetUrl = widget.initialUrl ?? ApiConfig.departmentLoginUrl;

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0F172A))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _progress = progress / 100;
                _isLoading = progress < 100;
              });
            }
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _hasError = false;
                _isLoading = true;
              });
            }
            _injectPortalModifications();
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() => _isLoading = false);
            }
            _injectPortalModifications();
          },
          onWebResourceError: (WebResourceError error) {
            // Only show error for main frame navigation failures
            if (error.isForMainFrame ?? true) {
              if (mounted) {
                setState(() {
                  _hasError = true;
                  _errorMessage = error.description;
                  _isLoading = false;
                });
              }
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            final url = request.url.toLowerCase();
            // Allow logout requests to proceed
            if (url.contains('/auth/logout')) {
              return NavigationDecision.navigate;
            }
            // If redirected to citizen login, smoothly transition to department login
            if (url.contains('/auth/login') && !url.contains('department')) {
              _controller.loadRequest(Uri.parse(ApiConfig.departmentLoginUrl));
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..addJavaScriptChannel(
        'FlutterPrintChannel',
        onMessageReceived: (JavaScriptMessage message) {
          _handlePrintMessage(message.message);
        },
      )
      ..loadRequest(Uri.parse(targetUrl));
  }

  DateTime? _lastPrintInvocationTime;

  void _handlePrintMessage(String payload) async {
    final now = DateTime.now();
    if (_lastPrintInvocationTime != null &&
        now.difference(_lastPrintInvocationTime!) < const Duration(seconds: 3)) {
      debugPrint("FlutterPrintChannel: duplicate print message dropped");
      return;
    }
    _lastPrintInvocationTime = now;

    try {
      final data = jsonDecode(payload) as Map<String, dynamic>;
      final action = data['action'] as String? ?? 'print';
      if (action == 'printComplaint') {
        await _printChannel.invokeMethod('printComplaint', data);
      } else {
        await _printChannel.invokeMethod('print', {
          'url': data['url'] as String? ?? ApiConfig.baseUrl,
          'title': data['title'] as String? ?? 'KDA-Complaint-Print',
        });
      }
    } catch (e) {
      debugPrint("FlutterPrintChannel error: $e");
    }
  }

  void _injectPortalModifications() {
    // Injected script handles:
    // 1. Native Android Print interception for window.print() and print buttons
    // 2. Completely removing 'Go to Citizen', 'Citizen Login', and 'Install App'
    // 3. Ensuring Dark Mode cards and Light Mode cards are razor-sharp with proper contrast
    // 4. Ensuring Status Chart has an elegant Empty State if count is 0
    _controller.runJavaScript(r"""
      (function() {
        // ── Window.print Interception for Native Android Print Spooler ──
        function extractComplaintData() {
          var data = {
            action: 'printComplaint',
            url: window.location.href,
            complaintNo: '',
            status: '',
            priority: '',
            title: '',
            description: '',
            slaDeadline: '',
            type: '',
            subType: '',
            zone: '',
            address: '',
            citizenName: '',
            citizenMobile: '',
            registeredOn: '',
            registeredBy: '',
            citizenPhotoBase64: '',
            citizenPhotoUrl: '',
            history: []
          };

          try {
            // Complaint No
            var titleEl = document.querySelector('.page-title, h1');
            if (titleEl) data.complaintNo = titleEl.textContent.trim();

            // Status & Priority badges
            var badges = document.querySelectorAll('.section-header .badge');
            badges.forEach(function(b) {
              var txt = b.textContent.trim();
              var cls = (b.className || '').toLowerCase();
              if (cls.indexOf('status-') !== -1 || (!data.status && txt.indexOf('Priority') === -1)) {
                data.status = txt;
              } else if (cls.indexOf('priority-') !== -1 || txt.indexOf('Priority') !== -1) {
                data.priority = txt;
              }
            });

            // Complaint Details Card
            var cards = document.querySelectorAll('.card');
            cards.forEach(function(card) {
              var headerEl = card.querySelector('.card-header, .card-title');
              var headerTxt = (headerEl ? headerEl.textContent : '').toLowerCase();
              if (headerTxt.indexOf('complaint details') !== -1) {
                var h5 = card.querySelector('h5');
                if (h5) data.title = h5.textContent.trim();

                var pDesc = card.querySelector('.card-body > p.text-muted, .card-body > p');
                if (pDesc) data.description = pDesc.textContent.trim();

                var detailItems = card.querySelectorAll('.detail-item');
                detailItems.forEach(function(item) {
                  var lblEl = item.querySelector('label');
                  var spanEl = item.querySelector('span');
                  var lbl = (lblEl ? lblEl.textContent : '').trim().toUpperCase();
                  var val = (spanEl ? spanEl.textContent : '').trim();
                  if (lbl.indexOf('COMPLAINT NO') !== -1 && val) data.complaintNo = val;
                  else if (lbl.indexOf('SLA') !== -1) data.slaDeadline = val;
                  else if (lbl.indexOf('SUB TYPE') !== -1) data.subType = val;
                  else if (lbl.indexOf('TYPE') !== -1) data.type = val;
                  else if (lbl.indexOf('ZONE') !== -1) data.zone = val;
                });

                var addrEl = card.querySelector('.card-body p:has(.fa-map-marker-alt), p i.fa-map-marker-alt');
                if (addrEl) {
                  var pParent = addrEl.closest('p');
                  if (pParent) {
                    data.address = pParent.textContent.trim().replace(/^Address\s*/i, '');
                  }
                }
              } else if (headerTxt.indexOf('citizen info') !== -1) {
                var detailItems = card.querySelectorAll('.detail-item');
                detailItems.forEach(function(item) {
                  var lblEl = item.querySelector('label');
                  var spanEl = item.querySelector('span');
                  var lbl = (lblEl ? lblEl.textContent : '').trim().toLowerCase();
                  var val = (spanEl ? spanEl.textContent : '').trim();
                  if (lbl.indexOf('name') !== -1) data.citizenName = val;
                  else if (lbl.indexOf('mobile') !== -1) {
                    var aCall = item.querySelector('a[href^="tel:"]');
                    data.citizenMobile = aCall ? aCall.textContent.trim() : val;
                  }
                });
              } else if (headerTxt.indexOf('timestamp') !== -1) {
                var detailItems = card.querySelectorAll('.detail-item');
                detailItems.forEach(function(item) {
                  var lblEl = item.querySelector('label');
                  var spanEl = item.querySelector('span');
                  var lbl = (lblEl ? lblEl.textContent : '').trim().toLowerCase();
                  var val = (spanEl ? spanEl.textContent : '').trim();
                  if (lbl.indexOf('registered on') !== -1) data.registeredOn = val;
                  else if (lbl.indexOf('registered by') !== -1) data.registeredBy = val;
                });
              } else if (headerTxt.indexOf('citizen') !== -1 || headerTxt.indexOf('submitted') !== -1) {
                var img = card.querySelector('img.kda-thumb, img');
                if (img && img.src) {
                  data.citizenPhotoUrl = img.src;
                  try {
                    var canvas = document.createElement('canvas');
                    canvas.width = img.naturalWidth || img.width || 300;
                    canvas.height = img.naturalHeight || img.height || 200;
                    var ctx = canvas.getContext('2d');
                    ctx.drawImage(img, 0, 0);
                    data.citizenPhotoBase64 = canvas.toDataURL('image/jpeg', 0.85);
                  } catch(e) {}
                }
              } else if (headerTxt.indexOf('history') !== -1) {
                var timelineItems = card.querySelectorAll('.timeline-item');
                timelineItems.forEach(function(item) {
                  var actEl = item.querySelector('.timeline-action');
                  var durEl = item.querySelector('.badge.bg-light, .badge');
                  var timEl = item.querySelector('.timeline-time');
                  var byEl = item.querySelector('.timeline-by');
                  var remEl = item.querySelector('.timeline-body');
                  var act = actEl ? actEl.textContent.trim() : '';
                  var dur = durEl ? durEl.textContent.trim() : '';
                  var tim = timEl ? timEl.textContent.trim() : '';
                  var by = byEl ? byEl.textContent.trim() : '';
                  var rem = remEl ? remEl.textContent.trim() : '';
                  if (act || tim || by) {
                    data.history.push({
                      action: act,
                      duration: dur,
                      time: tim,
                      by: by,
                      remarks: rem
                    });
                  }
                });
              }
            });

            // Fallback for photo if not found inside card
            if (!data.citizenPhotoUrl) {
              var anyImg = document.querySelector('.kda-gallery-item img, img.kda-thumb');
              if (anyImg && anyImg.src) {
                data.citizenPhotoUrl = anyImg.src;
                try {
                  var canvas = document.createElement('canvas');
                  canvas.width = anyImg.naturalWidth || anyImg.width || 300;
                  canvas.height = anyImg.naturalHeight || anyImg.height || 200;
                  var ctx = canvas.getContext('2d');
                  ctx.drawImage(anyImg, 0, 0);
                  data.citizenPhotoBase64 = canvas.toDataURL('image/jpeg', 0.85);
                } catch(e) {}
              }
            }
          } catch(err) {
            console.error('Data extract error:', err);
          }

          return data;
        }

        if (!window.__kda_print_interceptor_installed) {
          window.__kda_print_interceptor_installed = true;

          var _lastPrintTimestamp = 0;
          function triggerNativePrint() {
            var now = Date.now();
            if (now - _lastPrintTimestamp < 3000) {
              return;
            }
            _lastPrintTimestamp = now;

            try {
              var data = extractComplaintData();
              if (window.FlutterPrintChannel) {
                window.FlutterPrintChannel.postMessage(JSON.stringify(data));
              }
            } catch(e) {
              console.error('Trigger print error:', e);
            }
          }

          window.print = triggerNativePrint;

          // Attach delegated listener on all print buttons and links (only once)
          document.addEventListener('click', function(e) {
            var btn = e.target.closest('button, a, .btn');
            if (btn) {
              var onclickAttr = (btn.getAttribute('onclick') || '').toLowerCase();
              var txt = (btn.textContent || '').toLowerCase();
              var hasPrintIcon = btn.querySelector('.fa-print, .fas.fa-print, [class*="print"]');
              if (onclickAttr.indexOf('print') !== -1 || txt.indexOf('print') !== -1 || hasPrintIcon) {
                e.preventDefault();
                e.stopPropagation();
                triggerNativePrint();
              }
            }
          }, true);
        }
        // 1. Hide Citizen Login and Install App items
        var citizenElements = document.querySelectorAll(
          'a[href*="/auth/login"]:not([href*="department"]), ' +
          'a[href*="citizen_app"], ' +
          '#installPwaBtn, ' +
          '#installAppNavBtn, ' +
          '.install-app-btn, ' +
          '.btn-outline-primary[href*="login"]'
        );
        for (var i = 0; i < citizenElements.length; i++) {
          citizenElements[i].style.display = 'none';
        }

        // Hide profile dropdown items that lead to citizen or install app
        var dropdownLinks = document.querySelectorAll('.dropdown-menu a');
        for (var j = 0; j < dropdownLinks.length; j++) {
          var txt = (dropdownLinks[j].textContent || '').toLowerCase();
          var h = (dropdownLinks[j].getAttribute('href') || '').toLowerCase();
          if (txt.includes('citizen') || txt.includes('install app') || 
              (h.includes('/auth/login') && !h.includes('department'))) {
            dropdownLinks[j].style.display = 'none';
          }
        }

        // 2. Inject CSS for flawless Dark Mode contrast and mobile responsiveness
        var styleId = 'kda-department-flutter-css';
        if (!document.getElementById(styleId)) {
          var style = document.createElement('style');
          style.id = styleId;
          style.innerHTML = `
            /* Hide citizen switcher */
            a[href*="/auth/login"]:not([href*="department"]),
            #installPwaBtn, #installAppNavBtn {
              display: none !important;
            }
            /* ═════ DARK MODE FORM CONTROLS & CONTRAST FIXES ═════ */
            html[data-theme='dark'] .card,
            body.dark-mode .card,
            [data-bs-theme='dark'] .card,
            [data-theme='dark'] .card {
              background: #1e293b !important;
              color: #f8fafc !important;
              border-color: #334155 !important;
            }
            html[data-theme='dark'] .card h1,
            html[data-theme='dark'] .card h2,
            html[data-theme='dark'] .card h3,
            html[data-theme='dark'] .card h4,
            html[data-theme='dark'] .card h5,
            html[data-theme='dark'] .card h6,
            html[data-theme='dark'] .card p,
            html[data-theme='dark'] .card label {
              color: #f8fafc !important;
            }

            /* Global Input & Form Control Dark Mode Fixes */
            [data-theme='dark'] .form-control,
            [data-theme='dark'] .form-select,
            [data-theme='dark'] input.form-control,
            [data-theme='dark'] textarea.form-control,
            [data-theme='dark'] select.form-select,
            [data-theme='dark'] input[type="text"],
            [data-theme='dark'] input[type="email"],
            [data-theme='dark'] input[type="password"],
            [data-theme='dark'] input[type="tel"],
            [data-theme='dark'] input[type="number"],
            [data-theme='dark'] textarea,
            html[data-theme='dark'] .form-control,
            html[data-theme='dark'] textarea,
            body.dark-mode .form-control,
            body.dark-mode textarea {
              background-color: #0f172a !important;
              border: 1.5px solid #334155 !important;
              color: #f8fafc !important;
              caret-color: #e3861c !important;
            }

            [data-theme='dark'] .form-control:focus,
            [data-theme='dark'] textarea:focus,
            html[data-theme='dark'] .form-control:focus,
            body.dark-mode .form-control:focus {
              background-color: #0b1120 !important;
              border-color: #e3861c !important;
              color: #ffffff !important;
              box-shadow: 0 0 0 3px rgba(255, 107, 0, 0.25) !important;
            }

            [data-theme='dark'] .form-control::placeholder,
            [data-theme='dark'] textarea::placeholder,
            html[data-theme='dark'] .form-control::placeholder,
            body.dark-mode .form-control::placeholder {
              color: #94a3b8 !important;
              opacity: 1 !important;
            }

            [data-theme='dark'] .form-control[readonly],
            [data-theme='dark'] .form-control:disabled,
            html[data-theme='dark'] .form-control[readonly],
            body.dark-mode .form-control[readonly] {
              background-color: #0f172a !important;
              border-color: #334155 !important;
              color: #cbd5e1 !important;
              opacity: 0.85 !important;
            }

            [data-theme='dark'] .form-label,
            [data-theme='dark'] label,
            html[data-theme='dark'] .form-label,
            body.dark-mode .form-label {
              color: #e2e8f0 !important;
              font-weight: 600 !important;
            }

            /* Image 1: Phone input container */
            [data-theme='dark'] .custom-phone-input,
            html[data-theme='dark'] .custom-phone-input,
            body.dark-mode .custom-phone-input {
              background: #0f172a !important;
              border: 1.5px solid #334155 !important;
              border-radius: 12px !important;
            }

            [data-theme='dark'] .custom-phone-input:focus-within,
            html[data-theme='dark'] .custom-phone-input:focus-within,
            body.dark-mode .custom-phone-input:focus-within {
              border-color: #e3861c !important;
              box-shadow: 0 0 0 3px rgba(255, 107, 0, 0.25) !important;
            }

            [data-theme='dark'] .custom-phone-input .country-code,
            html[data-theme='dark'] .custom-phone-input .country-code,
            body.dark-mode .custom-phone-input .country-code {
              background: #0f172a !important;
              border-right: 1px solid #334155 !important;
              color: #e3861c !important;
            }

            [data-theme='dark'] .custom-phone-input .phone-field,
            [data-theme='dark'] .custom-phone-input .form-control,
            [data-theme='dark'] .custom-phone-input input,
            html[data-theme='dark'] .custom-phone-input input,
            body.dark-mode .custom-phone-input input {
              background: transparent !important;
              color: #ffffff !important;
              caret-color: #e3861c !important;
            }

            [data-theme='dark'] .custom-phone-input .phone-field::placeholder,
            html[data-theme='dark'] .custom-phone-input .phone-field::placeholder,
            body.dark-mode .custom-phone-input .phone-field::placeholder {
              color: #94a3b8 !important;
              opacity: 1 !important;
            }

            [data-theme='dark'] .custom-phone-input .phone-icon,
            html[data-theme='dark'] .custom-phone-input .phone-icon,
            body.dark-mode .custom-phone-input .phone-icon {
              background: transparent !important;
              color: #94a3b8 !important;
            }

            /* Image 2: Role selection buttons */
            [data-theme='dark'] .role-select-card,
            html[data-theme='dark'] .role-select-card,
            body.dark-mode .role-select-card {
              background: #0f172a !important;
              border: 1.5px solid #334155 !important;
              color: #f8fafc !important;
              box-shadow: 0 4px 12px rgba(0, 0, 0, 0.25) !important;
            }

            [data-theme='dark'] .role-select-card span,
            [data-theme='dark'] .role-select-card div,
            html[data-theme='dark'] .role-select-card span,
            html[data-theme='dark'] .role-select-card div,
            body.dark-mode .role-select-card span,
            body.dark-mode .role-select-card div {
              color: #f8fafc !important;
              font-weight: 700 !important;
            }

            [data-theme='dark'] .role-select-card:hover,
            html[data-theme='dark'] .role-select-card:hover,
            body.dark-mode .role-select-card:hover {
              background: rgba(255, 107, 0, 0.15) !important;
              border-color: #e3861c !important;
              color: #e3861c !important;
              transform: translateY(-2px) !important;
            }

            [data-theme='dark'] .role-select-card:hover span,
            html[data-theme='dark'] .role-select-card:hover span,
            body.dark-mode .role-select-card:hover span {
              color: #e3861c !important;
            }

            [data-theme='dark'] .role-select-card .role-card-badge,
            html[data-theme='dark'] .role-select-card .role-card-badge,
            body.dark-mode .role-select-card .role-card-badge {
              background: rgba(255, 107, 0, 0.18) !important;
              color: #e3861c !important;
            }

            [data-theme='dark'] .role-select-card:hover .role-card-badge,
            html[data-theme='dark'] .role-select-card:hover .role-card-badge,
            body.dark-mode .role-select-card:hover .role-card-badge {
              background: #e3861c !important;
              color: #ffffff !important;
            }

            /* SweetAlert Confirm Button Exact #e3861c */
            .swal2-confirm,
            button.swal2-confirm,
            .swal2-styled.swal2-confirm,
            div:where(.swal2-container) button:where(.swal2-styled):where(.swal2-confirm) {
              background: #e3861c !important;
              background-color: #e3861c !important;
              color: #ffffff !important;
              border: none !important;
              box-shadow: 0 4px 14px rgba(227, 134, 28, 0.4) !important;
            }

            /* Card Top Accent Bar */
            .card-top-accent-line,
            .citizen-form-card > div:first-child,
            div[style*="height: 6px"],
            div[style*="height:6px"] {
              background: #e3861c !important;
              background-color: #e3861c !important;
            }

            /* User Info Card & Mobile Number Text (Password Step) */
            [data-theme='dark'] .user-info-card,
            html[data-theme='dark'] .user-info-card,
            body.dark-mode .user-info-card,
            .user-info-card {
              background: #0f172a !important;
              border: 1.5px solid #334155 !important;
            }

            [data-theme='dark'] .user-info-card .user-info-value,
            [data-theme='dark'] #staff-mobile-display,
            [data-theme='dark'] .user-info-value,
            html[data-theme='dark'] .user-info-card .user-info-value,
            html[data-theme='dark'] #staff-mobile-display,
            html[data-theme='dark'] .user-info-value,
            body.dark-mode .user-info-card .user-info-value,
            body.dark-mode #staff-mobile-display,
            body.dark-mode .user-info-value,
            #staff-mobile-display,
            .user-info-card .user-info-value {
              color: #ffffff !important;
              font-weight: 800 !important;
            }

            [data-theme='dark'] .user-info-card .user-info-label,
            html[data-theme='dark'] .user-info-card .user-info-label,
            body.dark-mode .user-info-card .user-info-label,
            .user-info-card .user-info-label {
              color: #cbd5e1 !important;
              font-weight: 700 !important;
            }

            /* Role Display Badge */
            .user-info-card .badge-role-tag,
            #staff-role-display,
            .badge-role-tag {
              color: #ffffff !important;
              background: rgba(227, 134, 28, 0.25) !important;
              border: 1px solid rgba(227, 134, 28, 0.6) !important;
              padding: 5px 12px !important;
              border-radius: 8px !important;
              font-size: 12px !important;
              font-weight: 700 !important;
              text-align: right !important;
              display: inline-block !important;
              line-height: 1.4 !important;
            }

            /* Mobile Logo Subtitle */
            .mobile-logo-subtitle {
              color: #cbd5e1 !important;
              display: block !important;
              opacity: 0.95 !important;
              font-size: 11.5px !important;
            }
            /* Department Badge Styling */
            .dept-mobile-badge {
              display: inline-block;
              background: #e3861c !important;
              color: #fff !important;
              padding: 3px 8px;
              border-radius: 6px;
              font-size: 11px;
              font-weight: 700;
              margin-left: 6px;
            }
            /* Mobile drawer header badges text visibility */
            .mobile-nav-dropdown .header-badge,
            .mobile-drawer-body .header-badge,
            .mobile-drawer-badge {
              background: rgba(255, 255, 255, 0.08) !important;
              color: #ffffff !important;
              border: 1px solid rgba(255, 255, 255, 0.15) !important;
              border-radius: 12px !important;
            }
            .mobile-nav-dropdown .header-badge span,
            .mobile-drawer-body .header-badge span,
            .mobile-drawer-badge span,
            .mobile-nav-dropdown .header-badge *,
            .mobile-drawer-body .header-badge * {
              color: #ffffff !important;
              font-weight: 700 !important;
            }
            .mobile-nav-dropdown .header-badge i,
            .mobile-drawer-body .header-badge i,
            .mobile-drawer-badge i {
              color: #e3861c !important;
            }
            .mobile-nav-dropdown .header-lang-switch,
            .mobile-drawer-body .header-lang-switch {
              background: rgba(255, 255, 255, 0.08) !important;
              border: 1px solid rgba(255, 255, 255, 0.15) !important;
              border-radius: 12px !important;
            }
            .mobile-nav-dropdown .header-lang-btn,
            .mobile-drawer-body .header-lang-btn {
              color: #cbd5e1 !important;
            }
            .mobile-nav-dropdown .header-lang-btn.active,
            .mobile-drawer-body .header-lang-btn.active {
              background: #e3861c !important;
              color: #ffffff !important;
            }

            /* Global Department Portal #e3861c brand color overrides */
            /* Global Department Portal #e3861c brand color overrides */
            :root {
              --primary: #e3861c !important;
              --bs-primary: #e3861c !important;
              --primary-color: #e3861c !important;
            }

            /* 1. Continue Button - Exact Match #e3861c */
            #btn-staff-continue,
            .btn-register-submit,
            button:has([data-i18n="continue_btn"]),
            button:has(.fa-paper-plane),
            #btn-send-otp,
            .btn-continue {
              background: #e3861c !important;
              background-color: #e3861c !important;
              background-image: none !important;
              border: none !important;
              color: #ffffff !important;
              box-shadow: 0 4px 16px rgba(227, 134, 28, 0.4) !important;
            }
            #btn-staff-continue:hover,
            #btn-staff-continue:focus,
            #btn-staff-continue:active,
            .btn-register-submit:hover,
            .btn-register-submit:focus,
            .btn-register-submit:active {
              background: #cf7313 !important;
              background-color: #cf7313 !important;
              background-image: none !important;
              color: #ffffff !important;
            }

            /* 2. Mobile Menu Bar Toggle Button - Exact Match #e3861c */
            #mobileMenuToggleBtn,
            .mobile-menu-toggle,
            button:has(#mobileMenuIcon),
            button:has(i.fa-bars) {
              background: #e3861c !important;
              background-color: #e3861c !important;
              background-image: none !important;
              border: none !important;
              color: #ffffff !important;
              box-shadow: 0 4px 14px rgba(227, 134, 28, 0.35) !important;
            }
            #mobileMenuToggleBtn i,
            .mobile-menu-toggle i,
            #mobileMenuIcon {
              color: #ffffff !important;
            }

            /* 3. Departmental Icon & Card Accent */
            .rounded-circle:has(> i.fa-building),
            div:has(> i.fa-building) {
              background: #e3861c !important;
              background-color: #e3861c !important;
              background-image: none !important;
              box-shadow: 0 4px 14px rgba(227, 134, 28, 0.35) !important;
            }

            .btn-primary, .btn-primary:focus, .btn-primary:active,
            .btn-hero-primary, .btn-modern-primary,
            button[type="submit"], input[type="submit"],
            .bg-primary, .bg-orange, .btn-orange {
              background: #e3861c !important;
              background-color: #e3861c !important;
              background-image: none !important;
              border-color: #e3861c !important;
              color: #ffffff !important;
            }
            .text-orange, .text-primary {
              color: #e3861c !important;
            }
          `;
          document.head.appendChild(style);
        }

        // Apply direct inline styling for Continue button & Menu toggle
        function applyDeptColors() {
          var continueBtn = document.getElementById('btn-staff-continue');
          if (continueBtn) {
            continueBtn.style.setProperty('background', '#e3861c', 'important');
            continueBtn.style.setProperty('background-color', '#e3861c', 'important');
            continueBtn.style.setProperty('background-image', 'none', 'important');
            continueBtn.style.setProperty('box-shadow', '0 4px 16px rgba(227, 134, 28, 0.4)', 'important');
            continueBtn.style.setProperty('color', '#ffffff', 'important');
          }
          var menuBtn = document.getElementById('mobileMenuToggleBtn');
          if (menuBtn) {
            menuBtn.style.setProperty('background', '#e3861c', 'important');
            menuBtn.style.setProperty('background-color', '#e3861c', 'important');
            menuBtn.style.setProperty('background-image', 'none', 'important');
            menuBtn.style.setProperty('box-shadow', '0 4px 14px rgba(227, 134, 28, 0.35)', 'important');
            menuBtn.style.setProperty('color', '#ffffff', 'important');
          }
          var allBtns = document.querySelectorAll('button, .btn');
          for (var b = 0; b < allBtns.length; b++) {
            var bTxt = (allBtns[b].textContent || '').trim();
            if (bTxt === 'Continue' || bTxt === 'आगे बढ़ें') {
              allBtns[b].style.setProperty('background', '#e3861c', 'important');
              allBtns[b].style.setProperty('background-color', '#e3861c', 'important');
              allBtns[b].style.setProperty('background-image', 'none', 'important');
              allBtns[b].style.setProperty('box-shadow', '0 4px 16px rgba(227, 134, 28, 0.4)', 'important');
              allBtns[b].style.setProperty('color', '#ffffff', 'important');
            }
          }
          var buildingIcons = document.querySelectorAll('.fa-building');
          for (var k = 0; k < buildingIcons.length; k++) {
            var parentCircle = buildingIcons[k].closest('.rounded-circle') || buildingIcons[k].parentElement;
            if (parentCircle) {
              parentCircle.style.setProperty('background', '#e3861c', 'important');
              parentCircle.style.setProperty('background-color', '#e3861c', 'important');
              parentCircle.style.setProperty('background-image', 'none', 'important');
            }
          }

          // Card accent line
          var topLines = document.querySelectorAll('.card-top-accent-line, div[style*="height: 6px"], div[style*="height:6px"]');
          for (var tl = 0; tl < topLines.length; tl++) {
            topLines[tl].style.setProperty('background', '#e3861c', 'important');
            topLines[tl].style.setProperty('background-color', '#e3861c', 'important');
          }

          // Role display and user info card text
          var roleDisp = document.getElementById('staff-role-display');
          if (roleDisp) {
            roleDisp.style.setProperty('color', '#ffffff', 'important');
            roleDisp.style.setProperty('background', 'rgba(227, 134, 28, 0.25)', 'important');
            roleDisp.style.setProperty('border', '1px solid rgba(227, 134, 28, 0.6)', 'important');
          }
          var mobDisp = document.getElementById('staff-mobile-display');
          if (mobDisp) {
            mobDisp.style.setProperty('color', '#ffffff', 'important');
          }
          var swalConfirms = document.querySelectorAll('.swal2-confirm, button.swal2-confirm');
          for (var sc = 0; sc < swalConfirms.length; sc++) {
            swalConfirms[sc].style.setProperty('background-color', '#e3861c', 'important');
            swalConfirms[sc].style.setProperty('background', '#e3861c', 'important');
            swalConfirms[sc].style.setProperty('border', 'none', 'important');
            swalConfirms[sc].style.setProperty('color', '#ffffff', 'important');
          }
          var logoSubs = document.querySelectorAll('.mobile-logo-subtitle');
          for (var ls = 0; ls < logoSubs.length; ls++) {
            logoSubs[ls].style.setProperty('color', '#cbd5e1', 'important');
            logoSubs[ls].style.setProperty('display', 'block', 'important');
          }
        }
        applyDeptColors();
        setInterval(applyDeptColors, 400);

        // 3. Fix Empty Chart state if canvas has 0 items
        var chartCanvas = document.getElementById('statusChart');
        if (chartCanvas) {
          var parentCard = chartCanvas.closest('.card') || chartCanvas.parentElement;
          if (parentCard && (!chartCanvas.dataset.rendered || chartCanvas.clientHeight < 30)) {
            var emptyBox = parentCard.querySelector('.chart-empty-state');
            if (!emptyBox) {
              emptyBox = document.createElement('div');
              emptyBox.className = 'chart-empty-state text-center p-3';
              emptyBox.innerHTML = '<div style="font-size:32px;margin-bottom:8px">📊</div><div style="font-weight:600;font-size:14px;color:#94a3b8">All Grievances Addressed</div><div style="font-size:12px;color:#64748b">No active complaints pending in queue</div>';
              chartCanvas.style.display = 'none';
              chartCanvas.parentNode.appendChild(emptyBox);
            }
          }
        }
      })();
    """);
  }

  void _showHostSettingsDialog() {
    final controller = TextEditingController(text: ApiConfig.baseUrl);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.dns, color: Color(0xFFE3861C)),
            SizedBox(width: 8),
            Text("Department Host URL", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Configure backend host URL for department portal:",
              style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: "https://kdakota.rajasthan.gov.in/enivaran",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                prefixIcon: const Icon(Icons.link, size: 20),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              ),
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel", style: TextStyle(color: Color(0xFF64748B))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE3861C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final newUrl = controller.text.trim();
              if (newUrl.isNotEmpty) {
                await ApiConfig.updateBaseUrl(newUrl);
                if (mounted) {
                  Navigator.pop(ctx);
                  _controller.loadRequest(Uri.parse(ApiConfig.departmentLoginUrl));
                }
              }
            },
            child: const Text("Save & Reload"),
          ),
        ],
      ),
    );
  }

  Future<bool> _handleWillPop() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _handleWillPop,
      child: Scaffold(
        backgroundColor: const Color(0xFF0F172A),
        body: SafeArea(
          child: RefreshIndicator(
            color: const Color(0xFFE3861C),
            onRefresh: () async {
              await _controller.reload();
            },
            child: Stack(
              children: [
                if (!_hasError)
                  WebViewWidget(controller: _controller)
                else
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: const Color(0xFF1E293B),
                              shape: BoxShape.circle,
                              border: Border.all(color: const Color(0xFF334155)),
                            ),
                            child: const Icon(Icons.wifi_off, size: 48, color: Color(0xFFEF4444)),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "Unable to Connect to Portal",
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _errorMessage.isNotEmpty
                                ? _errorMessage
                                : "Please check your network connection or verify server host.",
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
                          ),
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  side: const BorderSide(color: Color(0xFF475569)),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: _showHostSettingsDialog,
                                icon: const Icon(Icons.settings, size: 18),
                                label: const Text("Host URL"),
                              ),
                              const SizedBox(width: 12),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE3861C),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _hasError = false;
                                    _isLoading = true;
                                  });
                                  _controller.reload();
                                },
                                icon: const Icon(Icons.refresh, size: 18),
                                label: const Text("Retry"),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                if (_isLoading)
                  LinearProgressIndicator(
                    value: _progress > 0 ? _progress : null,
                    backgroundColor: const Color(0xFF1E293B),
                    color: const Color(0xFFE3861C),
                    minHeight: 3,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

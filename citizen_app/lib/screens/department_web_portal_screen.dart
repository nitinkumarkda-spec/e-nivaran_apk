import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../config/api_config.dart';

class DepartmentWebPortalScreen extends StatefulWidget {
  final String? initialUrl;
  const DepartmentWebPortalScreen({super.key, this.initialUrl});

  @override
  State<DepartmentWebPortalScreen> createState() => _DepartmentWebPortalScreenState();
}

class _DepartmentWebPortalScreenState extends State<DepartmentWebPortalScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  double _progress = 0;
  bool _hasError = false;
  String _errorMessage = '';
  DateTime? _lastBackPressTime;

  @override
  void initState() {
    super.initState();

    final targetUrl = widget.initialUrl ?? "${ApiConfig.baseUrl}/auth/department-login?dept_app=1";

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
            if (url.contains('/auth/logout')) {
              return NavigationDecision.navigate;
            }
            if (url.contains('/auth/login') && !url.contains('department')) {
              _controller.loadRequest(Uri.parse("${ApiConfig.baseUrl}/auth/department-login?dept_app=1"));
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(targetUrl));
  }

  void _injectPortalModifications() {
    _controller.runJavaScript(r"""
      (function() {
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

        var dropdownLinks = document.querySelectorAll('.dropdown-menu a');
        for (var j = 0; j < dropdownLinks.length; j++) {
          var txt = (dropdownLinks[j].textContent || '').toLowerCase();
          var h = (dropdownLinks[j].getAttribute('href') || '').toLowerCase();
          if (txt.includes('citizen') || txt.includes('install app') || 
              (h.includes('/auth/login') && !h.includes('department'))) {
            dropdownLinks[j].style.display = 'none';
          }
        }

        var styleId = 'kda-department-flutter-css';
        if (!document.getElementById(styleId)) {
          var style = document.createElement('style');
          style.id = styleId;
          style.innerHTML = `
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
            }

            [data-theme='dark'] .user-info-card .user-info-label,
            html[data-theme='dark'] .user-info-card .user-info-label,
            body.dark-mode .user-info-card .user-info-label {
              color: #94a3b8 !important;
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
              background: linear-gradient(135deg, #e3861c 0%, #ea580c 100%) !important;
              color: #ffffff !important;
            }
          `;
          document.head.appendChild(style);
        }

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

  Future<bool> _handleWillPop() async {
    if (await _controller.canGoBack()) {
      _controller.goBack();
      return false;
    }

    final now = DateTime.now();
    if (_lastBackPressTime == null || now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Press back again to exit KDA Department App"),
          duration: Duration(seconds: 2),
        ),
      );
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
          child: Stack(
            children: [
              if (!_hasError)
                WebViewWidget(controller: _controller)
              else
                Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.wifi_off, size: 48, color: Color(0xFFEF4444)),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage.isNotEmpty ? _errorMessage : "Unable to connect",
                        style: const TextStyle(color: Colors.white70),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          setState(() {
                            _hasError = false;
                            _isLoading = true;
                          });
                          _controller.reload();
                        },
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                ),
              if (_isLoading)
                LinearProgressIndicator(
                  value: _progress > 0 ? _progress : null,
                  backgroundColor: const Color(0xFF1E293B),
                  color: const Color(0xFFD9531E),
                  minHeight: 3,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

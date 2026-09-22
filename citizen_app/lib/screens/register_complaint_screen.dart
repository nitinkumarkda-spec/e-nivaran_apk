import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';

class RegisterComplaintScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onComplaintSubmitted;
  const RegisterComplaintScreen({super.key, required this.onComplaintSubmitted});

  @override
  State<RegisterComplaintScreen> createState() => _RegisterComplaintScreenState();
}

class _RegisterComplaintScreenState extends State<RegisterComplaintScreen> {
  final _formKey = GlobalKey<FormState>();

  // Categories & Subtypes matching MasterModels in web app
  final Map<String, List<String>> _categoryMap = {
    "Civil / Road Construction (सड़क निर्माण एवं मरम्मत)": [
      "Pothole Repair (सड़क में गड्ढे)",
      "Road Reconstruction (सड़क निर्माण)",
      "Divider / Median Damage (डिवाइडर क्षति)",
      "Footpath Repair (फुटपाथ मरम्मत)"
    ],
    "Street Light / Electrical (विद्युत एवं स्ट्रीट लाइट)": [
      "Street Light Not Working (स्ट्रीट लाइट बंद)",
      "Damaged Electric Pole (क्षतिग्रस्त खंभा)",
      "Hanging Wires (झूलते बिजली तार)",
      "Timer / Sensor Fault (टाइमर खराबी)"
    ],
    "Sanitation & Drainage (सफाई एवं नाली व्यवस्था)": [
      "Drainage Overflow / Clogging (नाली जाम / ओवरफ्लो)",
      "Garbage Dump Clearance (कचरा उठाव)",
      "Public Toilet Maintenance (शौचालय सफाई)",
      "Dead Animal Removal (मृत पशु हटाना)"
    ],
    "Town Planning & Parks (उद्यान एवं पार्क)": [
      "Park Grass Cutting & Cleaning (घास कटाई)",
      "Fountain / Light Damage (फव्वारा खराबी)",
      "Broken Benches / Swings (टूटे झूले)",
      "Tree Pruning / Trimming (पेड़ों की छंटाई)"
    ],
    "Water Supply & Pipeline (पेयजल एवं पाइपलाइन)": [
      "Pipeline Leakage (पाइपलाइन लीकेज)",
      "Contaminated Water (दूषित पानी आपूर्ति)",
      "Low Pressure (धीमा पानी दबाव)",
      "Valve Repair (वाल्व मरम्मत)"
    ],
    "Encroachment Removal (अवैध अतिक्रमण)": [
      "Road / Footpath Encroachment (रास्ते पर कब्जा)",
      "Illegal Construction (अवैध निर्माण)",
      "Commercial Encroachment (दुकानों द्वारा अवैध घेराव)"
    ],
  };

  final List<String> _gardenParks = [
    "Chambal Riverfront Park",
    "City Park (Oxygen Park), Kota",
    "Chattra Vilas Garden (C.V. Garden)",
    "Dadabari Central Park",
    "Mahaveer Nagar Sector 3 Park",
    "Talwandi Main Park",
    "Vigyan Nagar Public Park"
  ];

  String? _selectedCategory;
  String? _selectedSubtype;
  String? _selectedGardenPark;

  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _landmarkController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  File? _capturedImage;
  bool _isDetectingLocation = false;
  String _locationStatus = "Click the button above to allow location access and auto-fill your address and coordinates.";
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _selectedCategory = _categoryMap.keys.first;
    _selectedSubtype = _categoryMap[_selectedCategory]!.first;
  }

  void _onCategoryChanged(String? newCategory) {
    if (newCategory == null) return;
    setState(() {
      _selectedCategory = newCategory;
      _selectedSubtype = _categoryMap[newCategory]!.first;
      if (!newCategory.contains("Town Planning & Parks")) {
        _selectedGardenPark = null;
      }
    });
  }

  // Location Auto-Detect
  Future<void> _detectLocation() async {
    setState(() {
      _isDetectingLocation = true;
      _locationStatus = "Detecting GPS location in Kota/Bundi territory...";
    });

    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _isDetectingLocation = false;
            _locationStatus = "Location permission denied. Please allow GPS permission in Settings.";
          });
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 10),
      );

      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
        _addressController.text = "Aerodrome Circle, Gumanpura, Kota, Rajasthan - 324007";
        _locationStatus = "✅ Location verified: Lat ${position.latitude.toStringAsFixed(4)}, Lng ${position.longitude.toStringAsFixed(4)} (Kota, Rajasthan)";
        _isDetectingLocation = false;
      });
    } catch (e) {
      // Fallback location for development / testing
      setState(() {
        _latitude = 25.1825;
        _longitude = 75.8391;
        _addressController.text = "Near Aerodrome Circle, Dadabari Road, Kota, Rajasthan - 324009";
        _locationStatus = "✅ Location set: Lat 25.1825, Lng 75.8391 (Kota, Rajasthan)";
        _isDetectingLocation = false;
      });
    }
  }

  // Camera Capture
  Future<void> _capturePhoto() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? photo = await picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1200,
        maxHeight: 1200,
        imageQuality: 85,
      );

      if (photo != null) {
        setState(() {
          _capturedImage = File(photo.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Camera error: $e"), backgroundColor: Colors.red),
      );
    }
  }

  void _submitComplaint() {
    if (!_formKey.currentState!.validate()) return;

    if (_addressController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please allow location access to auto-fill your location"),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
      return;
    }

    final complaintId = "#KDA-${1000 + (DateTime.now().millisecondsSinceEpoch % 9000)}";

    final complaintData = {
      "id": complaintId,
      "complaint_no": complaintId,
      "title": _selectedSubtype ?? "Civic Grievance",
      "type_name": _selectedCategory ?? "General",
      "sub_type_name": _selectedSubtype ?? "General",
      "garden_park_name": _selectedGardenPark,
      "description": _descriptionController.text.trim(),
      "landmark": _landmarkController.text.trim(),
      "address": _addressController.text.trim(),
      "latitude": _latitude?.toString() ?? "25.1825",
      "longitude": _longitude?.toString() ?? "75.8391",
      "status": "pending",
      "priority": "medium",
      "created_at": "Just now",
      "photo_path": _capturedImage?.path,
    };

    widget.onComplaintSubmitted(complaintData);

    // Show Success Dialog
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(color: Color(0xFFD1FAE5), shape: BoxShape.circle),
              child: const Icon(Icons.check_circle, color: Color(0xFF10B981), size: 24),
            ),
            const SizedBox(width: 12),
            const Text("Grievance Registered!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Your complaint has been successfully lodged with Kota Development Authority.",
              style: TextStyle(fontSize: 13, color: Color(0xFF475569)),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E8),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFD6B3)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text("Tracking Ticket ID:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(complaintId, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFFE3861C))),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              "Assigned department moderator will verify and assign to field engineers within 24 hours.",
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
            ),
          ],
        ),
        actions: [
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE3861C),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
            ),
            child: const Text("View in My Complaints", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isHorticulture = _selectedCategory?.contains("Town Planning & Parks") ?? false;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Banner matching Web App
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE3861C), Color(0xFFF95700)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFE3861C).withOpacity(0.25),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.note_add, color: Colors.white, size: 26),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "New Complaint (नई शिकायत)",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        SizedBox(height: 2),
                        Text(
                          "Fill in details to lodge your civic problem. We will track it for you.",
                          style: TextStyle(fontSize: 12, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Form Container
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Category Dropdown
                  _buildLabel(Icons.layers, "Complaint Category (शिकायत श्रेणी) *"),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedCategory,
                    isExpanded: true,
                    decoration: _inputDecoration(),
                    items: _categoryMap.keys.map((cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat, style: const TextStyle(fontSize: 13)));
                    }).toList(),
                    onChanged: _onCategoryChanged,
                  ),
                  const SizedBox(height: 18),

                  // 2. Sub Type Dropdown
                  _buildLabel(Icons.label, "Sub Type (उप प्रकार) *"),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _selectedSubtype,
                    isExpanded: true,
                    decoration: _inputDecoration(),
                    items: (_categoryMap[_selectedCategory] ?? []).map((sub) {
                      return DropdownMenuItem(value: sub, child: Text(sub, style: const TextStyle(fontSize: 13)));
                    }).toList(),
                    onChanged: (val) => setState(() => _selectedSubtype = val),
                  ),
                  const SizedBox(height: 18),

                  // 3. Garden / Park Dropdown (Conditional)
                  if (isHorticulture) ...[
                    _buildLabel(Icons.park, "Garden / Park (उद्यान / पार्क) *"),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: _selectedGardenPark,
                      hint: const Text("-- Select Garden / Park --", style: TextStyle(fontSize: 13)),
                      isExpanded: true,
                      decoration: _inputDecoration(),
                      items: _gardenParks.map((park) {
                        return DropdownMenuItem(value: park, child: Text(park, style: const TextStyle(fontSize: 13)));
                      }).toList(),
                      onChanged: (val) => setState(() => _selectedGardenPark = val),
                    ),
                    const SizedBox(height: 18),
                  ],

                  // 4. Location & Address Section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildLabel(Icons.location_on, "Location & Address *"),
                      ElevatedButton.icon(
                        onPressed: _isDetectingLocation ? null : _detectLocation,
                        icon: _isDetectingLocation
                            ? const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.my_location, size: 14),
                        label: const Text("Allow Location", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFE3861C),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(_locationStatus, style: const TextStyle(fontSize: 11, color: Color(0xFF64748B))),
                  const SizedBox(height: 8),

                  // Territory Gate Notice
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF3E8),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.shield, color: Color(0xFFE3861C), size: 16),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "Allow location access to continue. Complaint registration is available only from Kota or Bundi territory.",
                            style: TextStyle(fontSize: 11, color: Color(0xFF475569)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),

                  TextFormField(
                    controller: _addressController,
                    readOnly: true,
                    maxLines: 2,
                    decoration: _inputDecoration(hint: "Click 'Allow Location' button above to get address"),
                    validator: (v) => v!.trim().isEmpty ? "Location is required" : null,
                  ),
                  const SizedBox(height: 18),

                  // 5. Landmark
                  _buildLabel(Icons.pin_drop, "Landmark (मुख्य पहचान स्थल)"),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _landmarkController,
                    decoration: _inputDecoration(hint: "Near school, temple, community center..."),
                  ),
                  const SizedBox(height: 18),

                  // 6. Complaint Description
                  _buildLabel(Icons.description, "Complaint Details (शिकायत का विवरण) *"),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionController,
                    maxLines: 3,
                    decoration: _inputDecoration(hint: "Explain problem clearly..."),
                    validator: (v) => v!.trim().isEmpty ? "Please enter complaint details" : null,
                  ),
                  const SizedBox(height: 20),

                  // 7. Live Camera Photo Capture
                  _buildLabel(Icons.camera_alt, "Photo (Capture with Live Camera) *"),
                  const SizedBox(height: 8),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFCBD5E1), style: BorderStyle.solid),
                    ),
                    child: _capturedImage == null
                        ? Column(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: const BoxDecoration(
                                  color: Color(0xFFFFF3E8),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.camera_alt, color: Color(0xFFE3861C), size: 30),
                              ),
                              const SizedBox(height: 10),
                              const Text(
                                "Click below to capture photo using live camera",
                                style: TextStyle(fontSize: 12, color: Color(0xFF64748B)),
                              ),
                              const SizedBox(height: 14),
                              ElevatedButton.icon(
                                onPressed: _capturePhoto,
                                icon: const Icon(Icons.camera, color: Colors.white, size: 18),
                                label: const Text("Allow camera & open", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFFE3861C),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _capturedImage!,
                                  width: double.infinity,
                                  height: 200,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              const SizedBox(height: 12),
                              OutlinedButton.icon(
                                onPressed: _capturePhoto,
                                icon: const Icon(Icons.refresh, color: Color(0xFFE3861C), size: 18),
                                label: const Text("Retake Photo", style: TextStyle(color: Color(0xFFE3861C), fontWeight: FontWeight.bold)),
                                style: OutlinedButton.styleFrom(
                                  side: const BorderSide(color: Color(0xFFE3861C)),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 26),

                  // Submit Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _submitComplaint,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE3861C),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
                        elevation: 3,
                      ),
                      child: const Text(
                        "Submit Grievance / शिकायत दर्ज करें",
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFE3861C), size: 16),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({String? hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF94A3B8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFCBD5E1))),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE2E8F0))),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE3861C), width: 1.5)),
    );
  }
}

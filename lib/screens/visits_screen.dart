import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../providers/app_state_provider.dart';
import '../widgets/custom_widgets.dart';

class VisitsScreen extends StatefulWidget {
  const VisitsScreen({super.key});

  @override
  State<VisitsScreen> createState() => _VisitsScreenState();
}

class _VisitsScreenState extends State<VisitsScreen> {
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  String _selectedVisitType = 'School Visit';
  String? _selectedProjectId;
  final _locationController = TextEditingController();
  final _purposeController = TextEditingController();
  final _remarksController = TextEditingController();
  
  XFile? _capturedPhoto;
  bool _submitting = false;

  final List<String> _visitTypes = [
    'School Visit',
    'Widow Visit',
    'HO Visit',
    'Other Visit',
  ];

  @override
  void dispose() {
    _locationController.dispose();
    _purposeController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _captureFieldPhoto() async {
    final photo = await _picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1200,
      maxHeight: 1200,
      imageQuality: 85,
    );
    if (photo != null) {
      setState(() {
        _capturedPhoto = photo;
      });
    }
  }

  Future<void> _submitVisitReport() async {
    if (!_formKey.currentState!.validate()) return;
    if (_capturedPhoto == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('A photo is required to verify the field audit.')),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    final state = Provider.of<AppStateProvider>(context, listen: false);
    try {
      final bytes = await _capturedPhoto!.readAsBytes();

      final res = await state.submitFieldVisit(
        visitType: _selectedVisitType,
        projectId: _selectedProjectId ?? '',
        purpose: _purposeController.text,
        locationName: _locationController.text,
        remarks: _remarksController.text,
        photoBytes: bytes,
      );

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(res['success'] ? 'Success' : 'Failed'),
          content: Text(res['message']),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(ctx);
                if (res['success']) {
                  _resetForm();
                }
              },
              child: const Text('OK'),
            ),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Submission error: $e')),
      );
    } finally {
      setState(() {
        _submitting = false;
      });
    }
  }

  void _resetForm() {
    setState(() {
      _capturedPhoto = null;
      _locationController.clear();
      _purposeController.clear();
      _remarksController.clear();
      if (Provider.of<AppStateProvider>(context, listen: false).projects.isNotEmpty) {
        _selectedProjectId = Provider.of<AppStateProvider>(context, listen: false).projects.first.id;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final projects = state.projects;

    if (_selectedProjectId == null && projects.isNotEmpty) {
      _selectedProjectId = projects.first.id;
    }

    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      appBar: AppBar(
        title: const Text('Field Audits & Visits', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
        backgroundColor: const Color(0xff4f46e5),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Log New Visit Card
            CustomCard(
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Log New Field Audit',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xff0f172a)),
                    ),
                    const Divider(height: 24),
                    
                    // Visit Type
                    DropdownButtonFormField<String>(
                      value: _selectedVisitType,
                      decoration: const InputDecoration(labelText: 'Visit Category'),
                      items: _visitTypes.map((t) {
                        return DropdownMenuItem(value: t, child: Text(t));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedVisitType = val);
                      },
                    ),
                    const SizedBox(height: 16),

                    // Associated Project
                    if (projects.isNotEmpty) ...[
                      DropdownButtonFormField<String>(
                        value: _selectedProjectId,
                        decoration: const InputDecoration(labelText: 'Associated Project'),
                        items: projects.map((p) {
                          return DropdownMenuItem(value: p.id, child: Text(p.name));
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedProjectId = val);
                        },
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Location Name
                    TextFormField(
                      controller: _locationController,
                      decoration: const InputDecoration(labelText: 'Location / Landmark Name'),
                      validator: (v) => v == null || v.isEmpty ? 'Location name is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Purpose
                    TextFormField(
                      controller: _purposeController,
                      decoration: const InputDecoration(labelText: 'Audit Purpose'),
                      maxLines: 2,
                      validator: (v) => v == null || v.isEmpty ? 'Purpose is required' : null,
                    ),
                    const SizedBox(height: 16),

                    // Remarks
                    TextFormField(
                      controller: _remarksController,
                      decoration: const InputDecoration(labelText: 'Observations & Remarks'),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 20),

                    // Photo Attachment Area
                    GestureDetector(
                      onTap: _captureFieldPhoto,
                      child: Container(
                        height: 150,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.grey.shade300, width: 1.5, style: BorderStyle.none == false ? BorderStyle.solid : BorderStyle.none),
                        ),
                        child: _capturedPhoto != null
                            ? Stack(
                                fit: StackFit.expand,
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(10),
                                    child: Image.file(
                                      File(_capturedPhoto!.path),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                  Container(
                                    color: Colors.black45,
                                    alignment: Alignment.center,
                                    child: const Text(
                                      'Tap to recapture photo',
                                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              )
                            : Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.camera_alt_outlined, size: 40, color: Colors.grey.shade400),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Capture Mandatory Geotagged Photo',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    PrimaryButton(
                      label: 'Submit Field Report',
                      icon: Icons.send_outlined,
                      backgroundColor: const Color(0xff10b981),
                      onPressed: _submitting ? null : _submitVisitReport,
                      isLoading: _submitting,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Visit History Timeline
            const Text(
              'My Field Visit Log',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Color(0xff0f172a)),
            ),
            const SizedBox(height: 12),
            _buildVisitHistory(state.visits),
          ],
        ),
      ),
    );
  }

  Widget _buildVisitHistory(List<FieldVisit> visitsList) {
    if (visitsList.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 40.0),
          child: Text('No field audits logged yet.', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: visitsList.length,
      separatorBuilder: (context, i) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final visit = visitsList[i];
        final isCompleted = visit.status == 'Completed';

        return CustomCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    visit.projectName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xff0f172a)),
                  ),
                  StatusBadge(label: visit.visitType, type: 'info'),
                ],
              ),
              const Divider(height: 16),
              InfoRow(label: 'Location', value: visit.location, icon: Icons.location_pin),
              InfoRow(label: 'Purpose', value: visit.purpose, icon: Icons.info_outline),
              InfoRow(label: 'Date Logged', value: visit.dateTime.substring(0, 10), icon: Icons.calendar_today_outlined),
              if (visit.photos.isNotEmpty) ...[
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    visit.photos.first,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      height: 100,
                      color: Colors.grey.shade100,
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image_outlined, color: Colors.grey),
                    ),
                  ),
                )
              ]
            ],
          ),
        );
      },
    );
  }
}

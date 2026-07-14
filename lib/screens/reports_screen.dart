import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart';
import '../providers/app_state_provider.dart';
import '../models/employee_location.dart';
import '../widgets/custom_widgets.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  EmployeeLocation? _selectedOfficer;
  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    final state = Provider.of<AppStateProvider>(context);
    final userRole = state.currentUserEmployee?.designation ?? '';
    final isSupervisorOrAdmin = userRole.toLowerCase().contains('supervisor') || userRole.toLowerCase().contains('admin');

    // If officer is a field agent, they only view their own live track.
    EmployeeLocation? myTrackingDoc;
    if (!isSupervisorOrAdmin && state.currentUserEmployee != null) {
      try {
        myTrackingDoc = state.employeeLocations.firstWhere(
          (l) => l.employeeId == state.currentUserEmployee!.id,
        );
      } catch (_) {
        // Doc not synchronized yet
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xfff8fafc),
      appBar: AppBar(
        title: const Text('Live Tracking & Routes', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 16)),
        backgroundColor: const Color(0xff4f46e5),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: isSupervisorOrAdmin
          ? _buildSupervisorLayout(state)
          : _buildAgentLayout(myTrackingDoc),
    );
  }

  Widget _buildAgentLayout(EmployeeLocation? myTrack) {
    if (myTrack == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.gps_off_outlined, size: 48, color: Colors.grey.shade400),
              const SizedBox(height: 12),
              const Text(
                'Live tracking has not started yet.\nCheck In to broadcast your GPS map signal.',
                style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        _buildGoogleMapView(myTrack),
        Positioned(
          bottom: 24,
          left: 20,
          right: 20,
          child: CustomCard(
            color: Colors.white,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('My Tracking Beacon', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    StatusBadge(label: myTrack.status, type: myTrack.status == 'Offline' ? 'danger' : 'success'),
                  ],
                ),
                const Divider(height: 16),
                InfoRow(label: 'Last Broadcast', value: myTrack.lastUpdated.substring(11, 19)),
                InfoRow(label: 'Breadcrumb Steps', value: '${myTrack.routeHistory.length} positions'),
              ],
            ),
          ),
        )
      ],
    );
  }

  Widget _buildSupervisorLayout(AppStateProvider state) {
    final officers = state.employeeLocations;

    if (_selectedOfficer != null) {
      // Re-fetch selected officer from fresh live stream list
      try {
        _selectedOfficer = officers.firstWhere((o) => o.employeeId == _selectedOfficer!.employeeId);
      } catch (_) {}
    }

    return Column(
      children: [
        // Horizontal list of monitored officers
        Container(
          height: 90,
          color: Colors.white,
          child: officers.isEmpty
              ? const Center(child: Text('No active beacons tracking currently.', style: TextStyle(color: Colors.grey, fontSize: 12)))
              : ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.all(12),
                  itemCount: officers.length,
                  itemBuilder: (context, i) {
                    final o = officers[i];
                    final isSel = _selectedOfficer?.employeeId == o.employeeId;

                    return Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedOfficer = o;
                          });
                          _zoomToLocation(o.latitude, o.longitude);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSel ? const Color(0xff4f46e5).withOpacity(0.08) : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSel ? const Color(0xff4f46e5) : Colors.grey.shade200,
                              width: 1.2,
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 14,
                                backgroundColor: o.status == 'Offline' ? Colors.red : Colors.green,
                                child: const Icon(Icons.person, color: Colors.white, size: 14),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    o.employeeName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                  Text(
                                    o.status,
                                    style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
                                  )
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),

        Expanded(
          child: _selectedOfficer == null
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.map_outlined, size: 48, color: Colors.grey),
                      SizedBox(height: 12),
                      Text('Select an active Field Officer above\nto chart their live GPS routes.', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : Stack(
                  children: [
                    _buildGoogleMapView(_selectedOfficer!),
                    
                    // Card detailing selected officer breadcrumbs
                    Positioned(
                      bottom: 20,
                      left: 16,
                      right: 16,
                      child: CustomCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Route: ${_selectedOfficer!.employeeName}',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xff0f172a)),
                                ),
                                StatusBadge(label: _selectedOfficer!.status, type: 'success'),
                              ],
                            ),
                            const Divider(height: 16),
                            InfoRow(label: 'Live GPS Pin', value: '${_selectedOfficer!.latitude.toStringAsFixed(4)}, ${_selectedOfficer!.longitude.toStringAsFixed(4)}'),
                            InfoRow(label: 'Total Breadcrumbs', value: '${_selectedOfficer!.routeHistory.length} verified steps'),
                          ],
                        ),
                      ),
                    )
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildGoogleMapView(EmployeeLocation tracker) {
    final LatLng currentLatLng = LatLng(tracker.latitude, tracker.longitude);

    // Prepare path markers
    final Set<Marker> markers = {
      Marker(
        markerId: MarkerId(tracker.employeeId),
        position: currentLatLng,
        infoWindow: InfoWindow(title: tracker.employeeName, snippet: 'Status: ${tracker.status}'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueViolet),
      ),
    };

    // Plot full route lines representing movement trails
    final List<LatLng> polylinePoints = tracker.routeHistory
        .map((point) => LatLng(point.latitude, point.longitude))
        .toList();

    final Set<Polyline> polylines = {
      Polyline(
        polylineId: PolylineId('route_trail_${tracker.employeeId}'),
        points: polylinePoints,
        color: const Color(0xff6366f1),
        width: 4,
      ),
    };

    return GoogleMap(
      initialCameraPosition: CameraPosition(target: currentLatLng, zoom: 14),
      markers: markers,
      polylines: polylines,
      zoomControlsEnabled: false,
      onMapCreated: (controller) {
        _mapController = controller;
      },
    );
  }

  void _zoomToLocation(double lat, double lng) {
    _mapController?.animateCamera(
      CameraUpdate.newLatLngZoom(LatLng(lat, lng), 15),
    );
  }
}

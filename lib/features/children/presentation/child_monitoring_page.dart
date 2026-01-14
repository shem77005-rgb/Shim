import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../home/presentation/home_screen.dart';
import '../../../services/parent_monitoring_service.dart';
import '../../../models/child_location_model.dart';
import '../../../models/geo_alert_model.dart';

class ChildMonitoringPage extends StatefulWidget {
  final int childId;
  
  const ChildMonitoringPage({Key? key, required this.childId}) : super(key: key);
  
  @override
  _ChildMonitoringPageState createState() => _ChildMonitoringPageState();
}

class _ChildMonitoringPageState extends State<ChildMonitoringPage> {
  ChildLocation? _currentLocation;
  List<GeoAlert> _recentAlerts = [];
  List<ChildLocation> _locationHistory = [];
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _startPeriodicUpdates();
  }
  
  void _loadInitialData() async {
    await _loadCurrentLocation();
    await _loadRecentAlerts();
    await _loadLocationHistory();
    setState(() {
      _isLoading = false;
    });
  }
  
  void _startPeriodicUpdates() {
    Timer.periodic(const Duration(seconds: 60), (timer) async {
      await _loadCurrentLocation();
      await _loadRecentAlerts();
    });
  }
  
  Future<void> _loadCurrentLocation() async {
    ChildLocation? location = await ParentMonitoringService.getCurrentLocation(widget.childId);
    if (mounted) {
      setState(() {
        _currentLocation = location;
      });
    }
  }
  
  Future<void> _loadRecentAlerts() async {
    List<GeoAlert> alerts = await ParentMonitoringService.getRecentAlerts(widget.childId);
    if (mounted) {
      setState(() {
        _recentAlerts = alerts;
      });
    }
  }
  
  Future<void> _loadLocationHistory() async {
    List<ChildLocation> history = await ParentMonitoringService.getLocationHistory(widget.childId);
    if (mounted) {
      setState(() {
        _locationHistory = history;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Child Monitoring')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    
    return Scaffold(
      appBar: AppBar(title: const Text('Child Monitoring')),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Current Location on Map
            if (_currentLocation != null)
              SizedBox(
                height: 250,
                child: GoogleMap(
                  initialCameraPosition: CameraPosition(
                    target: LatLng(
                      _currentLocation!.latitude,
                      _currentLocation!.longitude,
                    ),
                    zoom: 15.0,
                  ),
                  markers: {
                    Marker(
                      markerId: const MarkerId('child_location'),
                      position: LatLng(
                        _currentLocation!.latitude,
                        _currentLocation!.longitude,
                      ),
                      icon: BitmapDescriptor.defaultMarkerWithHue(
                        BitmapDescriptor.hueRed,
                      ),
                    ),
                  },
                ),
              ),
            
            // Location Info
            Padding(
              padding: const EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      Text(
                        'Current Location',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Lat: ${_currentLocation?.latitude.toStringAsFixed(6)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Lng: ${_currentLocation?.longitude.toStringAsFixed(6)}',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Time: ${_currentLocation?.timestamp}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Recent Alerts
            if (_recentAlerts.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recent Alerts',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _recentAlerts.length,
                          itemBuilder: (context, index) {
                            GeoAlert alert = _recentAlerts[index];
                            return ListTile(
                              leading: Icon(
                                alert.eventType == 'entry' ? Icons.warning : Icons.info,
                                color: alert.eventType == 'entry' ? Colors.red : Colors.blue,
                              ),
                              title: Text('Alert: ${alert.eventType.toUpperCase()}'),
                              subtitle: Text('${alert.timestamp}'),
                              trailing: const Icon(Icons.location_on),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
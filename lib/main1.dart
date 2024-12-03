import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:location/location.dart'; // Import location package
import 'presentation/viewmodels/map_view_model.dart';
import 'presentation/screens/map_screen.dart';
import 'domain/usecases/location_tracking_use_case.dart';
import 'data/datasources/local/location_service.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        // Provide LocationService
        Provider<LocationService>(
          create: (_) => LocationService(),
        ),
        // Provide the LocationTrackingUseCase using LocationService from the previous provider
        ProxyProvider<LocationService, LocationTrackingUseCase>(
          update: (_, locationService, __) => LocationTrackingUseCase(locationService.locationStream),
        ),
        // Provide the MapViewModel, ensuring LocationTrackingUseCase is available from the ProxyProvider
        ChangeNotifierProvider<MapViewModel>(
          create: (context) {
            // Access LocationTrackingUseCase from context
            final locationTrackingUseCase = Provider.of<LocationTrackingUseCase>(context, listen: false);
            return MapViewModel(locationTrackingUseCase);
          },
        ),
      ],
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'GPS Tracker',
      theme: ThemeData(
        primarySwatch: Colors.teal,
      ),
      home: MapScreen(),
    );
  }
}

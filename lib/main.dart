import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:network_info_plus/network_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:http/http.dart' as http;
import 'dart:async';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Network Checker',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: NetworkCheckerScreen(),
    );
  }
}

class NetworkCheckerScreen extends StatefulWidget {
  @override
  _NetworkCheckerScreenState createState() => _NetworkCheckerScreenState();
}

class _NetworkCheckerScreenState extends State<NetworkCheckerScreen> {
  String networkStatus = 'Checking...';
  Timer? _timer; // Declarar el temporizador

  @override
  void initState() {
    super.initState();
    checkPermissionsAndNetwork();
    startPeriodicCheck(); // Iniciar la verificación periódica
  }

  @override
  void dispose() {
    _timer?.cancel(); // Cancelar el temporizador cuando el widget se desecha
    super.dispose();
  }

  void startPeriodicCheck() {
    _timer = Timer.periodic(Duration(seconds: 10), (timer) {
      checkPermissionsAndNetwork(); // Ejecutar la verificación periódicamente
    });
  }

  Future<void> checkPermissionsAndNetwork() async {
    bool hasPermissions = await requestPermissions();
    if (hasPermissions) {
      checkNetwork();
    } else {
      setState(() {
        networkStatus = 'Location permission is required to check Wi-Fi status';
      });
    }
  }

  Future<bool> requestPermissions() async {
    // Solicitar todos los permisos relevantes
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.locationWhenInUse,
    ].request();

    // Verificar que todos los permisos necesarios están concedidos
    bool allGranted = statuses.values.every((status) => status.isGranted);

    if (!allGranted) {
      // Si los permisos son denegados permanentemente, mostrar el cuadro de diálogo de configuración del sistema
      bool permanentlyDenied = statuses.values.any((status) => status.isPermanentlyDenied);
      if (permanentlyDenied) {
        showDialog(
          context: context,
          builder: (BuildContext context) => AlertDialog(
            title: Text('Permisos requeridos'),
            content: Text('Esta aplicación necesita permisos de ubicación para verificar el estado de Wi-Fi. Por favor, habilítalos en la configuración del sistema.'),
            actions: <Widget>[
              TextButton(
                child: Text('Ir a Configuración'),
                onPressed: () {
                  openAppSettings();
                },
              ),
            ],
          ),
        );
      }
    }

    return allGranted;
  }

  Future<void> checkNetwork() async {
    var connectivityResult = await (Connectivity().checkConnectivity());

    if (connectivityResult == ConnectivityResult.wifi) {
      final info = NetworkInfo();
      var wifiName = await info.getWifiName(); // Obtener el SSID de la red Wi-Fi
      var wifiBSSID = await info.getWifiBSSID(); // Obtener el BSSID de la red Wi-Fi

      if (wifiName != null && wifiName != '<unknown ssid>') {
        // Intentar acceder a Internet sin autenticación para determinar si es una red abierta
        bool isOpen = await canAccessInternetWithoutAuthentication();
        setState(() {
          if (isOpen) {
            networkStatus = 'You are connected to an open network: $wifiName';
          } else {
            networkStatus = 'You are connected to a secured network: $wifiName';
          }
        });
      } else {
        setState(() {
          networkStatus = 'No Wi-Fi connection detected or Wi-Fi name is unknown';
        });
      }
    } else {
      setState(() {
        networkStatus = 'You are not connected to Wi-Fi';
      });
    }
  }

  Future<bool> canAccessInternetWithoutAuthentication() async {
    try {
      // Realizar una solicitud HTTP a una URL conocida
      final response = await http.get(Uri.parse('http://example.com')).timeout(Duration(seconds: 5));
      // Si obtenemos una respuesta exitosa, inferimos que la red es abierta
      return response.statusCode == 200;
    } catch (e) {
      // Si ocurre un error, inferimos que la red podría no ser abierta
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Network Checker'),
      ),
      body: Center(
        child: Text(
          networkStatus,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}

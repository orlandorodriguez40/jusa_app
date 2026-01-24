import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:logger/logger.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFF62B23F),
        colorScheme: ColorScheme.fromSwatch().copyWith(
          primary: const Color(0xFF62B23F),
          secondary: const Color(0xFF424949),
        ),
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF424949),
          foregroundColor: Colors.white,
          elevation: 2,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      home: const LoginPage(),
    );
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  LoginPageState createState() => LoginPageState();
}

class LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  String _responseMessage = "";
  final Logger logger = Logger();

  Future<void> _login() async {
    try {
      final response = await http.post(
        Uri.parse("https://sistema.jusaimpulsemkt.com/api/login-app"),
        body: {
          "username": _usernameController.text,
          "password": _passwordController.text,
        },
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final bool estatus = data["estatus"] ?? false;
        final String mensaje = data["mensaje"] ?? "";
        final Map<String, dynamic> user = data["user"] ?? {};

        if (estatus &&
            mensaje.toLowerCase().contains("exito") &&
            user.isNotEmpty) {
          final int userId = user["id"] ?? 0;
          final String userName = user["username"] ?? "Usuario";

          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) =>
                  DashboardPage(userId: userId, userName: userName),
            ),
          );
        } else {
          setState(() {
            _responseMessage = mensaje.isNotEmpty ? mensaje : "Login fallido";
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(_responseMessage)));
        }
      } else {
        setState(() {
          _responseMessage = "Error de conexión (${response.statusCode})";
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_responseMessage)));
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _responseMessage = "Error: $e";
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_responseMessage)));
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Acceso al Sistema")),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset("assets/images/logo-jusa-2-opt.png", height: 120),
            const SizedBox(height: 30),
            TextField(
              controller: _usernameController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.person, color: Color(0xFF424949)),
                labelText: "USERNAME",
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.lock, color: Color(0xFF424949)),
                labelText: "PASSWORD",
              ),
              obscureText: true,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _login,
                child: const Text("ACCEDER"),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              _responseMessage,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF424949),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardPage extends StatefulWidget {
  final int userId;
  final String userName;

  const DashboardPage({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<DashboardPage> createState() => DashboardPageState();
}

class DashboardPageState extends State<DashboardPage> {
  List<dynamic> _asignaciones = [];
  String _errorMessage = "";
  bool _loading = true;
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    _fetchAsignaciones();
  }

  Future<void> _fetchAsignaciones() async {
    try {
      final response = await http.get(
        Uri.parse(
          "https://sistema.jusaimpulsemkt.com/api/mis-asignaciones-app/${widget.userId}",
        ),
        headers: {"Accept": "application/json"},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _asignaciones = data["datos"] ?? [];
          _loading = false;
        });
      } else {
        setState(() {
          _errorMessage = "Error al cargar asignaciones";
          _loading = false;
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = "Error: $e";
        _loading = false;
      });
    }
  }

  Future<void> _takePhoto(dynamic asignacion) async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);
    if (photo != null) {
      setState(() {
        _selectedImage = File(photo.path);
      });
    }
  }

  void _viewPhotos(dynamic asignacion) {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("No hay fotos tomadas")));
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text("Fotos tomadas")),
          body: Center(child: Image.file(_selectedImage!)),
        ),
      ),
    );
  }

  Widget _buildTable() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Text(
          _errorMessage,
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }
    if (_asignaciones.isEmpty) {
      return const Center(
        child: Text(
          "No hay asignaciones disponibles.",
          style: TextStyle(color: Color(0xFF424949), fontSize: 16),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFE8F5E9)),
        dataRowColor: WidgetStateProperty.resolveWith<Color?>((
          Set<WidgetState> states,
        ) {
          if (states.contains(WidgetState.selected)) {
            return Colors.green.withValues(alpha: 0.2);
          }
          return null;
        }),
        columns: const [
          DataColumn(
            label: Text("Fecha", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          DataColumn(
            label: Text(
              "Cliente",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text("Plaza", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          DataColumn(
            label: Text(
              "Ubicación",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              "Estatus",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          DataColumn(
            label: Text(
              "Acción",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
        rows: _asignaciones.map((asignacion) {
          return DataRow(
            cells: [
              DataCell(Text(asignacion["fecha"] ?? "")),
              DataCell(Text(asignacion["cliente"] ?? "")),
              DataCell(Text(asignacion["plaza"] ?? "")),
              DataCell(Text(asignacion["ciudad"] ?? "")),
              DataCell(Text(asignacion["estatus"] ?? "")),
              DataCell(
                Row(
                  children: [
                    Tooltip(
                      message: "Tomar foto",
                      child: IconButton(
                        icon: const Icon(Icons.camera_alt, color: Colors.green),
                        onPressed: () => _takePhoto(asignacion),
                      ),
                    ),
                    Tooltip(
                      message: "Ver fotos",
                      child: IconButton(
                        icon: const Icon(
                          Icons.photo_library,
                          color: Colors.blue,
                        ),
                        onPressed: () => _viewPhotos(asignacion),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF424949),
        title: const Text(
          "PANEL",
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.menu, color: Colors.white),
            onSelected: (value) {
              if (value == "Salir") {
                Navigator.of(context).pop();
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: "Asignaciones",
                child: Row(
                  children: [
                    Icon(Icons.assignment),
                    SizedBox(width: 8),
                    Text("Asignaciones"),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: "Perfil",
                child: Row(
                  children: [
                    Icon(Icons.person),
                    SizedBox(width: 8),
                    Text("Perfil"),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: "Salir",
                child: Row(
                  children: [
                    Icon(Icons.exit_to_app),
                    SizedBox(width: 8),
                    Text("Salir"),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Logo debajo del título
            Image.asset("assets/images/logo-jusa-2-opt.png", height: 80),
            const SizedBox(height: 20),
            Expanded(child: _buildTable()),
          ],
        ),
      ),
    );
  }
}

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
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor ingresa usuario y contraseña")),
      );
      return;
    }

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

          if (!mounted) return;
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) =>
                  DashboardPage(userId: userId, userName: userName),
            ),
          );
        } else {
          if (!mounted) return;
          setState(() {
            _responseMessage = mensaje.isNotEmpty ? mensaje : "Login fallido";
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(_responseMessage)));
        }
      } else {
        if (!mounted) return;
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
  bool _sendingPhoto = false; // loader para envío

  final Map<int, List<File>> _fotosPorAsignacion = {};

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
        if (!mounted) return;
        setState(() {
          _asignaciones = data["datos"] ?? [];
          _loading = false;
        });
      } else {
        if (!mounted) return;
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

  // Ver fotos desde el servidor
  void _viewPhotos(dynamic asignacion) async {
    final asignacionId = asignacion["id"];

    try {
      final response = await http.get(
        Uri.parse(
          "https://sistema.jusaimpulsemkt.com/api/fotos-asignacion-app/$asignacionId",
        ),
        headers: {"Accept": "application/json"},
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List fotosServidor = data["fotos"] ?? [];

        if (fotosServidor.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No hay fotos en el servidor")),
          );
          return;
        }

        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => Scaffold(
              appBar: AppBar(title: const Text("Fotos en servidor")),
              body: GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: fotosServidor.length,
                itemBuilder: (context, index) {
                  final fotoUrl = fotosServidor[index]["url"];
                  return Image.network(fotoUrl, fit: BoxFit.cover);
                },
              ),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al cargar fotos: ${response.statusCode}"),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Excepción al cargar fotos: $e")));
    }
  }

  Future<void> _takePhoto(dynamic asignacion) async {
    final ImagePicker picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);

    if (!mounted) return;

    if (photo != null) {
      final asignacionId = asignacion["id"];
      final nuevaFoto = File(photo.path);

      setState(() {
        _fotosPorAsignacion.putIfAbsent(asignacionId, () => []);
        _fotosPorAsignacion[asignacionId]!.add(nuevaFoto);
        _sendingPhoto = true; // mostrar loader mientras se envía
      });

      try {
        final request = http.MultipartRequest(
          'POST',
          Uri.parse("https://sistema.jusaimpulsemkt.com/api/tomar-foto-app"),
        );

        request.files.add(
          await http.MultipartFile.fromPath('file', nuevaFoto.path),
        );

        final response = await request.send();

        if (!mounted) return;
        setState(() {
          _sendingPhoto = false;
        });

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Foto tomada y enviada correctamente"),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error al enviar la foto: ${response.statusCode}"),
            ),
          );
        }
      } catch (e) {
        if (!mounted) return;
        setState(() {
          _sendingPhoto = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Excepción al enviar la foto: $e")),
        );
      }
    }
  }

  Widget _buildList() {
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

    return ListView.builder(
      itemCount: _asignaciones.length,
      itemBuilder: (context, index) {
        final asignacion = _asignaciones[index];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8),
          elevation: 3,
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Fecha: ${asignacion["fecha"] ?? ""}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text("Cliente: ${asignacion["cliente"] ?? ""}"),
                Text("Plaza: ${asignacion["plaza"] ?? ""}"),
                Text("Ubicación: ${asignacion["ciudad"] ?? ""}"),
                Text("Estatus: ${asignacion["estatus"] ?? ""}"),
                const SizedBox(height: 10),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.green),
                      tooltip: "Tomar y enviar foto",
                      onPressed: () => _takePhoto(asignacion),
                    ),
                    IconButton(
                      icon: const Icon(Icons.photo_library, color: Colors.blue),
                      tooltip: "Ver fotos en servidor",
                      onPressed: () => _viewPhotos(asignacion),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
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
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: "Asignaciones",
                    child: Row(
                      children: [
                        Icon(Icons.assignment),
                        SizedBox(width: 8),
                        Text("Asignaciones"),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: "Perfil",
                    child: Row(
                      children: [
                        Icon(Icons.person),
                        SizedBox(width: 8),
                        Text("Perfil"),
                      ],
                    ),
                  ),
                  PopupMenuItem(
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
                Image.asset("assets/images/logo-jusa-2-opt.png", height: 80),
                const SizedBox(height: 20),
                Expanded(child: _buildList()),
              ],
            ),
          ),
        ),

        // Overlay loader cuando se envía la foto
        if (_sendingPhoto)
          Positioned.fill(
            child: AbsorbPointer(
              absorbing: true,
              child: Container(
                color: Colors.black.withValues(alpha: 0.35),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 12),
                      Text(
                        "Enviando foto...",
                        style: TextStyle(color: Colors.white, fontSize: 16),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

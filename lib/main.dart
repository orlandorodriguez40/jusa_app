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

// ================== LOGIN PAGE ==================
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final Logger logger = Logger();
  bool _isLoading = false;

  Future<void> _login() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Por favor ingresa usuario y contraseña")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final response = await http.post(
        Uri.parse("https://sistema.jusaimpulsemkt.com/api/login-app"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "username": _usernameController.text,
          "password": _passwordController.text,
        }),
      );

      if (!mounted) return;
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 &&
          data["estatus"] == true &&
          data["user"] != null) {
        final user = data["user"];
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                DashboardPage(userId: user["id"], userName: user["username"]),
          ),
        );
      } else {
        if (!mounted) return;
        _showSnack(data["mensaje"] ?? "Login fallido");
      }
    } catch (e) {
      logger.e(e);
      if (!mounted) return;
      _showSnack("Error de conexión");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showSnack(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
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
                labelText: "USERNAME",
                prefixIcon: Icon(Icons.person, color: Color(0xFF424949)),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: "PASSWORD",
                prefixIcon: Icon(Icons.lock, color: Color(0xFF424949)),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _login,
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("ACCEDER"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ================== DASHBOARD PAGE ==================
class DashboardPage extends StatefulWidget {
  final int userId;
  final String userName;

  const DashboardPage({
    super.key,
    required this.userId,
    required this.userName,
  });

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  bool _loading = true;
  String _error = "";
  List<dynamic> _asignaciones = [];
  bool _sendingPhoto = false;

  final Map<int, List<File>> _fotosLocales = {};
  final String _serverBaseUrl = "https://sistema.jusaimpulsemkt.com/storage/";

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final response = await http.get(
        Uri.parse(
          "https://sistema.jusaimpulsemkt.com/api/mis-asignaciones-app/${widget.userId}",
        ),
      );
      if (!mounted) return;

      final data = jsonDecode(response.body);

      if (!mounted) return;
      setState(() {
        _asignaciones = data["datos"] ?? [];
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "No se pudieron cargar los datos";
        _loading = false;
      });
    }
  }

  Future<void> _takePhoto(dynamic asignacion) async {
    final picker = ImagePicker();
    final XFile? photo = await picker.pickImage(source: ImageSource.camera);
    if (!mounted) return;
    if (photo == null) return;

    final asignacionId = asignacion["id"];
    final file = File(photo.path);

    setState(() {
      _fotosLocales.putIfAbsent(asignacionId, () => []);
      _fotosLocales[asignacionId]!.add(file);
      _sendingPhoto = true;
    });

    try {
      final request = http.MultipartRequest(
        "POST",
        Uri.parse("https://sistema.jusaimpulsemkt.com/api/tomar-foto-app"),
      );
      request.fields["asignacion_id"] = asignacionId.toString();
      request.files.add(await http.MultipartFile.fromPath("file", file.path));

      final response = await request.send();
      if (!mounted) return;
      setState(() => _sendingPhoto = false);

      if (response.statusCode == 200) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Foto tomada y enviada correctamente")),
        );
      } else {
        final respStr = await response.stream.bytesToString();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error al enviar la foto: $respStr")),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _sendingPhoto = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Excepción al enviar la foto: $e")),
      );
    }
  }

  Future<void> _viewServerPhotos(int asignacionId) async {
    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final response = await http.get(
        Uri.parse(
          "https://sistema.jusaimpulsemkt.com/api/fotos-asignacion-app/$asignacionId",
        ),
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List fotos = data["datos"] ?? [];

        if (fotos.isEmpty) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("No hay fotos en el servidor")),
          );
          return;
        }

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => Scaffold(
              appBar: AppBar(title: const Text("Fotos en servidor")),
              body: GridView.builder(
                padding: const EdgeInsets.all(12),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                ),
                itemCount: fotos.length,
                itemBuilder: (_, index) {
                  final foto = fotos[index]["foto"];
                  final url = "$_serverBaseUrl$foto";
                  return Image.network(url, fit: BoxFit.cover);
                },
              ),
            ),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al cargar fotos: ${response.statusCode}"),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error al cargar fotos: $e")));
    }
  }

  Widget _card(dynamic item) {
    final asignacionId = item["id"];
    final fotos = _fotosLocales[asignacionId] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha((0.08 * 255).round()),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _item("Fecha", item["fecha"]),
          _item("Cliente", item["cliente"]),
          _item("Plaza", item["plaza"]),
          _item("Ciudad", item["ciudad"]),
          _item("Estatus", item["estatus"]),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _takePhoto(item),
                  icon: const Icon(Icons.camera_alt, size: 28),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text("Tomar foto", style: TextStyle(fontSize: 16)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _viewServerPhotos(asignacionId),
                  icon: const Icon(Icons.photo_library, size: 28),
                  label: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text("Ver fotos", style: TextStyle(fontSize: 16)),
                  ),
                ),
              ),
            ],
          ),
          if (fotos.isNotEmpty) ...[
            const SizedBox(height: 10),
            const Text("Fotos locales:"),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: fotos
                  .map(
                    (f) =>
                        Image.file(f, width: 90, height: 90, fit: BoxFit.cover),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _item(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text("$label: ${value ?? ''}"),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(title: Text("Hola, ${widget.userName}")),
          body: Center(
            child: SingleChildScrollView(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Image.asset(
                        "assets/images/logo-jusa-2-opt.png",
                        height: 80,
                      ),
                      const SizedBox(height: 20),
                      if (_loading)
                        const CircularProgressIndicator()
                      else if (_error.isNotEmpty)
                        Text(_error)
                      else
                        ..._asignaciones.map(_card),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
        if (_sendingPhoto)
          Container(
            color: Colors.black45,
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text(
                    "Enviando foto...",
                    style: TextStyle(color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

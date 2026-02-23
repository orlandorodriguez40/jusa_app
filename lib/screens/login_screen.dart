// login_screen.dart - VERSIÓN PARA DETECTAR EL JSON REAL

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'menu_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = await http.post(
        Uri.parse("https://sistema.jusaimpulsemkt.com/api/login-app"),
        headers: {
          "Accept": "application/json",
          "Content-Type": "application/json"
        },
        body: jsonEncode({
          "username": _usernameController.text.trim(),
          "password": _passwordController.text,
        }),
      );

      if (!mounted) {
        return;
      }

      final String bodyRaw = response.body;
      debugPrint("JSON RECIBIDO: $bodyRaw");

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(bodyRaw);
        Map<String, dynamic>? userDetected;

        // Intentamos detectar al usuario automáticamente
        if (data is Map<String, dynamic>) {
          // Buscamos en las llaves más probables
          var candidate = data['user'] ?? data['usuario'] ?? data['data'];

          if (candidate is List && candidate.isNotEmpty) {
            candidate = candidate[0];
          }

          if (candidate is Map) {
            userDetected = Map<String, dynamic>.from(candidate);
          } else if (data.containsKey('username')) {
            // Si el usuario está en la raíz
            userDetected = data;
          }
        }

        if (userDetected != null) {
          final fotos = data is Map ? (data['fotos_servidor'] ?? []) : [];
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => MenuScreen(
                user: userDetected!,
                fotosServidor: List<dynamic>.from(fotos),
              ),
            ),
          );
        } else {
          // 🚨 SI FALLA, MOSTRAMOS EL JSON EN PANTALLA
          _mostrarDialogoDebug(bodyRaw);
        }
      } else {
        _mostrarError("Error ${response.statusCode}: Credenciales incorrectas");
      }
    } catch (e) {
      if (mounted) {
        _mostrarError("Error de conexión: $e");
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // Esta función te mostrará el JSON en el celular para que me lo digas
  void _mostrarDialogoDebug(String jsonStr) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Analizando Respuesta"),
        content: SingleChildScrollView(
          child: Text("El servidor envió esto:\n\n$jsonStr"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Entendido"),
          ),
        ],
      ),
    );
  }

  void _mostrarError(String mensaje) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
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
      backgroundColor: Colors.white,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.asset(
                  'assets/images/logo-jusa-2-opt.png',
                  height: 120,
                  errorBuilder: (_, __, ___) =>
                      const Icon(Icons.business, size: 80, color: Colors.green),
                ),
                const SizedBox(height: 40),
                TextFormField(
                  controller: _usernameController,
                  decoration: const InputDecoration(
                    labelText: "Usuario",
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    return v!.isEmpty ? "Ingrese su usuario" : null;
                  },
                ),
                const SizedBox(height: 20),
                TextFormField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: "Contraseña",
                    prefixIcon: Icon(Icons.lock),
                    border: OutlineInputBorder(),
                  ),
                  validator: (v) {
                    return v!.isEmpty ? "Ingrese su contraseña" : null;
                  },
                ),
                const SizedBox(height: 30),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF62B23F),
                      foregroundColor: Colors.white,
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text("INICIAR SESIÓN",
                            style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

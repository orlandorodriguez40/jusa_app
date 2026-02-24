// login_screen.dart - VERSIÓN CON HEADERS ANTI-BLOQUEO

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
          "Content-Type": "application/json",
          // 🛡️ HEADERS CRÍTICOS PARA EVITAR "ACCESS DENIED BY IMUNIFY360"
          "User-Agent":
              "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/122.0.0.0 Safari/537.36",
          "Accept-Language": "es-ES,es;q=0.9",
          "Sec-Ch-Ua":
              '"Chromium";v="122", "Not(A:Brand";v="24", "Google Chrome";v="122"',
          "Sec-Ch-Ua-Mobile": "?0",
          "Sec-Ch-Ua-Platform": '"Windows"',
          "Sec-Fetch-Dest": "empty",
          "Sec-Fetch-Mode": "cors",
          "Sec-Fetch-Site": "same-origin",
          "Origin": "https://sistema.jusaimpulsemkt.com",
          "Referer": "https://sistema.jusaimpulsemkt.com/",
        },
        body: jsonEncode({
          "username": _usernameController.text.trim(),
          "password": _passwordController.text,
        }),
      );

      if (!mounted) return;

      final String bodyRaw = response.body;
      debugPrint("JSON RECIBIDO: $bodyRaw");

      if (response.statusCode == 200) {
        final dynamic data = jsonDecode(bodyRaw);
        Map<String, dynamic>? userDetected;

        if (data is Map<String, dynamic>) {
          var candidate = data['user'] ?? data['usuario'] ?? data['data'];

          if (candidate is List && candidate.isNotEmpty) {
            candidate = candidate[0];
          }

          if (candidate is Map) {
            userDetected = Map<String, dynamic>.from(candidate);
          } else if (data.containsKey('username')) {
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
          _mostrarDialogoDebug(bodyRaw);
        }
      } else {
        // 🚨 Si Imunify bloquea, el status suele ser 403 o 406. Mostramos el error real.
        _mostrarDialogoDebug("Error ${response.statusCode}\n\n$bodyRaw");
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
                  validator: (v) => v!.isEmpty ? "Ingrese su usuario" : null,
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
                  validator: (v) => v!.isEmpty ? "Ingrese su contraseña" : null,
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

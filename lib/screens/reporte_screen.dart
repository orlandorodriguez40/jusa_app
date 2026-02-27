import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ReporteScreen extends StatefulWidget {
  final int userId;

  const ReporteScreen({super.key, required this.userId});

  @override
  State<ReporteScreen> createState() => _ReporteScreenState();
}

class _ReporteScreenState extends State<ReporteScreen> {
  bool _isLoading = true;
  List<dynamic> _reportes = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchReportes();
    });
  }

  Future<void> _fetchReportes() async {
    if (!mounted) {
      return;
    }

    setState(() => _isLoading = true);

    try {
      final url =
          "https://sistema.jusaimpulsemkt.com/api/mis-asignaciones-app/${widget.userId}";

      final response = await http.get(
        Uri.parse(url),
        headers: {"Accept": "application/json"},
      ).timeout(const Duration(seconds: 10));

      if (!mounted) {
        return;
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _reportes = data["datos"] ?? data["data"] ?? [];
        });
      }
    } catch (e) {
      debugPrint("Error en Reporte: $e");
    } finally {
      // 🛡️ Bloqueo anti-loop: Pase lo que pase, el cargador se apaga aquí.
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("REPORTE"),
        backgroundColor: const Color(0xFF424949),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 20),
                  Text("Buscando registros..."),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchReportes,
              child: _reportes.isEmpty ? _buildEmptyState() : _buildList(),
            ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.3),
        const Icon(Icons.assignment_late_outlined,
            size: 70, color: Colors.grey),
        const SizedBox(height: 20),
        const Center(
          child: Text(
            "NO HAY ASIGNACIONES",
            style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueGrey),
          ),
        ),
        const Center(
          child: Text(
            "Desliza hacia abajo para actualizar",
            style: TextStyle(color: Colors.grey),
          ),
        ),
      ],
    );
  }

  Widget _buildList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reportes.length,
      itemBuilder: (context, index) {
        final item = _reportes[index];
        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: const Icon(Icons.description, color: Colors.orange),
            title: Text(
              "${item['cliente'] ?? 'Sin cliente'}",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              "Fecha: ${item['fecha'] ?? '---'}\nEstatus: ${item['estatus'] ?? '---'}",
            ),
            isThreeLine: true,
          ),
        );
      },
    );
  }
}

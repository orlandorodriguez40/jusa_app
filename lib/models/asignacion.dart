class Asignacion {
  final int id;
  final String fecha;
  final String cliente;
  final String plaza;
  final String ciudad;
  final String estatus;

  Asignacion({
    required this.id,
    required this.fecha,
    required this.cliente,
    required this.plaza,
    required this.ciudad,
    required this.estatus,
  });

  /// Crear una instancia desde un Map (JSON)
  factory Asignacion.fromJson(Map<String, dynamic> json) {
    return Asignacion(
      id: json['id'] ?? 0,
      fecha: json['fecha'] ?? '',
      cliente: json['cliente'] ?? '',
      plaza: json['plaza'] ?? '',
      ciudad: json['ciudad'] ?? '',
      estatus: json['estatus'] ?? '',
    );
  }

  /// Convertir a Map (JSON) si es necesario enviar al servidor
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fecha': fecha,
      'cliente': cliente,
      'plaza': plaza,
      'ciudad': ciudad,
      'estatus': estatus,
    };
  }
}

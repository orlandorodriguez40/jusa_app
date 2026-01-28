class User {
  final int id;
  final String username;

  User({
    required this.id,
    required this.username,
  });

  /// Crear una instancia desde JSON
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? 0,
      username: json['username'] ?? 'Usuario',
    );
  }

  /// Convertir a JSON si es necesario enviar al servidor
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
    };
  }
}

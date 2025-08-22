// lib/models/espace_securise.dart
class EspaceSecurise {
  String date;
  String lieu;
  String porte; // "ouvert" ou "ferme"
  String quartier;
  String etat;
  String systeme;

  EspaceSecurise({
    required this.date,
    required this.lieu,
    required this.porte,
    required this.quartier,
    required this.etat,
    required this.systeme,
  });

  // Convertir depuis Firebase
  factory EspaceSecurise.fromMap(Map<String, dynamic> map) {
    return EspaceSecurise(
      date: map['Date'] ?? '',
      lieu: map['Lieu'] ?? '',
      porte: map['Porte'] ?? 'ferme',
      quartier: map['Quartier'] ?? '',
      etat: map['Etat'] ?? '',
      systeme: map['Système'] ?? '',
    );
  }

  // Convertir vers Firebase
  Map<String, dynamic> toMap() {
    return {
      'Date': date,
      'Lieu': lieu,
      'Porte': porte,
      'Quartier': quartier,
      'Etat': etat,
      'Système': systeme,
    };
  }
}

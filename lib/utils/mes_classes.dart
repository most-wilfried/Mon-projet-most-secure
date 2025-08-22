class EvenementSecurise {
  DateTime date;         // date de l'événement
  String description;    // description de l'événement
  String niveauGravite;  // niveau de gravité (ex: "faible", "moyen", "élevé")
  String typeEvenement;  // type d'événement (ex: "intrusion", "alarme")

  EvenementSecurise({
    required this.date,
    required this.description,
    required this.niveauGravite,
    required this.typeEvenement,
  });
}

class Utilisateur {
  String id;          // id généré par Firebase (uid)
  String nom;
  String prenom;
  DateTime dateCreation;
  String adresse;
  String empreinte;
  String role;
  List<double> visage;

  /// Nouveau champ : codePin (optionnel)
  String? codePin;

  Utilisateur({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.dateCreation,
    required this.adresse,
    required this.empreinte,
    required this.role,
    required this.visage,
    this.codePin,   // par défaut null
  });

  // Convertir en Map pour Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'nom': nom,
      'prenom': prenom,
      'dateCreation': dateCreation.toIso8601String(),
      'adresse': adresse,
      'empreinte': empreinte,
      'role': role,
      'visage': visage,
      'codePin': codePin, // ajouté dans la map
    };
  }

  // Récupérer depuis Firestore
  factory Utilisateur.fromMap(Map<String, dynamic> map) {
    return Utilisateur(
      id: map['id'],
      nom: map['nom'],
      prenom: map['prenom'],
      dateCreation: DateTime.parse(map['dateCreation']),
      adresse: map['adresse'],
      empreinte: map['empreinte'],
      role: map['role'],
      visage: List<double>.from(map['visage'] ?? []),
      codePin: map['codePin'], // peut être null si pas encore défini
    );
  }
}

class Systeme {
  String pin;        // pour les activation
  bool etatCapteur;  // état du capteur (true = actif, false = inactif)

  Systeme({
    required this.pin,
    required this.etatCapteur,
  });
}

class EspaceSecurise {
  String lieu;         // exemple: "Maison", "Bureau"
  String quartier;     // exemple: "Quartier XYZ"
  bool etatSysteme;    // état du système (true = activé, false = désactivé)
  bool porte;
  DateTime date;


  EspaceSecurise({
    required this.lieu,
    required this.quartier,
    required this.etatSysteme,
    required this.porte,
    required this.date,
   
  });
}

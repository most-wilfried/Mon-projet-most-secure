/// Représente un événement de sécurité avec sa date, sa description et sa gravité.
class EvenementSecurise {
  DateTime date; // date de l'événement
  String description; // description de l'événement
  String niveauGravite; // niveau de gravité (ex: "faible", "moyen", "élevé")
  String typeEvenement; // type d'événement (ex: "intrusion", "alarme")

  EvenementSecurise({
    required this.date,
    required this.description,
    required this.niveauGravite,
    required this.typeEvenement,
  });
}

/// Représente un utilisateur de l'application, qu'il soit parent, enfant ou admin.
class Utilisateur {
  String id; // id généré par Firebase (uid)
  String nom;
  String prenom;
  DateTime dateCreation;
  String adresse;
  int empreinte;
  String role;
  List<double> visage;
  String? telephone;

  /// Nouveau champ : codePin (optionnel)
  String? codePin;

  /// Constructeur de la classe Utilisateur.
  ///
  /// Crée une instance d'un utilisateur avec les informations fournies.
  Utilisateur({
    required this.id, // Identifiant unique de l'utilisateur.
    required this.nom, // Nom de famille de l'utilisateur.
    required this.prenom, // Prénom de l'utilisateur.
    required this.dateCreation, // Date de création du compte utilisateur.
    required this.adresse, // Adresse postale de l'utilisateur.
    required this.empreinte, // Données d'empreinte digitale (entier).
    required this.role, // Rôle de l'utilisateur (ex: 'parent', 'enfant').
    required this.visage, // Données de reconnaissance faciale (booléen ou chaîne).
    this.telephone, // Numéro de téléphone (optionnel).
    this.codePin, // Code PIN pour l'authentification (optionnel).
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
      'telephone': telephone,
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
      empreinte: (map['empreinte'] as num?)?.toInt() ?? 0,
      role: map['role'],
      visage: List<double>.from(map['visage'] ?? []),
      telephone: map['telephone'],
      codePin: map['codePin'], // peut être null si pas encore défini
    );
  }
}

/// Représente les informations de base d'un système de sécurité.
class Systeme {
  String pin; // pour les activation
  bool etatCapteur; // état du capteur (true = actif, false = inactif)

  Systeme({required this.pin, required this.etatCapteur});
}

/// Représente un espace physique sécurisé par le système.
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

/// SessionManager (centralisé ici)
/// Stocke des informations de l'utilisateur durant la session de l'application
/// (en mémoire). Si vous voulez persister entre redémarrages, utilisez
/// SharedPreferences ou secure storage.
/// Utilise le pattern Singleton pour n'avoir qu'une seule instance dans toute l'app.
class SessionManager {
  SessionManager._internal();
  static final SessionManager instance = SessionManager._internal();

  String? userId;
  String? email;
  String? role;
  String? nom;
  String? prenom;

  bool get isAuthenticated => userId != null;

  Future<void> setSession({
    required String uid,
    String? email,
    String? role,
    String? nom,
    String? prenom,
  }) async {
    userId = uid;
    this.email = email;
    this.role = role;
    this.nom = nom;
    this.prenom = prenom;
  }

  void clear() {
    userId = null;
    email = null;
    role = null;
    nom = null;
    prenom = null;
  }
}

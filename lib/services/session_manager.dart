/// SessionManager
  /// Stocke des informations de l'utilisateur durant la session de l'application
  /// (en mémoire). Si vous voulez persister entre redémarrages, utilisez
  /// SharedPreferences ou secure storage.
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
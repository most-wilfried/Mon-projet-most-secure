
import 'package:flutter_test/flutter_test.dart';
import 'package:test2/utils/mes_classes.dart'; 

void main() {
  group('Tests pour la classe Utilisateur', () {

    test('Un objet Utilisateur doit pouvoir être converti en Map et vice-versa', () {
      // 1. ARRANGE : Préparez les données de test.
      // On crée une instance de l'objet `Utilisateur` que nous allons tester.
      final dateTest = DateTime.now();
      final utilisateurOriginal = Utilisateur(
        id: '12345',
        nom: 'Dupont',
        prenom: 'Jean',
        dateCreation: dateTest,
        adresse: '123 Rue du Test',
        empreinte: 101,
        role: 'parent',
        visage: [1.0, 2.0, 3.0],
        telephone: '0123456789',
        codePin: '1234',
      );

      // 2. ACT : Exécutez le code que vous testez.
      // On convertit notre objet en Map.
      final map = utilisateurOriginal.toMap();
      // On reconvertit cette Map en un nouvel objet Utilisateur.
      final utilisateurDepuisMap = Utilisateur.fromMap(map);

      // 3. ASSERT : Vérifiez que le résultat est celui attendu.
      // `expect` compare la valeur obtenue avec la valeur attendue.
      // On vérifie que le nouvel objet est identique à l'original.
      expect(utilisateurDepuisMap.id, utilisateurOriginal.id);
      expect(utilisateurDepuisMap.nom, utilisateurOriginal.nom);
      expect(utilisateurDepuisMap.prenom, utilisateurOriginal.prenom);
      // Pour les dates, on compare la version ISO8601 pour éviter les soucis de précision.
      expect(utilisateurDepuisMap.dateCreation.toIso8601String(), utilisateurOriginal.dateCreation.toIso8601String());
      expect(utilisateurDepuisMap.adresse, utilisateurOriginal.adresse);
      expect(utilisateurDepuisMap.empreinte, utilisateurOriginal.empreinte);
      expect(utilisateurDepuisMap.role, utilisateurOriginal.role);
      expect(utilisateurDepuisMap.visage, utilisateurOriginal.visage);
      expect(utilisateurDepuisMap.telephone, utilisateurOriginal.telephone);
      expect(utilisateurDepuisMap.codePin, utilisateurOriginal.codePin);
    });

    test('La méthode fromMap doit gérer les valeurs nulles correctement', () {
        // ARRANGE: Crée une map avec des champs manquants ou nuls.
        final mapAvecNuls = {
            'id': 'user-002',
            'nom': 'Test',
            'prenom': 'Nul',
            'dateCreation': DateTime.now().toIso8601String(),
            'adresse': 'Quelque part',
            'role': 'enfant',
            // 'empreinte', 'visage', 'telephone', 'codePin' sont manquants
        };

        // ACT: Crée un utilisateur depuis cette map.
        final utilisateur = Utilisateur.fromMap(mapAvecNuls);

        // ASSERT: Vérifie que les valeurs par défaut ou nulles sont bien appliquées.
        expect(utilisateur.empreinte, 0); // Doit être 0 par défaut
        expect(utilisateur.visage, []); // Doit être une liste vide
        expect(utilisateur.telephone, null); // Doit être null
        expect(utilisateur.codePin, null); // Doit être null
    });
  });
}

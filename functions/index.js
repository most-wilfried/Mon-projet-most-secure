const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

exports.sendNotificationOnAlarme = functions.database
    .ref("/alarme/etat")
    .onWrite(async (change, context) => {
      const before = change.before.val();
      const after = change.after.val();

      // 👉 Envoi seulement si ça passe de false → true
      if (before === false && after === true) {
        const message = {
          notification: {
            title: "🚨 Alerte Sécurité",
            body: "L'alarme vient d'être activée !",
          },
          topic: "allUsers", // tous les utilisateurs abonnés reçoivent la notif
        };

        try {
          const response = await admin.messaging().send(message);
          console.log("✅ Notification envoyée:", response);
        } catch (error) {
          console.error("❌ Erreur notification:", error);
        }
      }

      return null;
    });

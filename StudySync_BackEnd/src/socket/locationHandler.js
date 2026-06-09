import { updateUserLocation, getNearbyActiveUsers } from "../services/locationService.js";
import { isWithinGeofence } from "../services/geoService.js";
import { verifySocketToken } from "../middleware/auth.middleware.js";

export const initLocationSocket = (io) => {

  // ── Middleware Socket.IO : vérifier JWT avant toute connexion ──────────────
  io.use((socket, next) => {
    try {
      const token = socket.handshake.auth?.token;
      const user = verifySocketToken(token); // lève une erreur si invalide
      socket.user = user; // { id, email, major, ... }
      next();
    } catch (err) {
      next(new Error("Authentification socket échouée : " + err.message));
    }
  });

  io.on("connection", (socket) => {
    const userId = socket.user.id; // ✅ userId depuis JWT, pas du client
    console.log(`✅ Socket connecté — user ${userId} (${socket.id})`);

    // ── Flutter envoie la position toutes les 30 secondes ───────────────────
    socket.on("location:update", async (data) => {
      const { latitude, longitude } = data;

      if (!latitude || !longitude) {
        return socket.emit("error", { message: "latitude et longitude requis" });
      }

      try {
        // 1. Sauvegarder en BDD avec l'userId du token (sécurisé)
        await updateUserLocation(userId, latitude, longitude);

        // 2. Trouver les utilisateurs actifs proches
        const nearbyUsers = await getNearbyActiveUsers(latitude, longitude);

        // 3. Renvoyer à Flutter
        socket.emit("nearby:users", {
          success: true,
          count: nearbyUsers.length,
          users: nearbyUsers,
        });

        console.log(`📍 Position mise à jour — user ${userId}`);
      } catch (error) {
        console.error("Erreur location:update :", error.message);
        socket.emit("error", { message: "Erreur mise à jour position" });
      }
    });

    // ── Vérification geofence pour check-in ─────────────────────────────────
    socket.on("checkin:verify", async (data) => {
      const { sessionLat, sessionLng, userLat, userLng, sessionId } = data;

      if (!sessionLat || !sessionLng || !userLat || !userLng || !sessionId) {
        return socket.emit("error", { message: "Paramètres de géofence manquants" });
      }

      try {
        const canCheckin = await isWithinGeofence(
          sessionLat, sessionLng,
          userLat, userLng
        );

        socket.emit("checkin:result", {
          sessionId,
          can_checkin: canCheckin,
          message: canCheckin
            ? "✅ Tu es dans la zone, tu peux te checker !"
            : "❌ Tu es trop loin — reste dans 100m de la session",
        });

        console.log(`📌 Geofence check — session ${sessionId} — user ${userId} : ${canCheckin}`);
      } catch (error) {
        console.error("Erreur checkin:verify :", error.message);
        socket.emit("error", { message: "Erreur vérification geofence" });
      }
    });

    socket.on("disconnect", () => {
      console.log(`❌ Socket déconnecté — user ${userId} (${socket.id})`);
    });
  });
};

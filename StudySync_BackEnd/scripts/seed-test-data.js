/**
 * Données de test StudySync (3–5 lignes par table).
 * Mot de passe de tous les comptes : Password123
 *
 * Usage : npm run db:seed:test
 */
import "dotenv/config";
import bcrypt from "bcryptjs";
import sequelize from "../src/config/db.config.js";
import "../src/models/index.js";
import {
  User,
  StudySession,
  SessionParticipant,
  Message,
  Rating,
  Report,
  Block,
  AdminAction,
} from "../src/models/index.js";

const PASSWORD = "Password123";

const IDS = {
  users: {
    superAdmin: "00000000-0000-0000-0000-000000000001",
    admin: "00000000-0000-0000-0000-000000000002",
    moderator: "00000000-0000-0000-0000-000000000003",
    sara: "00000000-0000-0000-0000-000000000004",
    jean: "00000000-0000-0000-0000-000000000005",
  },
  sessions: {
    completed: "aaaaaaaa-0000-0000-0000-000000000001",
    active: "aaaaaaaa-0000-0000-0000-000000000002",
    upcoming: "aaaaaaaa-0000-0000-0000-000000000003",
    cancelled: "aaaaaaaa-0000-0000-0000-000000000004",
  },
  messages: {
    m1: "bbbbbbbb-0000-0000-0000-000000000001",
    m2: "bbbbbbbb-0000-0000-0000-000000000002",
    m3: "bbbbbbbb-0000-0000-0000-000000000003",
    m4: "bbbbbbbb-0000-0000-0000-000000000004",
  },
  reports: {
    r1: "cccccccc-0000-0000-0000-000000000001",
    r2: "cccccccc-0000-0000-0000-000000000002",
    r3: "cccccccc-0000-0000-0000-000000000003",
    r4: "cccccccc-0000-0000-0000-000000000004",
  },
};

const point = (lng, lat) => ({ type: "Point", coordinates: [lng, lat] });

const daysAgo = (n) => {
  const d = new Date();
  d.setDate(d.getDate() - n);
  return d;
};

const daysFromNow = (n) => {
  const d = new Date();
  d.setDate(d.getDate() + n);
  return d;
};

const run = async () => {
  await sequelize.authenticate();
  console.log("Connexion BDD OK\n");

  const password_hash = await bcrypt.hash(PASSWORD, 10);

  await sequelize.sync();

  await sequelize.query(`
    ALTER TABLE messages ADD COLUMN IF NOT EXISTS message_type VARCHAR(20) DEFAULT 'text';
    ALTER TABLE messages ADD COLUMN IF NOT EXISTS media_url TEXT;
    ALTER TABLE messages ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;
    ALTER TABLE study_sessions ADD COLUMN IF NOT EXISTS study_type VARCHAR(50) DEFAULT 'active_discussion';
    ALTER TABLE study_sessions ADD COLUMN IF NOT EXISTS visibility VARCHAR(20) DEFAULT 'public';
    ALTER TABLE study_sessions ADD COLUMN IF NOT EXISTS description VARCHAR(200);
    ALTER TABLE study_sessions ADD COLUMN IF NOT EXISTS updated_at TIMESTAMPTZ;
    ALTER TABLE ratings ADD COLUMN IF NOT EXISTS overall_score INTEGER;
    ALTER TABLE ratings ADD COLUMN IF NOT EXISTS punctuality_score INTEGER;
    ALTER TABLE ratings ADD COLUMN IF NOT EXISTS engagement_score INTEGER;
    ALTER TABLE ratings ADD COLUMN IF NOT EXISTS would_study_again BOOLEAN;
    ALTER TABLE ratings ADD COLUMN IF NOT EXISTS comment TEXT;
    ALTER TABLE admin_actions ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}';
    ALTER TABLE admin_actions ADD COLUMN IF NOT EXISTS target_session_id UUID;
    ALTER TABLE admin_actions ADD COLUMN IF NOT EXISTS target_message_id UUID;
    ALTER TABLE admin_actions ADD COLUMN IF NOT EXISTS target_report_id UUID;
    ALTER TABLE reports ADD COLUMN IF NOT EXISTS resolution_action TEXT;
  `).catch(() => {});

  await AdminAction.destroy({ where: {}, truncate: true, cascade: true });
  await Block.destroy({ where: {}, truncate: true, cascade: true });
  await Report.destroy({ where: {}, truncate: true, cascade: true });
  await Rating.destroy({ where: {}, truncate: true, cascade: true });
  await Message.destroy({ where: {}, truncate: true, cascade: true });
  await SessionParticipant.destroy({ where: {}, truncate: true, cascade: true });
  await StudySession.destroy({ where: {}, truncate: true, cascade: true });
  await User.destroy({ where: {}, truncate: true, cascade: true });

  console.log("Tables vidées, insertion des données...\n");

  await User.bulkCreate([
    {
      id: IDS.users.superAdmin,
      email: "superadmin@studysync.ma",
      password_hash,
      first_name: "Super",
      last_name: "Admin",
      role: "super_admin",
      trust_score: 5.0,
    },
    {
      id: IDS.users.admin,
      email: "admin@studysync.ma",
      password_hash,
      first_name: "Ali",
      last_name: "Admin",
      role: "admin",
      trust_score: 4.8,
    },
    {
      id: IDS.users.moderator,
      email: "moderator@studysync.ma",
      password_hash,
      first_name: "Mounir",
      last_name: "Mod",
      university: "UM5",
      major: "Droit",
      year: 5,
      role: "moderator",
      trust_score: 4.5,
    },
    {
      id: IDS.users.sara,
      email: "sara@univ.ma",
      password_hash,
      first_name: "Sara",
      last_name: "Rahman",
      university: "UM5",
      major: "Informatique",
      year: 3,
      role: "student",
      trust_score: 4.0,
      bio: "Étudiante en info",
    },
    {
      id: IDS.users.jean,
      email: "jean@univ.ma",
      password_hash,
      first_name: "Jean",
      last_name: "Kofi",
      university: "UCA",
      major: "Maths",
      year: 2,
      role: "student",
      trust_score: 3.5,
      is_suspended: true,
      suspended_until: daysFromNow(3),
    },
  ]);

  await User.update({ role: "super_admin" }, { where: { id: IDS.users.superAdmin } });
  await User.update({ role: "admin" }, { where: { id: IDS.users.admin } });
  await User.update({ role: "moderator" }, { where: { id: IDS.users.moderator } });
  await User.update({ role: "student" }, { where: { id: IDS.users.sara } });
  await User.update({ role: "student" }, { where: { id: IDS.users.jean } });

  await StudySession.bulkCreate([
    {
      id: IDS.sessions.completed,
      creator_id: IDS.users.sara,
      subject: "Algèbre linéaire",
      topic: "Matrices et déterminants",
      location: point(-6.8498, 33.9716),
      location_name: "Bibliothèque centrale",
      start_time: daysAgo(7),
      duration_minutes: 120,
      max_participants: 5,
      status: "completed",
    },
    {
      id: IDS.sessions.active,
      creator_id: IDS.users.jean,
      subject: "Python",
      topic: "Flask API",
      location: point(-6.86, 33.98),
      location_name: "Campus Agdal",
      start_time: daysAgo(0),
      duration_minutes: 90,
      max_participants: 4,
      status: "active",
    },
    {
      id: IDS.sessions.upcoming,
      creator_id: IDS.users.sara,
      subject: "BDD",
      topic: "PostgreSQL",
      location: point(-6.84, 33.97),
      location_name: "Salle B12",
      start_time: daysFromNow(2),
      duration_minutes: 120,
      max_participants: 6,
      status: "created",
    },
    {
      id: IDS.sessions.cancelled,
      creator_id: IDS.users.jean,
      subject: "Physique",
      topic: "Mécanique",
      location: point(-6.85, 33.975),
      location_name: "Amphi C",
      start_time: daysFromNow(5),
      duration_minutes: 60,
      max_participants: 3,
      status: "cancelled",
    },
  ]);

  await SessionParticipant.bulkCreate([
    {
      session_id: IDS.sessions.completed,
      user_id: IDS.users.sara,
      status: "checked_in",
      checked_in_at: daysAgo(7),
    },
    {
      session_id: IDS.sessions.completed,
      user_id: IDS.users.jean,
      status: "checked_in",
      checked_in_at: daysAgo(7),
    },
    {
      session_id: IDS.sessions.active,
      user_id: IDS.users.sara,
      status: "joined",
    },
    {
      session_id: IDS.sessions.upcoming,
      user_id: IDS.users.jean,
      status: "joined",
    },
  ]);

  await Message.bulkCreate([
    {
      id: IDS.messages.m1,
      session_id: IDS.sessions.completed,
      sender_id: IDS.users.sara,
      content: "On commence par les exercices 1 à 5 ?",
    },
    {
      id: IDS.messages.m2,
      session_id: IDS.sessions.completed,
      sender_id: IDS.users.jean,
      content: "Oui, j'ai préparé les corrections.",
    },
    {
      id: IDS.messages.m3,
      session_id: IDS.sessions.active,
      sender_id: IDS.users.sara,
      content: "Quelqu'un a le PDF du cours ?",
    },
    {
      id: IDS.messages.m4,
      session_id: IDS.sessions.completed,
      sender_id: IDS.users.jean,
      content: "Message signalé (spam)",
      is_deleted: true,
      deleted_by_admin_id: IDS.users.admin,
    },
  ]);

  await Rating.bulkCreate([
    {
      rater_id: IDS.users.sara,
      rated_id: IDS.users.jean,
      session_id: IDS.sessions.completed,
      overall_score: 4,
    },
    {
      rater_id: IDS.users.jean,
      rated_id: IDS.users.sara,
      session_id: IDS.sessions.completed,
      overall_score: 5,
    },
    {
      rater_id: IDS.users.moderator,
      rated_id: IDS.users.sara,
      session_id: IDS.sessions.completed,
      overall_score: 5,
    },
    {
      rater_id: IDS.users.admin,
      rated_id: IDS.users.jean,
      session_id: IDS.sessions.completed,
      overall_score: 3,
    },
  ]);

  await User.update({ trust_score: 4.0 }, { where: { id: IDS.users.sara } });
  await User.update({ trust_score: 4.0 }, { where: { id: IDS.users.jean } });

  await Report.bulkCreate([
    {
      id: IDS.reports.r1,
      reporter_id: IDS.users.sara,
      reported_user_id: IDS.users.jean,
      reason: "harassment",
      description: "Messages répétés après la session",
      status: "pending",
    },
    {
      id: IDS.reports.r2,
      reporter_id: IDS.users.jean,
      reported_session_id: IDS.sessions.cancelled,
      reason: "spam",
      description: "Session non académique",
      status: "pending",
    },
    {
      id: IDS.reports.r3,
      reporter_id: IDS.users.sara,
      reported_message_id: IDS.messages.m4,
      reason: "spam",
      description: "Lien externe dans le chat",
      status: "resolved",
      resolved_by_id: IDS.users.moderator,
      resolved_at: daysAgo(1),
    },
    {
      id: IDS.reports.r4,
      reporter_id: IDS.users.jean,
      reported_user_id: IDS.users.sara,
      reason: "other",
      description: "Désaccord pédagogique",
      status: "dismissed",
      resolved_by_id: IDS.users.admin,
      resolved_at: daysAgo(2),
    },
  ]);

  await Block.bulkCreate([
    { blocker_id: IDS.users.sara, blocked_id: IDS.users.jean },
    { blocker_id: IDS.users.jean, blocked_id: IDS.users.moderator },
    { blocker_id: IDS.users.sara, blocked_id: IDS.users.admin },
  ]);

  await AdminAction.bulkCreate([
    {
      admin_id: IDS.users.admin,
      action_type: "suspend",
      target_user_id: IDS.users.jean,
      reason: "Harcèlement signalé",
    },
    {
      admin_id: IDS.users.admin,
      action_type: "delete_message",
      target_user_id: IDS.users.jean,
      reason: "Message spam supprimé",
    },
    {
      admin_id: IDS.users.moderator,
      action_type: "resolve_report",
      target_user_id: IDS.users.jean,
      reason: "Rapport message traité",
    },
    {
      admin_id: IDS.users.admin,
      action_type: "ban",
      target_user_id: IDS.users.jean,
      reason: "Test ban (données seed)",
    },
  ]);

  const counts = await Promise.all([
    User.count(),
    StudySession.count(),
    SessionParticipant.count(),
    Message.count(),
    Rating.count(),
    Report.count(),
    Block.count(),
    AdminAction.count(),
  ]);

  console.log("Résumé des insertions :");
  console.log(`  users               : ${counts[0]}`);
  console.log(`  study_sessions      : ${counts[1]}`);
  console.log(`  session_participants: ${counts[2]}`);
  console.log(`  messages            : ${counts[3]}`);
  console.log(`  ratings             : ${counts[4]}`);
  console.log(`  reports             : ${counts[5]}`);
  console.log(`  blocks              : ${counts[6]}`);
  console.log(`  admin_actions       : ${counts[7]}`);
  console.log("\nMot de passe pour tous les comptes : Password123");
  console.log("\nComptes de test :");
  console.log("  superadmin@studysync.ma  (super_admin)");
  console.log("  admin@studysync.ma       (admin)");
  console.log("  moderator@studysync.ma   (moderator)");
  console.log("  sara@univ.ma             (student)");
  console.log("  jean@univ.ma             (student, suspendu)");

  await sequelize.close();
  process.exit(0);
};

run().catch((err) => {
  console.error("Erreur seed:", err);
  process.exit(1);
});

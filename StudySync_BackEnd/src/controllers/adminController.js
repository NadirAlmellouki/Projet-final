import { Op } from "sequelize";
import User from "../models/User.js";
import StudySession from "../models/StudySession.js";
import Message from "../models/Message.js";
import AdminAction from "../models/AdminAction.js";

const sanitizeUser = (user) => {
  const { password_hash, ...safe } = user.toJSON();
  return safe;
};

const createAdminAction = async ({ admin_id, action_type, target_user_id = null, reason }) => {
  return AdminAction.create({
    admin_id,
    action_type,
    target_user_id,
    reason: reason ?? null,
    metadata: {},
  });
};

const listUsers = async (req, res) => {
  const page = Math.max(Number.parseInt(req.query.page ?? "1", 10), 1);
  const limit = Math.min(Math.max(Number.parseInt(req.query.limit ?? "10", 10), 1), 100);
  const q = (req.query.q ?? "").trim();
  const role = (req.query.role ?? "").trim();
  const offset = (page - 1) * limit;

  const where = {};
  if (q) {
    where[Op.or] = [
      { first_name: { [Op.iLike]: `%${q}%` } },
      { last_name: { [Op.iLike]: `%${q}%` } },
      { email: { [Op.iLike]: `%${q}%` } },
    ];
  }
  if (role) where.role = role;

  const { rows, count } = await User.findAndCountAll({
    where,
    order: [["created_at", "DESC"]],
    limit,
    offset,
  });

  return res.status(200).json({
    page,
    limit,
    total: count,
    total_pages: Math.ceil(count / limit) || 1,
    users: rows.map(sanitizeUser),
  });
};

const getUserDetail = async (req, res) => {
  const user = await User.findByPk(req.params.id);
  if (!user) return res.status(404).json({ message: "user not found" });
  return res.status(200).json({ user: sanitizeUser(user) });
};

const suspendUser = async (req, res) => {
  const { id } = req.params;
  const { suspended_until, reason } = req.body;
  if (!suspended_until) {
    return res.status(400).json({ message: "suspended_until is required" });
  }

  const user = await User.findByPk(id);
  if (!user) return res.status(404).json({ message: "user not found" });

  const until = new Date(suspended_until);
  if (Number.isNaN(until.getTime())) {
    return res.status(400).json({ message: "invalid suspended_until date" });
  }

  user.is_suspended = true;
  user.suspended_until = until;
  await user.save();

  await createAdminAction({
    admin_id: req.user.id ?? req.user.userId,
    action_type: "suspend",
    target_user_id: user.id,
    reason: reason?.trim() || `Suspended until ${until.toISOString()}`,
  });

  return res.status(200).json({ message: "user suspended", user: sanitizeUser(user) });
};

const unsuspendUser = async (req, res) => {
  const { id } = req.params;
  const { reason } = req.body;

  const user = await User.findByPk(id);
  if (!user) return res.status(404).json({ message: "user not found" });

  user.is_suspended = false;
  user.suspended_until = null;
  await user.save();

  await createAdminAction({
    admin_id: req.user.id ?? req.user.userId,
    action_type: "unsuspend",
    target_user_id: user.id,
    reason: reason?.trim() || "User unsuspended",
  });

  return res.status(200).json({ message: "user unsuspended", user: sanitizeUser(user) });
};

const banUser = async (req, res) => {
  const { id } = req.params;
  const { reason } = req.body;

  const user = await User.findByPk(id);
  if (!user) return res.status(404).json({ message: "user not found" });

  user.is_banned = true;
  await user.save();

  await createAdminAction({
    admin_id: req.user.id ?? req.user.userId,
    action_type: "ban",
    target_user_id: user.id,
    reason: reason?.trim() || "User banned",
  });

  return res.status(200).json({ message: "user banned", user: sanitizeUser(user) });
};

const deleteSession = async (req, res) => {
  const { id } = req.params;
  const { reason } = req.body;

  const session = await StudySession.findByPk(id);
  if (!session) return res.status(404).json({ message: "session not found" });

  await session.destroy();

  await createAdminAction({
    admin_id: req.user.id ?? req.user.userId,
    action_type: "delete_session",
    target_user_id: session.creator_id ?? null,
    reason: reason?.trim() || `Session ${id} deleted`,
  });

  return res.status(200).json({ message: "session deleted" });
};

const deleteMessage = async (req, res) => {
  const { id } = req.params;
  const { reason } = req.body;

  const message = await Message.findByPk(id);
  if (!message) return res.status(404).json({ message: "message not found" });

  message.is_deleted = true;
  message.deleted_by_admin_id = req.user.id ?? req.user.userId;
  await message.save();

  await createAdminAction({
    admin_id: req.user.id ?? req.user.userId,
    action_type: "delete_message",
    target_user_id: message.sender_id ?? null,
    reason: reason?.trim() || `Message ${id} deleted by admin`,
  });

  return res.status(200).json({ message: "message deleted", data: message });
};

export default {
  listUsers,
  getUserDetail,
  suspendUser,
  unsuspendUser,
  banUser,
  deleteSession,
  deleteMessage,
};

import { fn, col } from "sequelize";
import sequelize from "../config/db.config.js";
import Rating from "../models/Rating.js";
import StudySession from "../models/StudySession.js";
import User from "../models/User.js";

const parseOptionalScore = (value, label) => {
  if (value == null) return null;
  const n = Number(value);
  if (!Number.isInteger(n) || n < 1 || n > 5) {
    throw new Error(`INVALID_${label}`);
  }
  return n;
};

const createRating = async (req, res) => {
  const {
    session_id,
    rated_id,
    score,
    overall_score: overallScoreBody,
    punctuality_score,
    engagement_score,
    would_study_again,
    comment,
  } = req.body;
  const rater_id = req.user.id ?? req.user.userId;

  const rawScore = score ?? overallScoreBody;
  if (!session_id || !rated_id || rawScore == null) {
    return res.status(400).json({ message: "session_id, rated_id and score are required" });
  }

  if (!Number.isInteger(rawScore) || rawScore < 1 || rawScore > 5) {
    return res.status(400).json({ message: "score must be an integer between 1 and 5" });
  }
  const overall_score = rawScore;

  let punctualityScore;
  let engagementScore;
  try {
    punctualityScore = parseOptionalScore(punctuality_score, "PUNCTUALITY");
    engagementScore = parseOptionalScore(engagement_score, "ENGAGEMENT");
  } catch {
    return res.status(400).json({ message: "sub-scores must be integers between 1 and 5" });
  }

  if (rater_id === rated_id) {
    return res.status(400).json({ message: "you cannot rate yourself" });
  }

  const session = await StudySession.findByPk(session_id);
  if (!session) {
    return res.status(404).json({ message: "session not found" });
  }

  const startDate = new Date(session.start_time);
  const sessionEndDate = new Date(startDate.getTime() + session.duration_minutes * 60 * 1000);
  const isSessionEnded = Date.now() >= sessionEndDate.getTime() || session.status === "completed";

  if (!isSessionEnded) {
    return res.status(400).json({ message: "you can only rate after the session ends" });
  }

  const existingRating = await Rating.findOne({
  where: {
    rater_id,
    rated_id,
    session_id,
  },
});

  if (existingRating) {
    return res.status(409).json({ message: "you already rated for this session" });
  }

  const ratedUser = await User.findByPk(rated_id);
  if (!ratedUser) {
    return res.status(404).json({ message: "rated user not found" });
  }

  const result = await sequelize.transaction(async (t) => {
    const createdRating = await Rating.create(
      {
        rater_id,
        rated_id,
        session_id,
        overall_score,
        punctuality_score: punctualityScore,
        engagement_score: engagementScore,
        would_study_again: would_study_again ?? null,
        comment: comment?.trim() || null,
      },
      { transaction: t },
    );

    const stats = await Rating.findOne({
      where: { rated_id },
      attributes: [[fn("AVG", col("overall_score")), "average_score"]],
      raw: true,
      transaction: t,
    });

    const averageScore = Number(stats?.average_score ?? 0);
    await User.update(
      { trust_score: averageScore.toFixed(2) },
      { where: { id: rated_id }, transaction: t },
    );

    return { createdRating, averageScore };
  });

  return res.status(201).json({
    rating: result.createdRating,
    new_trust_score: Number(result.averageScore.toFixed(2)),
  });
};

const getUserRatings = async (req, res) => {
  const { userId } = req.params;

  const targetUser = await User.findByPk(userId);
  if (!targetUser) {
    return res.status(404).json({ message: "user not found" });
  }

  const ratings = await Rating.findAll({
    where: { rated_id: userId },
    order: [["created_at", "DESC"]],
  });

  const stats = await Rating.findOne({
    where: { rated_id: userId },
    attributes: [[fn("AVG", col("overall_score")), "average_score"]],
    raw: true,
  });

  const averageScore = Number(stats?.average_score ?? 0);

  return res.status(200).json({
    user_id: userId,
    ratings_count: ratings.length,
    average_score: Number(averageScore.toFixed(2)),
    ratings,
  });
};

export default {
  createRating,
  getUserRatings,
};

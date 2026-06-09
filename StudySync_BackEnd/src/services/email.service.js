import nodemailer from "nodemailer";

const isConfigured = () =>
  Boolean(
    process.env.SMTP_HOST &&
      process.env.SMTP_USER &&
      process.env.SMTP_PASS
  );

const createTransport = () =>
  nodemailer.createTransport({
    host: process.env.SMTP_HOST,
    port: Number(process.env.SMTP_PORT || 587),
    secure: process.env.SMTP_SECURE === "true",
    requireTLS: process.env.SMTP_SECURE !== "true",
    auth: {
      user: process.env.SMTP_USER,
      pass: String(process.env.SMTP_PASS || "").replace(/\s/g, ""),
    },
  });

export const sendPasswordResetEmail = async ({ to, resetUrl }) => {
  if (!isConfigured()) {
    console.warn(
      "[email] SMTP non configuré — lien reset (dev):",
      resetUrl
    );
    return { sent: false, devLink: resetUrl };
  }

  const transport = createTransport();
  const from =
    process.env.SMTP_FROM || `"StudySync" <${process.env.SMTP_USER}>`;

  await transport.sendMail({
    from,
    to,
    subject: "Réinitialisation de votre mot de passe StudySync",
    text: `Bonjour,\n\nCliquez sur ce lien pour réinitialiser votre mot de passe (valide 1 heure) :\n${resetUrl}\n\nSi vous n'avez pas demandé cette réinitialisation, ignorez cet email.\n\n— StudySync`,
    html: `
      <p>Bonjour,</p>
      <p>Cliquez sur le lien ci-dessous pour réinitialiser votre mot de passe (valide <strong>1 heure</strong>) :</p>
      <p><a href="${resetUrl}">${resetUrl}</a></p>
      <p>Si vous n'avez pas demandé cette réinitialisation, ignorez cet email.</p>
      <p>— StudySync</p>
    `,
  });

  return { sent: true };
};

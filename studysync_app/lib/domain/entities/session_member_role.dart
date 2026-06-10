enum SessionMemberRole {
  none,
  member,
  creator;

  bool get isParticipant =>
      this == SessionMemberRole.member || this == SessionMemberRole.creator;
}

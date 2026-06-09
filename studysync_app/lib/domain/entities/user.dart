class User {
  const User({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.university,
    this.major,
    this.year,
    this.bio,
    this.role = 'student',
    this.trustScore,
    this.profilePhoto,
  });

  final String id;
  final String firstName;
  final String lastName;
  final String email;
  final String? university;
  final String? major;
  final int? year;
  final String? bio;
  final String role;
  final double? trustScore;
  final String? profilePhoto;

  String get fullName => '$firstName $lastName';

  String get initials {
    final f = firstName.isNotEmpty ? firstName[0] : '';
    final l = lastName.isNotEmpty ? lastName[0] : '';
    return '$f$l'.toUpperCase();
  }

  bool get needsProfileSetup =>
      university == null ||
      university!.isEmpty ||
      major == null ||
      major!.isEmpty;

  String get yearLabel {
    if (year == null) return '';
    return switch (year) {
      1 => 'L1',
      2 => 'L2',
      3 => 'L3',
      4 => 'M1',
      5 => 'M2',
      _ => 'Année $year',
    };
  }

  User copyWith({
    String? firstName,
    String? lastName,
    String? university,
    String? major,
    int? year,
    String? bio,
    String? profilePhoto,
  }) {
    return User(
      id: id,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email,
      university: university ?? this.university,
      major: major ?? this.major,
      year: year ?? this.year,
      bio: bio ?? this.bio,
      role: role,
      trustScore: trustScore,
      profilePhoto: profilePhoto ?? this.profilePhoto,
    );
  }
}

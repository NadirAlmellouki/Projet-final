import '../../domain/entities/user.dart';

class UserModel extends User {
  const UserModel({
    required super.id,
    required super.firstName,
    required super.lastName,
    required super.email,
    super.university,
    super.major,
    super.year,
    super.bio,
    super.role,
    super.trustScore,
    super.profilePhoto,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final trust = json['trust_score'];
    return UserModel(
      id: json['id']?.toString() ?? '',
      firstName: json['first_name']?.toString() ?? '',
      lastName: json['last_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      university: json['university']?.toString(),
      major: json['major']?.toString(),
      year: json['year'] is int
          ? json['year'] as int
          : int.tryParse('${json['year']}'),
      bio: json['bio']?.toString(),
      role: json['role']?.toString() ?? 'student',
      trustScore: trust == null
          ? null
          : double.tryParse(trust.toString()),
      profilePhoto: json['profile_photo']?.toString() ??
          json['profile_photo_url']?.toString(),
    );
  }

  Map<String, dynamic> toUpdateJson() => {
        if (firstName.isNotEmpty) 'first_name': firstName,
        if (lastName.isNotEmpty) 'last_name': lastName,
        if (university != null) 'university': university,
        if (major != null) 'major': major,
        if (year != null) 'year': year,
        if (bio != null) 'bio': bio,
        if (profilePhoto != null) 'profile_photo': profilePhoto,
      };
}

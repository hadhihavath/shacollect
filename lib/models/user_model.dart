class UserModel {
  final String uid;
  final String displayName;
  final String email;
  final String? photoUrl;
  final String role; // "Route Recovery Agent"

  const UserModel({
    required this.uid,
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.role = 'Route Recovery Agent',
  });

  factory UserModel.demo() {
    return const UserModel(
      uid: 'agent_sha_001',
      displayName: 'Hadi Sha',
      email: 'hadi@tinyfab.in',
      photoUrl: null,
      role: 'Lead Field Recovery Officer',
    );
  }

  factory UserModel.agent({required String name, required String email}) {
    final cleanName = name.trim().isNotEmpty ? name.trim() : 'Hadi Sha';
    final cleanEmail = email.trim().isNotEmpty ? email.trim() : 'hadi@tinyfab.in';
    final rawKey = cleanEmail.isNotEmpty ? cleanEmail.split('@').first : cleanName;
    final slug = rawKey.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');
    return UserModel(
      uid: 'agent_${slug.isEmpty ? 'hadi' : slug}',
      displayName: cleanName,
      email: cleanEmail,
      photoUrl: null,
      role: 'Tiny Fab Collection & Sales Executive',
    );
  }
}

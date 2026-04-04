class JournalistProfileArgs {
  final String authorId;
  final String displayName;
  final String? email;
  final bool isOwner;

  const JournalistProfileArgs({
    required this.authorId,
    required this.displayName,
    this.email,
    required this.isOwner,
  });
}

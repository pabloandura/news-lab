abstract class ProfileStatsEvent {
  const ProfileStatsEvent();
}

class LoadProfileStats extends ProfileStatsEvent {
  final String authorId;
  const LoadProfileStats(this.authorId);
}

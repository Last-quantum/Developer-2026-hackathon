class StudyDay {
  final int dayNumber;
  final String title;
  final String duration;
  final String videoLink;
  String detailedContent = '';
  bool isAddedToCalendar = false;

  StudyDay({
    required this.dayNumber,
    required this.title,
    required this.duration,
    required this.videoLink,
  });
}

import 'package:timezone_finder/timezone_finder.dart';

void main() async {
  final latitude = 42.7; //41.29708;
  final longitude = 23.316667; //2.07846;

  final stopwatch = Stopwatch()..start();

  final timeZoneFinder = TimeZoneFinder();
  final timeZoneName = await timeZoneFinder.findTimeZoneName(latitude, longitude);

  stopwatch.stop();

  print(timeZoneName); // Europe/Madrid

  print(stopwatch.elapsed); // 0:00:04.65682
}

import 'package:intl/intl.dart';

class TimeUtils {

  static int getCurrentTimeMilliSeconds(){
    return new DateTime.now().millisecondsSinceEpoch;
  }

  static DateTime getDateTime(int timestamp) {
    return new DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  }

  static String getDateTimeString(int timestamp) {
    DateTime date = new DateTime.fromMillisecondsSinceEpoch(timestamp);
    DateFormat format = new DateFormat("Hms");
    return format.format(date);
  }

  static int getTimeDiff(int oldTimeStamp, int newTimeStamp) {
    int diff = newTimeStamp - oldTimeStamp;
    return diff.abs();
  }

}
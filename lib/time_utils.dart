import 'package:timeago/timeago.dart' as Formater;
class TimeUtils {

  static int getCurrentTimeMilliSeconds(){

    return new DateTime.now().millisecondsSinceEpoch;
  }

  static DateTime getDateTime(int timestamp) {
    return new DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
  }

  static String getFormattedDate(int timestamp) {
    DateTime date = new DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);
    return  Formater.format(date, locale: "de");
  }


}
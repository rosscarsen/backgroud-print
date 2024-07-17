class EscHelper {
  static alginCeterPrint({int? width, dynamic content}) {
    String str = content.toString();
    int strLength = strWidth(str);
    int hlafWith = ((width! - strLength) ~/ 2);
    String space = '';
    for (int i = 0; i < hlafWith; i++) {
      space += ' ';
    }
    return space + content;
  }

  static int strWidth(dynamic content) {
    int lenght = 0;
    String str = content.toString();
    List<int> assciiList = str.codeUnits;
    for (int i = 0; i < assciiList.length; i++) {
      if (assciiList[i] >= 0 && assciiList[i] <= 255) {
        lenght++;
      } else {
        lenght += 2;
      }
    }
    return lenght;
  }

  static String fillSpace(int lenght) {
    String space = '';
    for (int i = 0; i < lenght; i++) {
      space += ' ';
    }
    return space;
  }

  static String fillhr({int? lenght, String? ch = '-'}) {
    String space = '';
    for (int i = 0; i < lenght!; i++) {
      space += '-';
    }
    return space;
  }

  static List<String> strToList(
      {required String str, required int splitLenth}) {
    String content = str.trim();
    int blankNum = splitLenth + 1;
    int strLenth = content.length;
    //String space = "";
    int m = 0;
    int j = 1;
    List<String> strList = [];
    String tail = "";
    for (int i = 0; i < strLenth; i++) {
      var newStr = content.substring(m, m + j);
      j++;
      if (strWidth(newStr) < blankNum) {
        if (m + j > strLenth) {
          m = m + j;
          tail = newStr;
          // int spaceLenth = splitLenth - strWidth(newStr);
          // for (var q = 0; q < spaceLenth; q++) {
          //   space += ' ';
          // }
          // tail += space;
          break;
        } else {
          var nextNewStr = content.substring(m, j + m);
          if (strWidth(nextNewStr) < blankNum) {
            continue;
          } else {
            m = i + 1;
            strList.add(newStr);
            j = 1;
          }
        }
      }
    }
    if (tail.isNotEmpty) {
      strList.add(tail);
    }
    return strList;
  }
}

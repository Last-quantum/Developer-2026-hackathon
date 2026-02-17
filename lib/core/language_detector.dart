/// 语言检测工具类
class LanguageDetector {
  /// 检测输入文本的主要语言
  /// 返回 'zh' (中文) 或 'en' (英文) 或 'mixed' (混合)
  static String detectLanguage(String text) {
    if (text.isEmpty) return 'en';

    final trimmed = text.trim();
    
    // 计数：中文字符、英文字符
    int chineseCount = 0;
    int englishCount = 0;

    for (final rune in trimmed.runes) {
      if (_isChinese(rune)) {
        chineseCount++;
      } else if (_isEnglish(rune)) {
        englishCount++;
      }
    }

    // 如果中文占比 > 50%，认为是中文
    // 如果英文占比 > 50%，认为是英文
    // 否则是混合语言
    final totalCount = chineseCount + englishCount;
    if (totalCount == 0) return 'en'; // 全是符号/数字

    if (chineseCount > totalCount * 0.5) {
      return 'zh';
    } else if (englishCount > totalCount * 0.5) {
      return 'en';
    } else {
      return 'mixed';
    }
  }

  /// 判断是否为中文字符（CJK Unified Ideographs）
  static bool _isChinese(int rune) {
    return (rune >= 0x4E00 && rune <= 0x9FFF) || // CJK 统一表意文字
        (rune >= 0x3400 && rune <= 0x4DBF) ||   // CJK 扩展A
        (rune >= 0x20000 && rune <= 0x2A6DF) || // CJK 扩展B
        (rune >= 0x2A700 && rune <= 0x2B73F) || // CJK 扩展C
        (rune >= 0xF900 && rune <= 0xFAFF);     // CJK 兼容表意文字
  }

  /// 判断是否为英文字符（A-Z, a-z）
  static bool _isEnglish(int rune) {
    return (rune >= 0x41 && rune <= 0x5A) ||  // A-Z
        (rune >= 0x61 && rune <= 0x7A);       // a-z
  }

  /// 构建针对特定语言的提示词
  /// 如果是中文输入，就用中文提示词；如果是英文输入，就用英文提示词
  static String buildLocalizedPrompt(String input, String chinesePrompt, String englishPrompt) {
    final lang = detectLanguage(input);
    return lang == 'zh' ? chinesePrompt : englishPrompt;
  }
}

import 'package:google_generative_ai/google_generative_ai.dart';
import '../constants/app_constants.dart';
import 'secure_storage_service.dart';

class AiFinancialAdvisorService {
  static final AiFinancialAdvisorService instance = AiFinancialAdvisorService._init();
  
  final SecureStorageService _storage = SecureStorageService.instance;
  GenerativeModel? _model;

  AiFinancialAdvisorService._init();

  Future<void> initialize() async {
    final apiKey = await _storage.getGeminiApiKey();
    if (apiKey != null && apiKey.isNotEmpty) {
      _model = GenerativeModel(
        model: AppConstants.geminiModel,
        apiKey: apiKey,
      );
    } else {
      _model = null;
    }
  }

  Future<void> setApiKey(String apiKey) async {
    await _storage.saveGeminiApiKey(apiKey);
    _model = GenerativeModel(
      model: AppConstants.geminiModel,
      apiKey: apiKey,
    );
  }

  bool get isConfigured => _model != null;

  /// Generate AI financial suggestions based on monthly financial data
  /// Returns suggestions in the requested language (en/th)
  Future<String?> generateFinancialSuggestions({
    required double income,
    required double expense,
    required double netBalance,
    required Map<String, double> incomeCategories,
    required Map<String, double> expenseCategories,
    required String language, // 'en' or 'th'
  }) async {
    if (_model == null) {
      return null;
    }

    try {
      // Determine financial health status
      final double cashFlowRatio = income > 0 ? (expense / income) : 0.0;
      final isCritical = netBalance < 0 || cashFlowRatio > 0.9;
      final isHealthy = netBalance > 0 && cashFlowRatio < 0.7;
      
      // Build financial summary
      final incomeSummary = incomeCategories.entries
          .map((e) => '${e.key}: ${e.value.toStringAsFixed(2)}')
          .join(', ');
      final expenseSummary = expenseCategories.entries
          .map((e) => '${e.key}: ${e.value.toStringAsFixed(2)}')
          .join(', ');

      final prompt = language == 'th' ? _buildThaiPrompt(
        income: income,
        expense: expense,
        netBalance: netBalance,
        cashFlowRatio: cashFlowRatio,
        isCritical: isCritical,
        isHealthy: isHealthy,
        incomeSummary: incomeSummary,
        expenseSummary: expenseSummary,
      ) : _buildEnglishPrompt(
        income: income,
        expense: expense,
        netBalance: netBalance,
        cashFlowRatio: cashFlowRatio,
        isCritical: isCritical,
        isHealthy: isHealthy,
        incomeSummary: incomeSummary,
        expenseSummary: expenseSummary,
      );

      // Log the actual data being sent to AI for debugging
      print('🤖 AI Advisor - Sending real financial data:');
      print('   Income: ${income.toStringAsFixed(2)} THB');
      print('   Expense: ${expense.toStringAsFixed(2)} THB');
      print('   Net Balance: ${netBalance.toStringAsFixed(2)} THB');
      print('   Income Categories: $incomeCategories');
      print('   Expense Categories: $expenseCategories');
      
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      
      final suggestions = response.text?.trim();
      
      // Log the response to verify it's real, not mockup
      if (suggestions != null) {
        print('🤖 AI Advisor - Received suggestions (${suggestions.length} chars)');
        print('   Preview: ${suggestions.substring(0, suggestions.length > 100 ? 100 : suggestions.length)}...');
      } else {
        print('🤖 AI Advisor - No suggestions received');
      }
      
      return suggestions;
    } catch (e) {
      print('🤖 AI Advisor Error: $e');
      return null;
    }
  }

  String _buildEnglishPrompt({
    required double income,
    required double expense,
    required double netBalance,
    required double cashFlowRatio,
    required bool isCritical,
    required bool isHealthy,
    required String incomeSummary,
    required String expenseSummary,
  }) {
    return '''
You are a financial advisor AI. Analyze the following monthly financial data and provide personalized recommendations:

**Financial Summary:**
- Monthly Income: ${income.toStringAsFixed(2)} THB
- Monthly Expense: ${expense.toStringAsFixed(2)} THB
- Net Balance: ${netBalance.toStringAsFixed(2)} THB
- Cash Flow Ratio: ${(cashFlowRatio * 100).toStringAsFixed(1)}%
- Status: ${isCritical ? 'CRITICAL - Cash flow is very low' : isHealthy ? 'HEALTHY' : 'CAUTION - Monitor spending'}

**Income Breakdown:**
$incomeSummary

**Expense Breakdown:**
$expenseSummary

**Your Task:**
Provide personalized financial advice based on THIS USER'S ACTUAL DATA shown above. Do NOT use generic examples or mockup data. Analyze their REAL financial situation and give REAL recommendations.

Include:

1. **Cash Flow Analysis**: Assess THIS USER'S current financial health based on their actual income (${income.toStringAsFixed(2)} THB) and expenses (${expense.toStringAsFixed(2)} THB). Identify specific issues based on their data.

2. **Long-term Investment Suggestions**: Based on their actual net balance (${netBalance.toStringAsFixed(2)} THB), recommend REAL investment options. Only suggest investments if they have positive cash flow. Do NOT use placeholder examples like "JPY" or "Dogecoin" unless you have current, real market data.

3. **Short-term Opportunities**: Based on their actual spending patterns (${expenseSummary.isEmpty ? 'no expense data' : expenseSummary}), suggest REAL ways to improve their financial situation.

**CRITICAL GUIDELINES:**
- Use ONLY the user's REAL financial data provided above
- Do NOT include generic examples or mockup suggestions
- Do NOT mention "JPY", "Dogecoin", or other specific investments unless you have verified current market data
- Focus on actionable advice based on their ACTUAL numbers
- If cash flow is critical (net balance: ${netBalance.toStringAsFixed(2)} THB), emphasize increasing income or reducing expenses
- Be specific to their situation, not generic
- Keep response under 200 words

**Response Format:**
Provide only personalized advice text based on their real data. No markdown, no titles, just plain text paragraphs.
''';
  }

  String _buildThaiPrompt({
    required double income,
    required double expense,
    required double netBalance,
    required double cashFlowRatio,
    required bool isCritical,
    required bool isHealthy,
    required String incomeSummary,
    required String expenseSummary,
  }) {
    return '''
คุณเป็นที่ปรึกษาทางการเงิน AI กรุณาวิเคราะห์ข้อมูลทางการเงินรายเดือนต่อไปนี้และให้คำแนะนำส่วนบุคคล:

**สรุปทางการเงิน:**
- รายได้รายเดือน: ${income.toStringAsFixed(2)} บาท
- ค่าใช้จ่ายรายเดือน: ${expense.toStringAsFixed(2)} บาท
- ยอดคงเหลือสุทธิ: ${netBalance.toStringAsFixed(2)} บาท
- อัตราส่วนกระแสเงินสด: ${(cashFlowRatio * 100).toStringAsFixed(1)}%
- สถานะ: ${isCritical ? 'วิกฤต - กระแสเงินสดต่ำมาก' : isHealthy ? 'สุขภาพดี' : 'ระวัง - ควรติดตามการใช้จ่าย'}

**รายละเอียดรายได้:**
$incomeSummary

**รายละเอียดค่าใช้จ่าย:**
$expenseSummary

**งานของคุณ:**
ให้คำแนะนำทางการเงินส่วนบุคคลตามข้อมูลจริงของผู้ใช้ที่แสดงด้านบน อย่าใช้ตัวอย่างทั่วไปหรือข้อมูลจำลอง วิเคราะห์สถานการณ์ทางการเงินจริงของผู้ใช้และให้คำแนะนำจริง

รวมถึง:

1. **การวิเคราะห์กระแสเงินสด**: ประเมินสุขภาพทางการเงินปัจจุบันของผู้ใช้ตามรายได้จริง (${income.toStringAsFixed(2)} บาท) และค่าใช้จ่ายจริง (${expense.toStringAsFixed(2)} บาท) ระบุปัญหาที่เฉพาะเจาะจงตามข้อมูลจริง

2. **คำแนะนำการลงทุนระยะยาว**: ตามยอดคงเหลือสุทธิจริง (${netBalance.toStringAsFixed(2)} บาท) แนะนำตัวเลือกการลงทุนจริง เฉพาะเมื่อมีกระแสเงินสดบวกเท่านั้น อย่าใช้ตัวอย่างจำลองเช่น "JPY" หรือ "Dogecoin" เว้นแต่คุณมีข้อมูลตลาดปัจจุบันจริง

3. **โอกาสระยะสั้น**: ตามรูปแบบการใช้จ่ายจริง (${expenseSummary.isEmpty ? 'ไม่มีข้อมูลค่าใช้จ่าย' : expenseSummary}) แนะนำวิธีจริงในการปรับปรุงสถานการณ์ทางการเงิน

**แนวทางสำคัญ:**
- ใช้เฉพาะข้อมูลทางการเงินจริงของผู้ใช้ที่ให้ไว้ด้านบนเท่านั้น
- อย่ารวมตัวอย่างทั่วไปหรือคำแนะนำจำลอง
- อย่า mention "JPY", "Dogecoin" หรือการลงทุนเฉพาะอื่นๆ เว้นแต่คุณมีข้อมูลตลาดปัจจุบันที่ยืนยันแล้ว
- มุ่งเน้นคำแนะนำที่ปฏิบัติได้ตามตัวเลขจริงของพวกเขา
- หากกระแสเงินสดวิกฤต (ยอดคงเหลือสุทธิ: ${netBalance.toStringAsFixed(2)} บาท) ให้เน้นการเพิ่มรายได้หรือลดค่าใช้จ่าย
- เฉพาะเจาะจงกับสถานการณ์ของพวกเขา ไม่ใช่ทั่วไป
- จำกัดคำตอบไว้ที่ 200 คำ

**รูปแบบการตอบ:**
ให้เฉพาะข้อความคำแนะนำส่วนบุคคลตามข้อมูลจริงของพวกเขา ไม่มี markdown ไม่มีหัวข้อ แค่ย่อหน้าข้อความธรรมดา
''';
  }
}


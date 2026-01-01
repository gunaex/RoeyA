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

  /// Generate AI insight for a specific category
  Future<String?> generateCategoryInsight({
    required String category,
    required double total,
    required Map<DateTime, double> history,
    required String language,
  }) async {
    if (_model == null) return null;

    try {
      // Build history summary
      final historyEntries = history.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      final historySummary = historyEntries
          .map((e) => '${e.key.year}-${e.key.month.toString().padLeft(2, '0')}: ${e.value.toStringAsFixed(2)} THB')
          .join('\n');

      final prompt = language == 'th' ? '''
คุณเป็นที่ปรึกษาทางการเงิน AI วิเคราะห์ข้อมูลหมวดหมู่ "${category}":

**ข้อมูลหมวดหมู่:**
- หมวดหมู่: $category
- ยอดรวมปัจจุบัน: ${total.toStringAsFixed(2)} THB
- ประวัติ 3-6 เดือน:
$historySummary

**งานของคุณ:**
วิเคราะห์แนวโน้มการใช้จ่ายในหมวดหมู่นี้และให้คำแนะนำเฉพาะเจาะจง:
1. แนวโน้มการใช้จ่าย (เพิ่มขึ้น/ลดลง/คงที่)
2. การเปรียบเทียบกับเดือนก่อนหน้า
3. คำแนะนำในการจัดการหมวดหมู่นี้
4. เคล็ดลับในการประหยัด (ถ้าเป็นค่าใช้จ่าย)

ให้คำตอบสั้นๆ ประมาณ 100-150 คำ ไม่มี markdown แค่ข้อความธรรมดา
''' : '''
You are a financial advisor AI. Analyze the following category data:

**Category Information:**
- Category: $category
- Current Total: ${total.toStringAsFixed(2)} THB
- 3-6 Month History:
$historySummary

**Your Task:**
Analyze spending trends for this category and provide specific insights:
1. Spending trend (increasing/decreasing/stable)
2. Comparison with previous months
3. Recommendations for managing this category
4. Savings tips (if expense category)

Keep response concise, 100-150 words. No markdown, just plain text.
''';

      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      return response.text?.trim();
    } catch (e) {
      print('🤖 AI Category Insight Error: $e');
      return null;
    }
  }

  /// Generate AI insight for a single transaction
  Future<String?> generateTransactionInsight({
    required String description,
    required double amount,
    required String? category,
    required String? accountName,
    required DateTime date,
    required String type,
    required String language,
  }) async {
    if (_model == null) return null;

    try {
      final prompt = language == 'th' ? '''
คุณเป็นที่ปรึกษาทางการเงิน AI วิเคราะห์รายการธุรกรรมนี้:

**รายการธุรกรรม:**
- คำอธิบาย: $description
- จำนวนเงิน: ${amount.toStringAsFixed(2)} THB
- หมวดหมู่: ${category ?? 'ไม่ระบุ'}
- บัญชี: ${accountName ?? 'ไม่ระบุ'}
- วันที่: ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}
- ประเภท: ${type == 'income' ? 'รายได้' : 'ค่าใช้จ่าย'}

**งานของคุณ:**
วิเคราะห์รายการนี้และให้คำแนะนำ:
1. รายการนี้เหมาะสมหรือไม่?
2. มีวิธีประหยัดหรือเพิ่มมูลค่าได้หรือไม่?
3. คำแนะนำสำหรับรายการคล้ายๆ กันในอนาคต

ให้คำตอบสั้นๆ ประมาณ 80-120 คำ ไม่มี markdown แค่ข้อความธรรมดา
''' : '''
You are a financial advisor AI. Analyze this transaction:

**Transaction Details:**
- Description: $description
- Amount: ${amount.toStringAsFixed(2)} THB
- Category: ${category ?? 'Not specified'}
- Account: ${accountName ?? 'Not specified'}
- Date: ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}
- Type: ${type == 'income' ? 'Income' : 'Expense'}

**Your Task:**
Analyze this transaction and provide insights:
1. Is this transaction reasonable?
2. Any ways to save money or increase value?
3. Recommendations for similar transactions in the future

Keep response concise, 80-120 words. No markdown, just plain text.
''';

      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      return response.text?.trim();
    } catch (e) {
      print('🤖 AI Transaction Insight Error: $e');
      return null;
    }
  }

  /// Simulate a financial scenario
  Future<String?> simulateScenario({
    required double currentIncome,
    required double currentExpense,
    required double? targetSaving,
    double? targetPurchaseAmount,
    int? timeframeMonths,
    required Map<String, double>? categoryReductions,
    required String language,
  }) async {
    if (_model == null) return null;

    try {
      final reductionSummary = categoryReductions?.entries
          .map((e) => '${e.key}: reduce by ${e.value.toStringAsFixed(1)}%')
          .join(', ') ?? 'None';

      // Build goal description
      String goalDescription = '';
      if (targetPurchaseAmount != null && timeframeMonths != null) {
        final monthlyNeeded = targetPurchaseAmount / timeframeMonths;
        goalDescription = language == 'th' 
          ? '- **เป้าหมายการซื้อ:** ${targetPurchaseAmount.toStringAsFixed(2)} THB ภายใน ${timeframeMonths} เดือน\n'
            '- **ต้องออมรายเดือน:** ${monthlyNeeded.toStringAsFixed(2)} THB/เดือน\n'
            '- **คำถาม:** จะทำอย่างไรให้ได้เงินจำนวนนี้เร็วที่สุด?\n'
          : '- **Purchase Goal:** ${targetPurchaseAmount.toStringAsFixed(2)} THB within ${timeframeMonths} months\n'
            '- **Monthly Saving Needed:** ${monthlyNeeded.toStringAsFixed(2)} THB/month\n'
            '- **Question:** How can I achieve this fastest?\n';
      } else if (targetSaving != null) {
        goalDescription = language == 'th'
          ? '- เป้าหมายการออม: ${targetSaving.toStringAsFixed(2)} THB/เดือน\n'
          : '- Target Saving: ${targetSaving.toStringAsFixed(2)} THB/month\n';
      }

      final prompt = language == 'th' ? '''
คุณเป็นที่ปรึกษาทางการเงิน AI จำลองสถานการณ์ทางการเงิน:

**สถานการณ์ปัจจุบัน:**
- รายได้รายเดือน: ${currentIncome.toStringAsFixed(2)} THB
- ค่าใช้จ่ายรายเดือน: ${currentExpense.toStringAsFixed(2)} THB
- ยอดคงเหลือสุทธิ: ${(currentIncome - currentExpense).toStringAsFixed(2)} THB

**เป้าหมาย:**
${goalDescription.isNotEmpty ? goalDescription : '- ไม่มีเป้าหมายการออมเฉพาะ'}
${categoryReductions != null && categoryReductions.isNotEmpty ? '- ลดค่าใช้จ่ายตามหมวดหมู่:\n$reductionSummary' : ''}

**งานของคุณ:**
วิเคราะห์ความเป็นไปได้และสร้างแผนการ:
1. สรุปความเป็นไปได้ (ทำได้/ทำได้แต่ยาก/ทำไม่ได้)
2. แผนการปรับปรุงแบบทีละขั้นตอน:
   - ปรับอะไรบ้าง (เพิ่มรายได้/ลดค่าใช้จ่าย/ทั้งสองอย่าง)
   - ปรับเท่าไหร่
   - ระยะเวลาเท่าไหร่
   ${targetPurchaseAmount != null ? '- วิธีที่เร็วที่สุดในการได้เงินจำนวนนี้:' : ''}
3. คำแนะนำเพิ่มเติม (เช่น หารายได้เสริม, ลดค่าใช้จ่ายที่ไม่จำเป็น, ลงทุน)

ให้คำตอบเป็นข้อความโครงสร้างชัดเจน ประมาณ 250-300 คำ
''' : '''
You are a financial advisor AI. Simulate this financial scenario:

**Current Situation:**
- Monthly Income: ${currentIncome.toStringAsFixed(2)} THB
- Monthly Expense: ${currentExpense.toStringAsFixed(2)} THB
- Net Balance: ${(currentIncome - currentExpense).toStringAsFixed(2)} THB

**Goals:**
${goalDescription.isNotEmpty ? goalDescription : '- No specific saving target'}
${categoryReductions != null && categoryReductions.isNotEmpty ? '- Category Reductions:\n$reductionSummary' : ''}

**Your Task:**
Analyze feasibility and create an action plan:
1. Feasibility summary (Achievable/Challenging but possible/Not achievable)
2. Step-by-step improvement plan:
   - What to adjust (increase income/reduce expenses/both)
   - How much to adjust
   - Timeline
   ${targetPurchaseAmount != null ? '- Fastest way to achieve this amount:' : ''}
3. Additional recommendations (e.g., side income, cut unnecessary expenses, investments)

Provide structured response, 250-300 words.
''';

      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      return response.text?.trim();
    } catch (e) {
      print('🤖 AI Scenario Simulation Error: $e');
      return null;
    }
  }

  /// Generate AI insight for outlier transactions
  Future<String?> generateOutlierInsight({
    required List<Map<String, dynamic>> outliers,
    required String language,
  }) async {
    if (_model == null) return null;

    try {
      final outlierSummary = outliers
          .take(10)
          .map((tx) => '${tx['description'] ?? 'No description'}: ${tx['amount']} ${tx['currencyCode']} (${tx['category'] ?? 'No category'})')
          .join('\n');

      final prompt = language == 'th' ? '''
คุณเป็นที่ปรึกษาทางการเงิน AI วิเคราะห์รายการผิดปกติ:

**รายการผิดปกติ (${outliers.length} รายการ):**
$outlierSummary

**งานของคุณ:**
วิเคราะห์และอธิบาย:
1. เหตุใดรายการเหล่านี้จึงผิดปกติ
2. มีสาเหตุที่เป็นไปได้อะไรบ้าง
3. คำแนะนำในการจัดการ

ให้คำตอบสั้นๆ ประมาณ 150-200 คำ
''' : '''
You are a financial advisor AI. Analyze these unusual transactions:

**Unusual Transactions (${outliers.length} items):**
$outlierSummary

**Your Task:**
Analyze and explain:
1. Why these transactions are unusual
2. Possible causes
3. Recommendations for handling

Keep response concise, 150-200 words.
''';

      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);
      return response.text?.trim();
    } catch (e) {
      print('🤖 AI Outlier Insight Error: $e');
      return null;
    }
  }
}


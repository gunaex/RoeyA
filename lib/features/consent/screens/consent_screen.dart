import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:roeyp/core/constants/app_constants.dart';
import 'package:roeyp/core/localization/app_localizations.dart';
import 'package:roeyp/core/localization/locale_provider.dart';
import 'package:roeyp/core/services/secure_storage_service.dart';
import 'package:roeyp/core/theme/app_colors.dart';
import 'package:roeyp/shared/widgets/app_button.dart';

class ConsentScreen extends StatefulWidget {
  const ConsentScreen({super.key});

  @override
  State<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends State<ConsentScreen> {
  bool _hasAccepted = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProvider = Provider.of<LocaleProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.consentTitle),
        actions: [
          // Language Switcher
          PopupMenuButton<String>(
            icon: const Icon(Icons.language),
            onSelected: (languageCode) {
              localeProvider.setLocale(Locale(languageCode));
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'en',
                child: Text('English'),
              ),
              const PopupMenuItem(
                value: 'th',
                child: Text('ไทย'),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Icon
                    Center(
                      child: Icon(
                        Icons.privacy_tip_outlined,
                        size: 80,
                        color: AppColors.primary,
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Title
                    Text(
                      l10n.consentTitle,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Message
                    Text(
                      l10n.consentMessage,
                      style: Theme.of(context).textTheme.bodyLarge,
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Data Collection Notice
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.info.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.info_outline, size: 20, color: AppColors.info),
                              const SizedBox(width: 8),
                              Text(
                                l10n.dataCollectionTitle,
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      color: AppColors.info,
                                    ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _buildDataItem(
                            context,
                            l10n.dataCollectionAccount,
                          ),
                          _buildDataItem(
                            context,
                            l10n.dataCollectionFinancial,
                          ),
                          _buildDataItem(
                            context,
                            l10n.dataCollectionLocation,
                          ),
                          _buildDataItem(
                            context,
                            l10n.dataCollectionMedia,
                          ),
                          _buildDataItem(
                            context,
                            l10n.dataCollectionAI,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Privacy Policy Card
                    _buildLinkCard(
                      context,
                      l10n.privacyPolicy,
                      Icons.shield_outlined,
                      () {
                        _showPrivacyPolicy(context);
                      },
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Terms of Use Card
                    _buildLinkCard(
                      context,
                      l10n.termsOfUse,
                      Icons.description_outlined,
                      () {
                        _showTermsOfUse(context);
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Key Points
                    _buildKeyPoint(
                      context,
                      'Your data stays on your device',
                      Icons.phone_android,
                    ),
                    const SizedBox(height: 12),
                    _buildKeyPoint(
                      context,
                      'No forced cloud sync',
                      Icons.cloud_off,
                    ),
                    const SizedBox(height: 12),
                    _buildKeyPoint(
                      context,
                      'You own and control your data',
                      Icons.verified_user,
                    ),
                    const SizedBox(height: 12),
                    _buildKeyPoint(
                      context,
                      'AI features require your own API key',
                      Icons.key,
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom Section
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: const BoxDecoration(
                color: AppColors.surface,
                border: Border(
                  top: BorderSide(color: AppColors.border),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Checkbox
                  CheckboxListTile(
                    value: _hasAccepted,
                    onChanged: (value) {
                      setState(() {
                        _hasAccepted = value ?? false;
                      });
                    },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      l10n.consentCheckbox,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Buttons
                  Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: l10n.decline,
                          isOutlined: true,
                          onPressed: _isLoading ? null : () {
                            _showDeclineDialog(context);
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: AppButton(
                          text: l10n.accept,
                          isLoading: _isLoading,
                          onPressed: _hasAccepted ? _handleAccept : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLinkCard(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textHint),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeyPoint(BuildContext context, String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.success),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
  
  Widget _buildDataItem(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(fontSize: 16)),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleAccept() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final localeProvider = Provider.of<LocaleProvider>(context, listen: false);
      
      await SecureStorageService.instance.saveConsentData(
        version: AppConstants.consentVersion,
        language: localeProvider.locale.languageCode,
        timestamp: DateTime.now(),
      );

      if (mounted) {
        Navigator.pushReplacementNamed(context, AppConstants.routeCreatePin);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showDeclineDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.cannotContinue),
        content: Text(l10n.declineMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.ok),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicy(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const PrivacyPolicyDialog(),
    );
  }

  void _showTermsOfUse(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const TermsOfUseDialog(),
    );
  }
}

class PrivacyPolicyDialog extends StatelessWidget {
  const PrivacyPolicyDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final isThai = localeProvider.locale.languageCode == 'th';
    
    return AlertDialog(
      title: Text(isThai ? 'นโยบายความเป็นส่วนตัว' : 'Privacy Policy'),
      content: SingleChildScrollView(
        child: Text(
          isThai ? _privacyPolicyTH : _privacyPolicyEN,
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(isThai ? 'ปิด' : 'Close'),
        ),
      ],
    );
  }
}

class TermsOfUseDialog extends StatelessWidget {
  const TermsOfUseDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final localeProvider = Provider.of<LocaleProvider>(context);
    final isThai = localeProvider.locale.languageCode == 'th';
    
    return AlertDialog(
      title: Text(isThai ? 'ข้อกำหนดการใช้งาน' : 'Terms of Service'),
      content: SingleChildScrollView(
        child: Text(
          isThai ? _termsOfServiceTH : _termsOfServiceEN,
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(isThai ? 'ปิด' : 'Close'),
        ),
      ],
    );
  }
}

const String _privacyPolicyTH = '''
บริษัท/ผู้ให้บริการ (“เรา”) ให้ความสำคัญกับการคุ้มครองข้อมูลส่วนบุคคลของผู้ใช้ (“ท่าน”) ตามพระราชบัญญัติคุ้มครองข้อมูลส่วนบุคคล พ.ศ. 2562 (PDPA)

1. การเก็บรวบรวมข้อมูลส่วนบุคคล
เราอาจเก็บรวบรวมข้อมูลดังต่อไปนี้:
• ข้อมูลระบุตัวตน (เช่น ชื่อผู้ใช้ อีเมล)
• ข้อมูลการเงินและการบันทึกบัญชี
• ข้อมูลการใช้งาน (เช่น ประวัติการใช้งาน การเชื่อมต่ออุปกรณ์)
• ข้อมูลทางเทคนิค (เช่น IP Address, ประเภทอุปกรณ์)
• ตำแหน่งของอุปกรณ์ (จากรูปถ่าย)
• ข้อมูล AI/Chat (การโต้ตอบเพื่อปรับปรุงระบบ)

2. วัตถุประสงค์ในการใช้ข้อมูล
เราใช้ข้อมูลของท่านเพื่อ:
• ให้บริการและพัฒนาระบบ
• ติดต่อสื่อสารและแจ้งข้อมูลที่เกี่ยวข้อง
• วิเคราะห์และปรับปรุงประสบการณ์ผู้ใช้
• ปฏิบัติตามกฎหมายที่เกี่ยวข้อง

3. การเปิดเผยข้อมูล
เราจะไม่เปิดเผยข้อมูลส่วนบุคคลของท่านแก่บุคคลภายนอก เว้นแต่:
• ได้รับความยินยอมจากท่าน
• เป็นไปตามที่กฎหมายกำหนด
• จำเป็นต่อการให้บริการ (เช่น ผู้ให้บริการระบบ)

4. การเก็บรักษาข้อมูล
เราจะเก็บรักษาข้อมูลส่วนบุคคลของท่านตามระยะเวลาที่จำเป็น และใช้มาตรการรักษาความปลอดภัยที่เหมาะสม

5. สิทธิของเจ้าของข้อมูล
ท่านมีสิทธิ:
• ขอเข้าถึง แก้ไข หรือลบข้อมูล
• ถอนความยินยอม
• ร้องเรียนต่อหน่วยงานที่เกี่ยวข้องตามกฎหมาย
''';

const String _privacyPolicyEN = '''
We (“the Service Provider”) respect your privacy and are committed to protecting your personal data in accordance with the Thailand Personal Data Protection Act B.E. 2562 (PDPA).

1. Personal Data We Collect
We may collect the following information:
• Identifiable information (e.g., username, email, password)
• Financial and expense tracking data
• Usage data (e.g., app activity, device connection)
• Technical data (e.g., IP address, device type)
• Device location (from uploaded photos)
• AI/Chat generated data

2. Purpose of Data Processing
Your personal data is used to:
• Provide and improve our services
• Communicate relevant information
• Analyze usage to enhance user experience
• Comply with applicable laws

3. Data Disclosure
We will not disclose your personal data to third parties except:
• With your consent
• As required by law
• When necessary for service operation

4. Data Retention and Security
We retain your data only as long as necessary and apply appropriate security measures.

5. Your Rights
You have the right to access, correct, delete your data, withdraw consent, and file complaints under applicable laws.
''';

const String _termsOfServiceTH = '''
1. การยอมรับข้อตกลง
การใช้งานแอปพลิเคชัน/เว็บไซต์นี้ถือว่าท่านยอมรับข้อกำหนดการใช้งานทั้งหมด

2. การใช้งานที่เหมาะสม
ผู้ใช้ตกลงว่าจะไม่:
• ใช้งานในทางที่ผิดกฎหมาย
• ละเมิดสิทธิของผู้อื่น
• พยายามเข้าถึงระบบโดยไม่ได้รับอนุญาต

3. ทรัพย์สินทางปัญญา
เนื้อหา ระบบ และซอฟต์แวร์ทั้งหมดเป็นทรัพย์สินของผู้ให้บริการ ห้ามคัดลอกหรือใช้โดยไม่ได้รับอนุญาต

4. การจำกัดความรับผิด
เราไม่รับผิดชอบต่อความเสียหายที่เกิดจากการใช้งาน เว้นแต่เป็นกรณีที่กฎหมายกำหนด

5. การเปลี่ยนแปลงข้อตกลง
เราขอสงวนสิทธิ์ในการแก้ไขข้อกำหนดโดยไม่ต้องแจ้งล่วงหน้า
''';

const String _termsOfServiceEN = '''
1. Acceptance of Terms
By using this application/website, you agree to these Terms of Service.

2. Proper Use
Users must not:
• Use the service unlawfully
• Violate others’ rights
• Attempt unauthorized system access

3. Intellectual Property
All content and software are the property of the Service Provider and may not be used without permission.

4. Limitation of Liability
We are not liable for damages arising from use of the service, except as required by law.

5. Changes to Terms
We reserve the right to modify these terms at any time.
''';

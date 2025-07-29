import 'package:flutter/material.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          '隐私政策',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 标题
                const Center(
                  child: Text(
                    '隐私政策',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    '生效日期：2025年7月1日',
                    style: TextStyle(
                      fontSize: 14,
                      color: Color(0xFF666666),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // 开头段落
                _buildParagraph(
                  '本隐私协议旨在说明"秒遇"（以下简称"本应用"）在收集、使用、存储和共享您的个人信息时所遵循的原则和做法。请您在使用本应用前，仔细阅读本隐私协议。',
                ),
                
                const SizedBox(height: 24),
                
                // 一、我们收集的信息
                _buildSection(
                  title: '一、我们收集的信息',
                  subsections: [
                    {
                      'title': '（一）注册与登录信息',
                      'content': '当您注册或登录本应用时，我们会收集您提供的手机号码、电子邮箱地址、用户名、密码等信息，用于创建和管理您的账户。'
                    },
                    {
                      'title': '（二）个人资料信息',
                      'content': '您可以选择完善个人资料，包括但不限于真实姓名、性别、出生日期、头像、个人简介等。这些信息将帮助其他用户更好地了解您，同时用于个性化的内容推荐。'
                    },
                    {
                      'title': '（三）位置信息',
                      'content': '为了方便您找到附近的演唱会搭子，我们可能会在您授权的情况下，收集您的地理位置信息。您可以随时在设备设置中关闭位置服务。'
                    },
                    {
                      'title': '（四）使用行为信息',
                      'content': '我们会自动记录您在使用本应用过程中的行为信息，例如浏览的演唱会信息、发布的动态内容、搜索记录、与其他用户的互动情况等。这些信息用于优化应用体验、提供更符合您需求的服务。'
                    },
                    {
                      'title': '（五）设备信息',
                      'content': '我们会收集您使用本应用的设备相关信息，包括设备型号、操作系统版本、设备标识符（如IMEI、MAC地址等）、网络连接信息等，以保障应用的正常运行和安全性。'
                    },
                  ],
                ),
                
                // 二、我们如何使用信息
                _buildSection(
                  title: '二、我们如何使用信息',
                  items: [
                    '提供和维护服务：使用收集的信息来运行、维护和改进本应用，确保您能够正常使用找搭子、发布动态等功能。',
                    '个性化推荐：根据您的个人资料、使用行为和位置信息，向您推荐相关的演唱会信息、可能感兴趣的搭子以及个性化的内容。',
                    '通信与互动：通过您提供的联系方式（如手机号码、电子邮箱），向您发送重要的通知、服务更新以及您可能感兴趣的活动信息。同时，支持您与其他用户之间的私信、评论等互动功能。',
                    '安全保障：利用收集的设备信息和使用行为信息，检测和防范安全风险，保障您的账户和个人信息安全。',
                  ],
                ),
                
                // 三、信息的共享与披露
                _buildSection(
                  title: '三、信息的共享与披露',
                  items: [
                    '共享原则：我们不会向第三方共享您的个人信息，除非获得您的明确同意，或法律法规要求必须共享。',
                    '合作方共享：在某些情况下，我们可能会与合作伙伴（如演唱会主办方、技术服务提供商等）共享必要的信息，以提供更好的服务。但我们会要求合作伙伴遵守严格的保密义务。',
                    '法律要求披露：如果我们收到法律要求（如法院传票、政府指令等），我们可能会披露您的个人信息以遵守法律规定。',
                  ],
                ),
                
                // 四、信息的存储与安全
                _buildSection(
                  title: '四、信息的存储与安全',
                  items: [
                    '存储期限：我们会在为您提供服务所必需的期限内保留您的个人信息，法律法规另有规定的除外。当您注销账户后，我们将按照相关规定删除或匿名化处理您的个人信息。',
                    '安全措施：我们采取合理的技术和管理措施，保护您的个人信息安全，防止信息泄露、丢失、被滥用等情况。但请您妥善保管自己的账户和密码信息。',
                  ],
                ),
                
                // 五、您的权利
                _buildSection(
                  title: '五、您的权利',
                  items: [
                    '访问与修改：您有权访问和修改您在本应用中提供的个人信息。您可以通过应用内的设置功能进行操作。',
                    '删除与注销：在符合法律规定的情况下，您有权要求删除您的个人信息或注销您的账户。注销账户后，您的个人信息将按照我们的规定进行处理。',
                    '撤回同意：您可以随时撤回对某些信息收集和使用的同意，但这可能会影响您使用本应用的部分功能。',
                  ],
                ),
                
                // 六、协议的变更
                _buildSection(
                  title: '六、协议的变更',
                  content: '我们可能会根据业务发展和法律法规的变化，对本隐私协议进行更新。更新后的协议会在本应用内公布，您继续使用本应用即视为同意接受变更后的协议。',
                ),
                
                const SizedBox(height: 24),
                
                // 联系我们
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFE44D).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFFFFE44D).withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.shield_outlined,
                            color: Color(0xFFFFE44D),
                            size: 20,
                          ),
                          SizedBox(width: 8),
                          Text(
                            '联系我们',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        '如您对本隐私协议有任何疑问或建议，请联系我们的客服团队：',
                        style: TextStyle(
                          fontSize: 14,
                          color: Color(0xFF666666),
                        ),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        'liangyuyi@wildtrekhk.shop',
                        style: TextStyle(
                          fontSize: 14,
                          color: const Color(0xFFFFE44D).withValues(alpha: 0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 15,
        color: Color(0xFF666666),
        height: 1.6,
      ),
    );
  }

  Widget _buildSection({
    required String title,
    String? content,
    List<String>? items,
    List<Map<String, dynamic>>? subsections,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 12),
        if (content != null)
          Text(
            content,
            style: const TextStyle(
              fontSize: 15,
              color: Color(0xFF666666),
              height: 1.6,
            ),
          ),
        if (items != null) ...[
          if (content != null) const SizedBox(height: 8),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${index + 1}. ',
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFFFFE44D),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      item,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Color(0xFF666666),
                        height: 1.6,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
        if (subsections != null) ...[
          if (content != null) const SizedBox(height: 8),
          ...subsections.asMap().entries.map((entry) {
            final index = entry.key;
            final subsection = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    subsection['title']!,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF444444),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    subsection['content']!,
                    style: const TextStyle(
                      fontSize: 15,
                      color: Color(0xFF666666),
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
        const SizedBox(height: 20),
      ],
    );
  }
} 
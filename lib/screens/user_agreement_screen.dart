import 'package:flutter/material.dart';

class UserAgreementScreen extends StatelessWidget {
  const UserAgreementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          '用户协议',
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
                    '用户协议',
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
                  '欢迎您使用"秒遇"（以下简称"本应用"）！请您在使用本应用前，仔细阅读本用户协议（以下简称"本协议"）。您使用本应用的行为即视为您已阅读、理解并同意接受本协议的全部条款。',
                ),
                
                const SizedBox(height: 24),
                
                // 一、服务内容
                _buildSection(
                  title: '一、服务内容',
                  content: '本应用旨在为用户提供演唱会找搭子、发布个人动态等服务，方便用户分享演唱会相关的经历和信息，结识志同道合的朋友。',
                ),
                
                // 二、用户注册与账户管理
                _buildSection(
                  title: '二、用户注册与账户管理',
                  items: [
                    '注册条件：您必须年满法定年龄周岁，并具备完全民事行为能力，才能注册使用本应用。在注册过程中，您应提供真实、准确、完整的信息。',
                    '账户安全：您有责任妥善保管自己的账户和密码，对通过您的账户进行的所有活动和行为负责。如发现账户被他人非法使用，应立即通知我们。',
                    '账户注销：您有权随时注销您的账户。注销后，您的账户信息将按照我们的规定进行处理，且您将无法再使用本应用的相关服务。',
                  ],
                ),
                
                // 三、用户行为规范
                _buildSection(
                  title: '三、用户行为规范',
                  items: [
                    '合法合规：您使用本应用时，应遵守中国及其他相关国家和地区的法律法规，不得从事任何违法犯罪活动。',
                    '文明使用：您发布的内容（包括但不限于动态、评论、私信等）应遵守社会公德，不得含有辱骂、诽谤、淫秽、暴力、歧视等违法或不适当的内容。',
                    '尊重知识产权：您不得在本应用上侵犯他人的知识产权，包括但不限于著作权、商标权等。未经授权，不得擅自使用他人的作品或标识。',
                    '不得滥用服务：您不得利用本应用进行恶意刷赞、刷评论、批量注册虚假账户等干扰本应用正常运行的行为。',
                  ],
                ),
                
                // 四、服务的使用与限制
                _buildSection(
                  title: '四、服务的使用与限制',
                  items: [
                    '服务使用：我们授予您有限的、可撤销的、非独占的使用本应用服务的权利。我们保留根据业务需要随时变更、暂停或终止部分或全部服务的权利，但会提前通知您。',
                    '广告与推广：本应用可能会展示广告或推广信息。您同意我们在提供服务的过程中，向您展示这些内容。',
                    '第三方服务：本应用可能会链接到第三方提供的服务或网站。对于第三方服务或网站的内容、隐私政策和使用条款，我们不承担任何责任，您在使用时应自行注意。',
                  ],
                ),
                
                // 五、知识产权声明
                _buildSection(
                  title: '五、知识产权声明',
                  content: '本应用的所有内容，包括但不限于应用程序代码、界面设计、文字、图片、音频、视频等，其知识产权归我们或相关权利人所有。未经我们事先书面同意，您不得复制、修改、传播、出售或以其他方式使用这些内容。',
                ),
                
                // 六、责任限制
                _buildSection(
                  title: '六、责任限制',
                  items: [
                    '免责声明：我们尽力提供优质、稳定的服务，但不保证本应用始终无故障、无中断。对于因不可抗力、网络故障、第三方行为等原因导致您无法正常使用服务，或造成的任何损失，我们不承担责任。',
                    '用户责任：您应对自己在本应用上的行为和发布的内容负责。如因您的行为导致我们或其他第三方遭受损失，您应承担赔偿责任。',
                  ],
                ),
                
                // 七、争议解决
                _buildSection(
                  title: '七、争议解决',
                  content: '如您与我们之间就本协议或本应用的使用发生任何争议，应首先友好协商解决；协商不成的，任何一方均有权向有管辖权的人民法院提起诉讼。\n\n本协议的解释、效力及执行均适用中华人民共和国法律（不包括冲突法规则）。',
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
                            Icons.contact_support,
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
                        '如您对本协议有任何疑问或建议，请联系我们的客服团队：',
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
        if (items != null)
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
        const SizedBox(height: 20),
      ],
    );
  }
} 
import 'package:flutter/material.dart';

class LegalDocumentsView extends StatelessWidget {
  const LegalDocumentsView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Hukuki Bilgiler'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Kullanım Şartları'),
              Tab(text: 'Gizlilik Politikası'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _LegalContent(
              title: 'Kullanım Şartları',
              sections: _termsSections,
            ),
            _LegalContent(
              title: 'Gizlilik Politikası',
              sections: _privacySections,
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalContent extends StatelessWidget {
  const _LegalContent({
    required this.title,
    required this.sections,
  });

  final String title;
  final List<_LegalSection> sections;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ColoredBox(
      color: const Color(0xFFF8F3EC),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: sections.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                title,
                style: textTheme.headlineSmall?.copyWith(
                      color: const Color(0xFF5B2C07),
                      fontWeight: FontWeight.w800,
                    ) ??
                    const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF5B2C07),
                    ),
              ),
            );
          }
          final section = sections[index - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  section.title,
                  style: textTheme.titleMedium?.copyWith(
                        color: const Color(0xFF7A4A22),
                        fontWeight: FontWeight.w700,
                      ) ??
                      const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF7A4A22),
                      ),
                ),
                const SizedBox(height: 6),
                Text(
                  section.body,
                  style: textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF4D3423),
                        height: 1.4,
                      ) ??
                      const TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: Color(0xFF4D3423),
                      ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _LegalSection {
  const _LegalSection({required this.title, required this.body});

  final String title;
  final String body;
}

const List<_LegalSection> _termsSections = [
  _LegalSection(
    title: 'Kabul ve Güncellemeler',
    body:
        'Uygulamayı indirip kullanarak bu şartları kabul etmiş olursunuz. Kurallar zaman zaman güncellenebilir; değişiklikleri uygulama içi duyurulardan takip etmek sizin sorumluluğunuzdadır.',
  ),
  _LegalSection(
    title: 'Adil Kullanım',
    body:
        'Hile, otomasyon veya oyunun dengesini bozan davranışlar yasaktır. Hesabınızın güvenliğini korumak için cihazınızı ve giriş bilgilerinizi üçüncü kişilerle paylaşmayın.',
  ),
  _LegalSection(
    title: 'Ücretli İçerikler',
    body:
        'Bazı kozmetik veya hızlandırıcı paketler ücretli olabilir. Satın alımlar mağaza sağlayıcınızın iade politikalarına tabidir. Yetkisiz ödeme tespit edilirse siparişi iptal etme hakkımız saklıdır.',
  ),
  _LegalSection(
    title: 'Sorumluluk Reddi',
    body:
        'Uygulama “olduğu gibi” sunulur. Kesintiler, veri kayıpları ya da üçüncü taraf hizmetlerinden kaynaklanan aksaklıklardan doğacak zararlardan sorumlu tutulamayız.',
  ),
];

const List<_LegalSection> _privacySections = [
  _LegalSection(
    title: 'Toplanan Veriler',
    body:
        'Oyun ilerlemeniz, skorlarınız ve isteğe bağlı olarak sağladığınız kullanıcı adı yerel olarak saklanır. Analiz ve hata raporları anonimdir ve cihaz bilgileriyle ilişkilendirilmez.',
  ),
  _LegalSection(
    title: 'Veri Kullanımı',
    body:
        'Toplanan bilgiler oyun deneyimini iyileştirmek, teknik sorunları gidermek ve yeni özellikleri planlamak için kullanılır. Veriler reklam amaçlı üçüncü taraflarla paylaşılmaz.',
  ),
  _LegalSection(
    title: 'Saklama Süresi',
    body:
        'Yerel kayıtlar cihazınızda kaldığı sürece saklanır. Bulut eşitleme tercih edildiğinde, hesabınız silinene veya 24 ay boyunca oturum açılmayana kadar veriler korunur.',
  ),
  _LegalSection(
    title: 'Haklarınız',
    body:
        'Verilerinize erişme, düzeltme ya da silme talebinde bulunabilirsiniz. Destek ekibimizle uygulama içindeki geri bildirim ekranından iletişime geçerek bu hakları kullanabilirsiniz.',
  ),
];

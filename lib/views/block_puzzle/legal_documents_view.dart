import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';

class LegalDocumentsView extends StatelessWidget {
  const LegalDocumentsView({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tr('legal.title')),
          bottom: TabBar(
            tabs: [
              Tab(text: tr('legal.tabs.terms')),
              Tab(text: tr('legal.tabs.privacy')),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _LegalContent(
              titleKey: 'legal.tabs.terms',
              sectionKeys: _termsSectionKeys,
            ),
            _LegalContent(
              titleKey: 'legal.tabs.privacy',
              sectionKeys: _privacySectionKeys,
            ),
          ],
        ),
      ),
    );
  }
}

class _LegalContent extends StatelessWidget {
  const _LegalContent({required this.titleKey, required this.sectionKeys});

  final String titleKey;
  final List<String> sectionKeys;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return ColoredBox(
      color: const Color(0xFFF8F3EC),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        itemCount: sectionKeys.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                tr(titleKey),
                style:
                    textTheme.headlineSmall?.copyWith(
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
          final sectionKey = sectionKeys[index - 1];
          return Padding(
            padding: const EdgeInsets.only(bottom: 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr('$sectionKey.title'),
                  style:
                      textTheme.titleMedium?.copyWith(
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
                  tr('$sectionKey.body'),
                  style:
                      textTheme.bodyMedium?.copyWith(
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

const List<String> _termsSectionKeys = [
  'legal.sections.terms.accept',
  'legal.sections.terms.fair_use',
  'legal.sections.terms.paid_content',
  'legal.sections.terms.liability',
];

const List<String> _privacySectionKeys = [
  'legal.sections.privacy.data_collection',
  'legal.sections.privacy.data_use',
  'legal.sections.privacy.retention',
  'legal.sections.privacy.rights',
];

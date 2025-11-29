import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsax/iconsax.dart';
import 'package:kartal/kartal.dart';
import 'package:puzzle_game/core/extension/dynamic_size.dart';
import 'package:puzzle_game/core/extension/sized_box.dart';
import 'package:puzzle_game/widgets/components/locale_menu_button.dart';

import 'block_puzzle_view.dart';
import 'level_path_view.dart';
import 'legal_documents_view.dart';

class BlockPuzzleModeView extends ConsumerStatefulWidget {
  const BlockPuzzleModeView({super.key});

  @override
  ConsumerState<BlockPuzzleModeView> createState() =>
      _BlockPuzzleModeViewState();
}

class _BlockPuzzleModeViewState extends ConsumerState<BlockPuzzleModeView> {

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final shortest = media.size.shortestSide;
    final isTablet = shortest >= 700;
    final logoHeight = isTablet ? media.size.height * 0.32 : 300.0;
    final maxWidth = isTablet ? 520.0 : 380.0;
    final verticalPadding = isTablet ? 32.0 : 20.0;

    return Scaffold(
      body: BlockPuzzleBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Positioned(
                top: 12,
                right: 16,
                child: LocaleMenuButton(
                  backgroundColor: Colors.black.withOpacity(0.35),
                  textColor: const Color(0xFFFEEACC),
                ),
              ),
              Center(
                child: ConstrainedBox(
                  constraints: BoxConstraints(maxWidth: maxWidth),
                  child: Column(
                    children: [
                      const Spacer(),
                      Image.asset(
                        'assets/images/wooden_block_logo2.png',
                        height: logoHeight,
                      ),
                      SizedBox(height: verticalPadding),
                      _WoodButton(
                        label: tr('block_mode.adventure.title'),
                        subtitle: tr('block_mode.adventure.subtitle'),
                        icon: Icons.explore_outlined,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const LevelPathView(),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                      _WoodButton(
                        label: tr('block_mode.classic.title'),
                        subtitle: tr('block_mode.classic.subtitle'),
                        icon: Iconsax.paintbucket1,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const BlockPuzzleGameView(),
                            ),
                          );
                        },
                      ),
                      const Spacer(),
                      const _FooterDecoration(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WoodButton extends StatelessWidget {
  const _WoodButton({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: context.border.normalBorderRadius,
      child: InkWell(
        borderRadius: context.border.normalBorderRadius,
        onTap: onTap,
        child: Ink(
          padding: context.padding.normal,
          decoration: BoxDecoration(
            borderRadius: context.border.normalBorderRadius,
            gradient: const LinearGradient(
              colors: [Color.fromARGB(255, 242, 205, 174), Color(0xFFE1B072)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x55000000),
                offset: Offset(0, 8),
                blurRadius: 16,
                spreadRadius: -6,
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: context.dynamicHeight(0.05),
                height: context.dynamicHeight(0.05),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: const Color(0xFF7A4A22),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x33000000),
                      offset: Offset(0, 6),
                      blurRadius: 10,
                    ),
                  ],
                ),
                child: Icon(icon, color: const Color(0xFFFEEACC), size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF5B2C07),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF7A4A22),
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: Color(0xFF7A4A22)),
            ],
          ),
        ),
      ),
    );
  }
}

class _FooterDecoration extends StatelessWidget {
  const _FooterDecoration();

  static const _legalLabelKeys = ['legal.tabs.terms', 'legal.tabs.privacy'];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: context.padding.onlyTopMedium,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 34,
                height: 2,
                color: const Color.fromARGB(255, 223, 195, 156),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.circle,
                size: 6,
                color: const Color.fromARGB(255, 223, 195, 156),
              ),
              const SizedBox(width: 12),
              Container(
                width: 34,
                height: 2,
                color: const Color.fromARGB(255, 223, 195, 156),
              ),
            ],
          ),
          context.dynamicHeight(0.01).height,
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            children: [
              for (final key in _legalLabelKeys)
                TextButton(
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    foregroundColor: const Color.fromARGB(255, 223, 195, 156),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  onPressed: () {
                    final label = tr(key);
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const LegalDocumentsView(),
                        settings: RouteSettings(arguments: label),
                      ),
                    );
                  },
                  child: Text(tr(key)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

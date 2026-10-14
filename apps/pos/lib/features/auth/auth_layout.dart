import 'package:flutter/material.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

/// Kirish ekranlari karkasi: markazda, eni cheklangan, tepada ilova belgisi.
class AuthLayout extends StatelessWidget {
  const AuthLayout({required this.child, this.maxWidth = 440, super.key});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    final l10n = AppLocalizations.of(context);
    final compact = PosWindowSize.of(context).isCompact;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: EdgeInsets.all(compact ? PosSpacing.l : PosSpacing.xl),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.storefront,
                        color: p.primaryText,
                        size: PosSizes.iconXl,
                      ),
                      const SizedBox(width: PosSpacing.s),
                      Text(
                        l10n.appTitle,
                        style: PosTypography.h2.copyWith(color: p.text),
                      ),
                    ],
                  ),
                  SizedBox(height: compact ? PosSpacing.xl : PosSpacing.xxl),
                  child,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ekran sarlavhasi + izoh.
class AuthHeading extends StatelessWidget {
  const AuthHeading({required this.title, this.subtitle, super.key});

  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Semantics(
          header: true,
          child: Text(
            title,
            textAlign: TextAlign.center,
            style: PosTypography.h1.copyWith(color: p.text),
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: PosSpacing.s),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: PosTypography.body.copyWith(color: p.textSecondary),
          ),
        ],
      ],
    );
  }
}

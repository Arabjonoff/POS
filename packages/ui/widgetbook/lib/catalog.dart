import 'package:flutter/material.dart';
import 'package:pos_ui/pos_ui.dart';
import 'package:pos_ui_widgetbook/galleries/buttons_gallery.dart';
import 'package:pos_ui_widgetbook/galleries/dialog_gallery.dart';
import 'package:pos_ui_widgetbook/galleries/display_gallery.dart';
import 'package:pos_ui_widgetbook/galleries/feedback_gallery.dart';
import 'package:pos_ui_widgetbook/galleries/inputs_gallery.dart';
import 'package:pos_ui_widgetbook/galleries/keypad_gallery.dart';
import 'package:pos_ui_widgetbook/galleries/scaffold_gallery.dart';
import 'package:pos_ui_widgetbook/galleries/table_gallery.dart';
import 'package:pos_ui_widgetbook/galleries/tokens_gallery.dart';
import 'package:widgetbook/widgetbook.dart';

/// Galereya nomi → vidjet. Golden testlar ham shu ro'yxatdan foydalanadi.
final Map<String, WidgetBuilder> galleries = {
  'tokens': (_) => const TokensGallery(),
  'buttons': (_) => const ButtonsGallery(),
  'inputs': (_) => const InputsGallery(),
  'keypad': (_) => const KeypadGallery(),
  'pin_pad': (_) => const PinPadGallery(),
  'display': (_) => const DisplayGallery(),
  'feedback': (_) => const FeedbackGallery(),
  'table': (_) => const TableGallery(),
  'scaffold': (_) => const ScaffoldGallery(),
};

WidgetbookUseCase _all(String gallery) =>
    WidgetbookUseCase(name: 'All states', builder: galleries[gallery]!);

Widget _center(Widget child) => Center(
  child: Padding(padding: const EdgeInsets.all(PosSpacing.xl), child: child),
);

/// Katalog tarkibi: har komponent — "All states" (galereya) va kerak
/// bo'lsa "Playground" (knob'lar bilan).
final List<WidgetbookNode> catalog = [
  WidgetbookFolder(
    name: 'Tokens',
    children: [
      WidgetbookComponent(
        name: 'Colors & typography',
        useCases: [_all('tokens')],
      ),
    ],
  ),
  WidgetbookFolder(
    name: 'Actions',
    children: [
      WidgetbookComponent(
        name: 'Button',
        useCases: [
          _all('buttons'),
          WidgetbookUseCase(
            name: 'Playground',
            builder: (context) => _center(
              PosButton(
                label: context.knobs.string(
                  label: 'label',
                  initialValue: "To'lash",
                ),
                variant: context.knobs.object.dropdown(
                  label: 'variant',
                  options: PosButtonVariant.values,
                  labelBuilder: (v) => v.name,
                ),
                size: context.knobs.object.dropdown(
                  label: 'size',
                  options: PosButtonSize.values,
                  initialOption: PosButtonSize.m,
                  labelBuilder: (v) => v.name,
                ),
                shortcut: context.knobs.stringOrNull(
                  label: 'shortcut',
                  initialValue: 'F12',
                ),
                loading: context.knobs.boolean(label: 'loading'),
                onPressed:
                    context.knobs.boolean(
                      label: 'enabled',
                      initialValue: true,
                    )
                    ? () {}
                    : null,
              ),
            ),
          ),
        ],
      ),
    ],
  ),
  WidgetbookFolder(
    name: 'Inputs',
    children: [
      WidgetbookComponent(
        name: 'TextField, SearchField, QtyStepper',
        useCases: [_all('inputs')],
      ),
      WidgetbookComponent(
        name: 'NumericKeypad',
        useCases: [_all('keypad')],
      ),
      WidgetbookComponent(
        name: 'PinPad',
        useCases: [
          _all('pin_pad'),
          WidgetbookUseCase(
            name: 'Interactive',
            builder: (context) => const _PinPadDemo(),
          ),
        ],
      ),
    ],
  ),
  WidgetbookFolder(
    name: 'Display',
    children: [
      WidgetbookComponent(
        name: 'MoneyText, Badge, StatusDot, ProductTile, Card, ListTile',
        useCases: [
          _all('display'),
          WidgetbookUseCase(
            name: 'MoneyText playground',
            builder: (context) => _center(
              PosMoneyText(
                amount: context.knobs.int.input(
                  label: 'amount (tiyin)',
                  initialValue: 12500000,
                ),
                currency: context.knobs.object.dropdown(
                  label: 'currency',
                  options: const ["so'm", 'сўм', 'сум'],
                ),
                size: context.knobs.object.dropdown(
                  label: 'size',
                  options: PosMoneySize.values,
                  labelBuilder: (v) => v.name,
                ),
                tone: context.knobs.objectOrNull.dropdown(
                  label: 'tone',
                  options: PosTone.values,
                  labelBuilder: (v) => v.name,
                ),
              ),
            ),
          ),
        ],
      ),
      WidgetbookComponent(
        name: 'DataTable',
        useCases: [_all('table')],
      ),
    ],
  ),
  WidgetbookFolder(
    name: 'Feedback',
    children: [
      WidgetbookComponent(
        name: 'Toast, EmptyState, Skeleton, ScanFeedback',
        useCases: [
          _all('feedback'),
          WidgetbookUseCase(
            name: 'ScanFeedback interactive',
            builder: (context) => const _ScanDemo(),
          ),
        ],
      ),
      WidgetbookComponent(
        name: 'Dialog',
        useCases: [
          WidgetbookUseCase(
            name: 'Open',
            builder: (context) => const DialogGallery(),
          ),
        ],
      ),
    ],
  ),
  WidgetbookFolder(
    name: 'Layout',
    children: [
      WidgetbookComponent(
        name: 'ResponsiveScaffold + StatusBar',
        useCases: [_all('scaffold')],
      ),
    ],
  ),
];

class _PinPadDemo extends StatefulWidget {
  const _PinPadDemo();

  @override
  State<_PinPadDemo> createState() => _PinPadDemoState();
}

class _PinPadDemoState extends State<_PinPadDemo> {
  String _pin = '';
  String? _error;

  void _digit(String d) {
    if (_pin.length >= 6) return;
    setState(() {
      _error = null;
      _pin += d;
    });
  }

  @override
  Widget build(BuildContext context) => _center(
    PosPinPad(
      filled: _pin.length,
      errorText: _error,
      onDigit: _digit,
      onBackspace: () => setState(() {
        if (_pin.isNotEmpty) _pin = _pin.substring(0, _pin.length - 1);
      }),
      onSubmit: () => setState(() {
        if (_pin != '1234') _error = "PIN noto'g'ri (to'g'risi: 1234)";
        _pin = '';
      }),
      submitTooltip: 'Kirish',
      backspaceTooltip: "O'chirish",
    ),
  );
}

class _ScanDemo extends StatefulWidget {
  const _ScanDemo();

  @override
  State<_ScanDemo> createState() => _ScanDemoState();
}

class _ScanDemoState extends State<_ScanDemo> {
  final _controller = PosScanFeedbackController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => _center(
    Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 360,
          height: 200,
          child: PosScanFeedback(
            controller: _controller,
            child: const PosCard(child: Center(child: Text('Savat'))),
          ),
        ),
        const SizedBox(height: PosSpacing.l),
        Wrap(
          spacing: PosSpacing.s,
          children: [
            for (final r in PosScanResult.values)
              PosButton(
                label: r.name,
                size: PosButtonSize.s,
                variant: PosButtonVariant.secondary,
                onPressed: () => _controller.flash(r),
              ),
          ],
        ),
      ],
    ),
  );
}

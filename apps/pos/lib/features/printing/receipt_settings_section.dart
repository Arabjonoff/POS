import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/app/session/session.dart';
import 'package:pos_app/core/text/phone.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/store/store_settings.dart';
import 'package:pos_app/data/sync/server_features.dart';
import 'package:pos_app/features/common/manager_approval.dart';
import 'package:pos_app/features/pos/cart/discount_policy.dart';
import 'package:pos_app/features/printing/mono_bitmap.dart';
import 'package:pos_app/features/printing/printer_service.dart';
import 'package:pos_app/features/printing/printer_settings.dart';
import 'package:pos_app/features/printing/receipt.dart';
import 'package:pos_app/features/printing/receipt_loader.dart';
import 'package:pos_app/features/printing/receipt_preview.dart';
import 'package:pos_app/features/printing/receipt_sample.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

final StreamProvider<Store?> _storeRowProvider =
    StreamProvider.autoDispose<Store?>(
      (ref) => ref.watch(storeSettingsProvider).watch(),
    );

/// Sozlamalar → Chek rekvizitlari va ko'rinishi (T-104b): chapda —
/// do'kon rekvizitlari, logotip, ko'rsat/yashir; o'ngda (telefonda pastda) —
/// **jonli** chek ko'rinishi (saqlanmagan o'zgarishlar ham). Saqlash —
/// ega/menejer (kassir — menejer PIN), hamma kassalarga sinxron orqali.
class ReceiptSettingsSection extends ConsumerStatefulWidget {
  const ReceiptSettingsSection({super.key});

  @override
  ConsumerState<ReceiptSettingsSection> createState() =>
      _ReceiptSettingsSectionState();
}

class _ReceiptSettingsSectionState
    extends ConsumerState<ReceiptSettingsSection> {
  final _name = TextEditingController();
  final _legalName = TextEditingController();
  final _tin = TextEditingController();
  final _address = TextEditingController();
  final _phone = TextEditingController();
  final _header = TextEditingController();
  final _footer = TextEditingController();
  String? _storeId;
  GrayImage? _logo;
  ReceiptOptions _options = const ReceiptOptions();
  Set<StoreProblem> _problems = const {};
  bool _saving = false;
  bool _dirty = false;

  List<TextEditingController> get _fields => [
    _name,
    _legalName,
    _tin,
    _address,
    _phone,
    _header,
    _footer,
  ];

  @override
  void dispose() {
    for (final c in _fields) {
      c.dispose();
    }
    super.dispose();
  }

  void _load(Store row) {
    _storeId = row.id;
    _name.text = row.name;
    _legalName.text = row.legalName;
    _tin.text = row.tin;
    _address.text = row.address;
    _phone.text = displayPhone(row.phone);
    _header.text = row.receiptHeader;
    _footer.text = row.receiptFooter;
    _logo = decodeStoreLogo(row.receiptLogo);
    _options = decodeReceiptOptions(row.receiptOptions);
  }

  StoreDraft _draft() => StoreDraft(
    id: _storeId!,
    name: _name.text,
    legalName: _legalName.text,
    tin: _tin.text,
    address: _address.text,
    phone: _phone.text,
    header: _header.text,
    footer: _footer.text,
    logo: _logo,
    options: _options,
  );

  void _changed() => setState(() {
    _dirty = true;
    _problems = const {};
  });

  Future<void> _pickLogo() async {
    final l10n = AppLocalizations.of(context);
    try {
      final logo = await ref.read(logoPickerProvider)();
      if (logo == null || !mounted) return;
      setState(() {
        _logo = logo;
        _dirty = true;
      });
    } on FormatException {
      if (mounted) {
        showPosToast(
          context,
          message: l10n.storeLogoError,
          tone: PosTone.danger,
        );
      }
    }
  }

  Future<void> _save() async {
    if (_saving || _storeId == null) return;
    final l10n = AppLocalizations.of(context);
    final draft = _draft();
    final problems = StoreSettingsStore.validate(draft).toSet();
    if (problems.isNotEmpty) {
      setState(() => _problems = problems);
      if (problems.contains(StoreProblem.logoTooLarge)) {
        showPosToast(
          context,
          message: l10n.storeLogoTooLarge,
          tone: PosTone.danger,
        );
      }
      return;
    }
    final user = ref.read(sessionProvider).user;
    if (user == null) return;
    final by = DiscountPolicy.canApprove(user.role)
        ? user.id
        : await requestManagerApproval(
            context,
            reason: l10n.storeNeedsApproval,
          );
    if (by == null || !mounted) return;
    setState(() => _saving = true);
    try {
      await ref.read(storeSettingsProvider).save(draft, by: by);
      if (!mounted) return;
      setState(() => _dirty = false);
      showPosToast(context, message: l10n.storeSaved, tone: PosTone.success);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final row = ref.watch(_storeRowProvider).value;
    if (row != null && _storeId == null) _load(row);
    final available =
        (ref.watch(serverFeaturesProvider).value ?? const {}).contains(
          ServerFeature.storeSettings,
        ) &&
        row != null;
    final form = _form(l10n, enabled: available);
    final preview = _preview();
    return Padding(
      padding: const EdgeInsets.all(PosSpacing.s),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth >= 760) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: form),
                const SizedBox(width: PosSpacing.xl),
                Expanded(flex: 2, child: preview),
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              form,
              const SizedBox(height: PosSpacing.l),
              preview,
            ],
          );
        },
      ),
    );
  }

  Widget _preview() {
    final settings =
        ref.watch(printerSettingsProvider).value ?? const PrinterSettings();
    final data = ref.watch(receiptPreviewDataProvider).value;
    if (data == null) return const PosSkeleton(height: 320);
    final merged = _storeId == null
        ? data.data
        : data.data.withStore(
            storeName: _name.text,
            storeAddress: _address.text,
            storePhone: _phone.text,
            header: _header.text,
            footer: _footer.text,
            legalName: _legalName.text,
            tin: _tin.text,
            logo: _logo,
            options: _options,
          );
    final rows = ref.watch(printerServiceProvider).previewRows(merged);
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: PosBadge(
            label: data.isSample
                ? l10n.receiptPreviewSample
                : l10n.receiptPreviewLast,
          ),
        ),
        const SizedBox(height: PosSpacing.m),
        ReceiptPreview(
          rows: rows,
          width: settings.width,
          encoding: settings.encoding,
        ),
      ],
    );
  }

  Widget _form(AppLocalizations l10n, {required bool enabled}) {
    final p = PosPalette.of(context);
    Widget field(
      TextEditingController controller,
      String label, {
      Key? key,
      String? helper,
      String? hint,
      String? error,
      int maxLines = 1,
      TextInputType? keyboard,
      List<TextInputFormatter>? formatters,
    }) => Padding(
      padding: const EdgeInsets.only(bottom: PosSpacing.m),
      child: PosTextField(
        key: key,
        controller: controller,
        label: label,
        helper: helper,
        hint: hint,
        errorText: error,
        maxLines: maxLines,
        enabled: enabled,
        keyboardType: keyboard,
        inputFormatters: formatters,
        onChanged: (_) => _changed(),
      ),
    );

    Widget toggle(
      String title, {
      required bool value,
      required ValueChanged<bool> onChanged,
    }) => PosListTile(
      title: title,
      trailing: Switch(value: value, onChanged: enabled ? onChanged : null),
      onTap: enabled ? () => onChanged(!value) : null,
    );

    void option(ReceiptOptions next) => setState(() {
      _options = next;
      _dirty = true;
    });

    final o = _options;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (!enabled)
          Padding(
            padding: const EdgeInsets.only(bottom: PosSpacing.m),
            child: Text(
              l10n.storeUnavailable,
              style: PosTypography.small.copyWith(color: p.textSecondary),
            ),
          ),
        field(
          _name,
          l10n.storeName,
          key: const ValueKey('store-name'),
          error: _problems.contains(StoreProblem.nameRequired)
              ? l10n.fieldRequired
              : null,
        ),
        field(
          _legalName,
          l10n.fieldOptional(l10n.storeLegalName),
          key: const ValueKey('store-legal-name'),
          hint: l10n.storeLegalNameHint,
        ),
        field(
          _tin,
          l10n.fieldOptional(l10n.storeTin),
          key: const ValueKey('store-tin'),
          helper: l10n.storeTinHint,
          error: _problems.contains(StoreProblem.tinFormat)
              ? l10n.storeTinError
              : null,
          keyboard: TextInputType.number,
          formatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(14),
          ],
        ),
        field(
          _address,
          l10n.fieldOptional(l10n.storeAddress),
          key: const ValueKey('store-address'),
        ),
        field(
          _phone,
          l10n.fieldOptional(l10n.storePhone),
          key: const ValueKey('store-phone'),
          keyboard: TextInputType.phone,
          error: _problems.contains(StoreProblem.phoneFormat)
              ? l10n.phoneInvalid
              : null,
        ),
        field(
          _header,
          l10n.fieldOptional(l10n.storeHeader),
          key: const ValueKey('store-header'),
          hint: l10n.storeHeaderHint,
          maxLines: 3,
        ),
        field(
          _footer,
          l10n.fieldOptional(l10n.storeFooter),
          key: const ValueKey('store-footer'),
          hint: l10n.storeFooterHint,
          maxLines: 3,
        ),
        Text(
          l10n.fieldOptional(l10n.storeLogo),
          style: PosTypography.smallStrong.copyWith(color: p.text),
        ),
        const SizedBox(height: PosSpacing.xs),
        Text(
          l10n.storeLogoHint,
          style: PosTypography.small.copyWith(color: p.textSecondary),
        ),
        const SizedBox(height: PosSpacing.s),
        Wrap(
          spacing: PosSpacing.s,
          runSpacing: PosSpacing.s,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            PosButton(
              key: const ValueKey('store-logo-pick'),
              label: _logo == null ? l10n.storeLogoPick : l10n.storeLogoReplace,
              icon: Icons.image_outlined,
              size: PosButtonSize.s,
              variant: PosButtonVariant.secondary,
              onPressed: enabled ? () => unawaited(_pickLogo()) : null,
            ),
            if (_logo != null)
              PosButton(
                key: const ValueKey('store-logo-remove'),
                label: l10n.storeLogoRemove,
                icon: Icons.delete_outline,
                size: PosButtonSize.s,
                variant: PosButtonVariant.ghost,
                onPressed: enabled
                    ? () => setState(() {
                        _logo = null;
                        _dirty = true;
                      })
                    : null,
              ),
          ],
        ),
        const SizedBox(height: PosSpacing.l),
        Text(
          l10n.storeShowTitle,
          style: PosTypography.smallStrong.copyWith(color: p.text),
        ),
        toggle(
          l10n.storeLogo,
          value: o.showLogo,
          onChanged: (v) => option(o.copyWith(showLogo: v)),
        ),
        toggle(
          l10n.storeLegalName,
          value: o.showLegalName,
          onChanged: (v) => option(o.copyWith(showLegalName: v)),
        ),
        toggle(
          l10n.storeAddress,
          value: o.showAddress,
          onChanged: (v) => option(o.copyWith(showAddress: v)),
        ),
        toggle(
          l10n.storePhone,
          value: o.showPhone,
          onChanged: (v) => option(o.copyWith(showPhone: v)),
        ),
        toggle(
          l10n.storeTin,
          value: o.showTin,
          onChanged: (v) => option(o.copyWith(showTin: v)),
        ),
        toggle(
          l10n.storeHeader,
          value: o.showHeader,
          onChanged: (v) => option(o.copyWith(showHeader: v)),
        ),
        toggle(
          l10n.storeShowCashier,
          value: o.showCashier,
          onChanged: (v) => option(o.copyWith(showCashier: v)),
        ),
        toggle(
          l10n.storeShowBarcode,
          value: o.showBarcode,
          onChanged: (v) => option(o.copyWith(showBarcode: v)),
        ),
        toggle(
          l10n.storeFooter,
          value: o.showFooter,
          onChanged: (v) => option(o.copyWith(showFooter: v)),
        ),
        const SizedBox(height: PosSpacing.m),
        toggle(
          l10n.storeVatPayer,
          value: o.vatPayer,
          onChanged: (v) => option(o.copyWith(vatPayer: v)),
        ),
        const SizedBox(height: PosSpacing.m),
        Align(
          alignment: Alignment.centerLeft,
          child: PosButton(
            key: const ValueKey('store-save'),
            label: l10n.storeSave,
            icon: Icons.check,
            loading: _saving,
            onPressed: enabled && _dirty && !_saving
                ? () => unawaited(_save())
                : null,
          ),
        ),
      ],
    );
  }
}

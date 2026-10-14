import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/app/session/session.dart';
import 'package:pos_app/data/catalog/product_import.dart';
import 'package:pos_app/data/remote/api.dart';
import 'package:pos_app/features/common/manager_approval.dart';
import 'package:pos_app/features/pos/cart/discount_policy.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

/// "Excel'dan yuklash" (`docs/specs/product-import.md`): fayl → ustunlarni
/// moslash → tekshirish → import (bitta server tranzaksiyasi) → natija.
/// Natija — qo'llangan import yoki `null`.
Future<ImportResult?> showImportDialog(BuildContext context) =>
    showPosDialog<ImportResult>(
      context: context,
      maxWidth: ImportDialog.maxWidth,
      builder: (context) => const ImportDialog(),
    );

enum _Stage { pick, map, check, done }

class ImportDialog extends ConsumerStatefulWidget {
  const ImportDialog({super.key});

  static const double maxWidth = 640;

  /// Xatolar ro'yxatida ko'rsatiladigan qatorlar.
  static const int shownErrors = 50;

  @override
  ConsumerState<ImportDialog> createState() => _ImportDialogState();
}

class _ImportDialogState extends ConsumerState<ImportDialog> {
  _Stage _stage = _Stage.pick;
  late String _fileName;
  ImportUpload? _upload;
  late ImportMapping _mapping;
  late ImportCheck _check;
  late ImportResult _result;
  bool _busy = false;
  String? _error;

  ProductImportApi get _api => ref.read(productImportApiProvider);

  Future<void> _run(Future<void> Function() action) async {
    if (_busy) return;
    final l10n = AppLocalizations.of(context);
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
    } on ApiFailure catch (e) {
      if (mounted) {
        setState(
          () => _error = e.kind == ApiFailureKind.network
              ? l10n.importOffline
              : l10n.importFailed,
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _template() => _run(() async {
    final bytes = await _api.template();
    final saved = await ref
        .read(importFilesProvider)
        .save('tovarlar-shablon.xlsx', bytes);
    if (saved && mounted) {
      showPosToast(
        context,
        message: AppLocalizations.of(context).importTemplateSaved,
        tone: PosTone.success,
      );
    }
  });

  Future<void> _pick() => _run(() async {
    final file = await ref.read(importFilesProvider).pick();
    if (file == null) return;
    final upload = await _api.upload(file);
    if (!mounted) return;
    setState(() {
      _fileName = file.name;
      _upload = upload;
      _mapping = Map.of(upload.mapping);
      _stage = _Stage.map;
    });
  });

  Future<void> _runCheck() async {
    final upload = _upload;
    if (upload == null) return;
    if (ImportField.values.any((f) => f.required && _mapping[f] == null)) {
      setState(
        () => _error = AppLocalizations.of(context).importRequiredMissing,
      );
      return;
    }
    await _run(() async {
      final check = await _api.check(upload.id, _mapping);
      if (!mounted) return;
      setState(() {
        _check = check;
        _stage = _Stage.check;
      });
    });
  }

  Future<void> _apply() async {
    final upload = _upload;
    final user = ref.read(sessionProvider).user;
    if (upload == null || user == null || _busy) return;
    var by = DiscountPolicy.canApprove(user.role) ? user.id : null;
    if (by == null) {
      by = await requestManagerApproval(
        context,
        reason: AppLocalizations.of(context).importNeedsApproval,
      );
      if (by == null || !mounted) return;
    }
    final approver = by;
    await _run(() async {
      final result = await _api.apply(upload.id, _mapping, by: approver);
      // Yangi tovarlar kassaga — darhol pull (xato bo'lsa fon sinxroni oladi).
      unawaited(ref.read(refreshCatalogProvider)().catchError((_) {}));
      if (!mounted) return;
      setState(() {
        _result = result;
        _stage = _Stage.done;
      });
    });
  }

  Future<void> _chooseColumn(ImportField field) async {
    final upload = _upload;
    if (upload == null) return;
    final l10n = AppLocalizations.of(context);
    final picked = await showPosDialog<int>(
      context: context,
      builder: (context) => PosDialog(
        title: l10n.importChooseColumn,
        message: _fieldLabel(l10n, field),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PosListTile(
              key: const ValueKey('import-column-none'),
              title: l10n.importNoColumn,
              selected: _mapping[field] == null,
              onTap: () => Navigator.of(context).pop(-1),
            ),
            for (final (i, name) in upload.columns.indexed)
              PosListTile(
                key: ValueKey('import-column-$i'),
                title: name.isEmpty ? '${i + 1}' : name,
                subtitle: upload.sample.isEmpty ? null : upload.sample.first[i],
                selected: _mapping[field] == i,
                onTap: () => Navigator.of(context).pop(i),
              ),
          ],
        ),
        actions: [
          PosButton(
            label: l10n.actionCancel,
            variant: PosButtonVariant.secondary,
            shortcut: 'Esc',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
    if (picked == null || !mounted) return;
    setState(() {
      _mapping = {..._mapping, field: picked < 0 ? null : picked};
      _error = null;
    });
  }

  static String _fieldLabel(AppLocalizations l10n, ImportField field) =>
      switch (field) {
        ImportField.name => l10n.productsColName,
        ImportField.barcode => l10n.productsColBarcode,
        ImportField.category => l10n.productsColCategory,
        ImportField.unit => l10n.productUnit,
        ImportField.sellPrice => l10n.productsColPrice,
        ImportField.costPrice => l10n.productsColCost,
        ImportField.stock => l10n.productsColStock,
      };

  static String _reason(AppLocalizations l10n, String code) => switch (code) {
    'required' => l10n.importErrRequired,
    'invalid_number' => l10n.importErrNumber,
    'not_positive' => l10n.importErrPositive,
    'invalid_barcode' => l10n.importErrBarcode,
    'invalid_check_digit' => l10n.importErrCheckDigit,
    'duplicate_in_file' => l10n.importErrDuplicate,
    'unknown_unit' => l10n.importErrUnit,
    'too_long' => l10n.importErrTooLong,
    'weighted_unit' => l10n.importErrWeighted,
    _ => code,
  };

  String _errorLine(AppLocalizations l10n, ImportRowError e) {
    final field = ImportField.fromCode(e.field);
    return l10n.importErrorRow(
      e.row,
      field == null ? e.field : _fieldLabel(l10n, field),
      _reason(l10n, e.code),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = PosPalette.of(context);
    final error = _error;
    final (content, actions) = switch (_stage) {
      _Stage.pick => _pickStage(l10n),
      _Stage.map => _mapStage(l10n),
      _Stage.check => _checkStage(l10n),
      _Stage.done => _doneStage(l10n),
    };
    return PosDialog(
      icon: Icons.upload_file_outlined,
      title: _stage == _Stage.map ? l10n.importMapTitle : l10n.importTitle,
      message: _upload == null
          ? null
          : l10n.importRows(_fileName, _upload!.totalRows),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          content,
          if (_busy) ...[
            const SizedBox(height: PosSpacing.m),
            const LinearProgressIndicator(),
          ],
          if (error != null) ...[
            const SizedBox(height: PosSpacing.m),
            Text(
              error,
              key: const ValueKey('import-error'),
              style: PosTypography.bodyStrong.copyWith(color: p.dangerText),
            ),
          ],
        ],
      ),
      actions: actions,
    );
  }

  PosButton _cancel(AppLocalizations l10n) => PosButton(
    label: l10n.actionCancel,
    variant: PosButtonVariant.secondary,
    shortcut: 'Esc',
    onPressed: _busy ? null : () => Navigator.of(context).pop(),
  );

  (Widget, List<Widget>) _pickStage(AppLocalizations l10n) {
    final p = PosPalette.of(context);
    return (
      Text(
        l10n.importIntro,
        style: PosTypography.body.copyWith(color: p.textSecondary),
      ),
      [
        _cancel(l10n),
        PosButton(
          key: const ValueKey('import-template'),
          label: l10n.importTemplate,
          icon: Icons.download_outlined,
          variant: PosButtonVariant.secondary,
          onPressed: _busy ? null : () => unawaited(_template()),
        ),
        PosButton(
          key: const ValueKey('import-pick'),
          label: l10n.importPick,
          icon: Icons.folder_open_outlined,
          onPressed: _busy ? null : () => unawaited(_pick()),
        ),
      ],
    );
  }

  (Widget, List<Widget>) _mapStage(AppLocalizations l10n) {
    final p = PosPalette.of(context);
    final upload = _upload!;
    String column(int? index) => index == null
        ? l10n.importNoColumn
        : (upload.columns[index].isEmpty
              ? '${index + 1}'
              : upload.columns[index]);
    final mapped = [
      for (final f in ImportField.values)
        if (_mapping[f] != null) f,
    ];
    return (
      Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final f in ImportField.values)
            Padding(
              padding: const EdgeInsets.only(bottom: PosSpacing.xs),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      f.required
                          ? '${_fieldLabel(l10n, f)} *'
                          : _fieldLabel(l10n, f),
                      style: PosTypography.bodyStrong.copyWith(color: p.text),
                    ),
                  ),
                  PosButton(
                    key: ValueKey('import-field-${f.code}'),
                    label: column(_mapping[f]),
                    size: PosButtonSize.s,
                    variant: _mapping[f] == null
                        ? PosButtonVariant.ghost
                        : PosButtonVariant.secondary,
                    icon: Icons.unfold_more,
                    onPressed: () => unawaited(_chooseColumn(f)),
                  ),
                ],
              ),
            ),
          if (mapped.isNotEmpty && upload.sample.isNotEmpty) ...[
            const SizedBox(height: PosSpacing.m),
            PosDataTable<List<String>>(
              shrinkWrap: true,
              rows: upload.sample.take(5).toList(),
              columns: [
                for (final f in mapped)
                  PosTableColumn(
                    label: _fieldLabel(l10n, f),
                    minWidth: 96,
                    cell: (context, row) => Text(
                      row[_mapping[f]!],
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: PosTypography.small.copyWith(color: p.text),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
      [
        _cancel(l10n),
        PosButton(
          key: const ValueKey('import-check'),
          label: l10n.importCheck,
          icon: Icons.fact_check_outlined,
          onPressed: _busy ? null : () => unawaited(_runCheck()),
        ),
      ],
    );
  }

  (Widget, List<Widget>) _checkStage(AppLocalizations l10n) {
    final check = _check;
    return (
      _Summary(
        headline: l10n.importSummary(
          check.creates,
          check.updates,
          check.errorCount,
        ),
        tone: check.errorCount == 0 ? PosTone.success : PosTone.warning,
        lines: [
          for (final e in check.errors.take(ImportDialog.shownErrors))
            _errorLine(l10n, e),
          if (check.errorCount > ImportDialog.shownErrors)
            l10n.importMoreErrors(check.errorCount - ImportDialog.shownErrors),
        ],
      ),
      [
        PosButton(
          label: l10n.importBack,
          variant: PosButtonVariant.ghost,
          onPressed: _busy ? null : () => setState(() => _stage = _Stage.map),
        ),
        _cancel(l10n),
        PosButton(
          key: const ValueKey('import-apply'),
          label: l10n.importApply,
          icon: Icons.check,
          onPressed: _busy || check.creates + check.updates == 0
              ? null
              : () => unawaited(_apply()),
        ),
      ],
    );
  }

  (Widget, List<Widget>) _doneStage(AppLocalizations l10n) {
    final result = _result;
    return (
      _Summary(
        headline: l10n.importDone(
          result.created,
          result.updated,
          result.skipped,
        ),
        tone: PosTone.success,
        lines: [
          for (final e in result.errors.take(ImportDialog.shownErrors))
            _errorLine(l10n, e),
          if (result.errorCount > ImportDialog.shownErrors)
            l10n.importMoreErrors(
              result.errorCount - ImportDialog.shownErrors,
            ),
        ],
      ),
      [
        PosButton(
          key: const ValueKey('import-close'),
          label: l10n.importClose,
          onPressed: () => Navigator.of(context).pop(result),
        ),
      ],
    );
  }
}

/// Natija: rangli sarlavha qatori va xatolar ro'yxati.
class _Summary extends StatelessWidget {
  const _Summary({
    required this.headline,
    required this.tone,
    required this.lines,
  });

  final String headline;
  final PosTone tone;
  final List<String> lines;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    final colors = p.tone(tone);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.soft,
            borderRadius: PosRadius.controlAll,
          ),
          child: Padding(
            padding: const EdgeInsets.all(PosSpacing.m),
            child: Text(
              headline,
              key: const ValueKey('import-summary'),
              style: PosTypography.bodyStrong.copyWith(color: colors.onSoft),
            ),
          ),
        ),
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(top: PosSpacing.xs),
            child: Text(
              line,
              style: PosTypography.small.copyWith(color: p.textSecondary),
            ),
          ),
      ],
    );
  }
}

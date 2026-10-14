import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/app/session/pin_gate.dart';
import 'package:pos_app/core/security/pin_hash.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/features/auth/lock_screen.dart';
import 'package:pos_app/features/pos/cart/discount_policy.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

/// Huquq talab qiluvchi amal: menejer yoki ega PIN bilan tasdiqlaydi
/// (`auth-roles.md`). Natija — tasdiqlagan xodim ID si yoki `null`.
Future<String?> requestManagerApproval(
  BuildContext context, {
  required String reason,
}) => showPosDialog<String>(
  context: context,
  builder: (context) => _ApprovalDialog(reason: reason),
);

class _ApprovalDialog extends ConsumerStatefulWidget {
  const _ApprovalDialog({required this.reason});

  final String reason;

  @override
  ConsumerState<_ApprovalDialog> createState() => _ApprovalDialogState();
}

class _ApprovalDialogState extends ConsumerState<_ApprovalDialog> {
  StaffUser? _user;
  String _pin = '';
  String? _error;
  bool _busy = false;

  void _digit(String d) {
    if (_busy || _pin.length >= PinHash.maxLength) return;
    setState(() {
      _pin += d;
      _error = null;
    });
  }

  void _backspace() {
    if (_busy || _pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  Future<void> _submit() async {
    final user = _user;
    if (user == null || _busy || _pin.length < PinHash.minLength) return;
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = true);
    final result = await ref.read(pinGateProvider).check(user, _pin);
    if (!mounted) return;
    setState(() {
      _busy = false;
      _pin = '';
    });
    switch (result) {
      case PinAccepted():
        Navigator.of(context).pop(user.id);
      case PinRejected(:final attemptsLeft):
        setState(() => _error = l10n.lockWrongPin(attemptsLeft));
      case PinLockedOut(:final remaining):
        setState(() => _error = l10n.lockLockedOut(remaining.inSeconds));
      case PinNotSet():
        setState(() => _error = l10n.lockNoPin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = PosPalette.of(context);
    final user = _user;
    final approvers = [
      for (final u
          in ref.watch(staffUsersProvider).value ?? const <StaffUser>[])
        if (DiscountPolicy.canApprove(u.role) && u.pinHash != null) u,
    ];

    final Widget content;
    if (user == null) {
      content = approvers.isEmpty
          ? PosEmptyState(
              icon: Icons.admin_panel_settings_outlined,
              title: l10n.approvalNoManagers,
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final u in approvers)
                  PosListTile(
                    leading: const Icon(Icons.person_outline),
                    title: u.fullName,
                    subtitle: roleLabel(l10n, u.role),
                    onTap: () => setState(() {
                      _user = u;
                      _pin = '';
                      _error = null;
                    }),
                  ),
              ],
            );
    } else {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            user.fullName,
            style: PosTypography.bodyStrong.copyWith(color: p.text),
          ),
          Text(
            l10n.lockEnterPin,
            style: PosTypography.small.copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: PosSpacing.m),
          PosPinPad(
            filled: _pin.length,
            onDigit: _digit,
            onBackspace: _backspace,
            onSubmit: () => unawaited(_submit()),
            submitTooltip: l10n.approvalConfirm,
            backspaceTooltip: l10n.actionBackspace,
            errorText: _error,
            enabled: !_busy,
          ),
        ],
      );
    }

    return PosDialog(
      icon: Icons.verified_user_outlined,
      title: l10n.approvalTitle,
      message: widget.reason,
      content: content,
      actions: [
        if (user != null)
          PosButton(
            label: l10n.lockBack,
            variant: PosButtonVariant.ghost,
            onPressed: _busy ? null : () => setState(() => _user = null),
          ),
        PosButton(
          label: l10n.actionCancel,
          variant: PosButtonVariant.secondary,
          shortcut: 'Esc',
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }
}

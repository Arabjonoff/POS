import 'dart:async';

import 'package:drift/drift.dart' show OrderingTerm;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/app/session/pin_gate.dart';
import 'package:pos_app/app/session/session.dart';
import 'package:pos_app/core/security/pin_hash.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/features/auth/auth_layout.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

/// Faol xodimlar (pull'dan): ega, menejer, kassir — ism bo'yicha.
final staffUsersProvider = StreamProvider<List<StaffUser>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return (db.select(db.staffUsers)
        ..where((u) => u.isActive.equals(true))
        ..orderBy([(u) => OrderingTerm(expression: u.fullName)]))
      .watch();
});

String roleLabel(AppLocalizations l10n, String role) => switch (role) {
  'owner' => l10n.roleOwner,
  'manager' => l10n.roleManager,
  _ => l10n.roleCashier,
};

/// Kundalik kirish: xodim tanlash + PIN (oflaynda ham). 5 xato → 1 daqiqa.
class LockScreen extends ConsumerStatefulWidget {
  const LockScreen({super.key});

  @override
  ConsumerState<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends ConsumerState<LockScreen> {
  StaffUser? _user;
  String _pin = '';
  String? _error;
  bool _busy = false;
  int _secondsLeft = 0;
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    unawaited(_restoreLockout());
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  Future<void> _restoreLockout() async {
    final left = await ref.read(pinGateProvider).lockedFor();
    if (left != null && mounted) _startLockout(left);
  }

  void _startLockout(Duration left) {
    _ticker?.cancel();
    setState(() {
      _secondsLeft = (left.inMilliseconds / 1000).ceil();
      _pin = '';
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _secondsLeft--;
        if (_secondsLeft <= 0) {
          timer.cancel();
          _secondsLeft = 0;
          _error = null;
        }
      });
    });
  }

  bool get _locked => _secondsLeft > 0;

  void _back() => setState(() {
    _user = null;
    _pin = '';
    _error = null;
  });

  void _digit(String d) {
    if (_busy || _locked || _pin.length >= PinHash.maxLength) return;
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
    if (user == null || _busy || _locked) return;
    if (_pin.length < PinHash.minLength) return;
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
        ref.read(sessionProvider.notifier).unlock(user);
      case PinRejected(:final attemptsLeft):
        setState(() => _error = l10n.lockWrongPin(attemptsLeft));
      case PinLockedOut(:final remaining):
        _startLockout(remaining);
      case PinNotSet():
        setState(() => _error = l10n.lockNoPin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final user = _user;
    return AuthLayout(
      maxWidth: user == null ? 720 : 400,
      child: user == null ? _pickUser(l10n) : _enterPin(l10n, user),
    );
  }

  Widget _pickUser(AppLocalizations l10n) {
    final users = ref.watch(staffUsersProvider).value;
    if (users == null) return const PosSkeletonListTile();
    if (users.isEmpty) {
      return PosCard(
        child: PosEmptyState(
          icon: Icons.group_off_outlined,
          title: l10n.lockNoStaffTitle,
          message: l10n.lockNoStaffMessage,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthHeading(title: l10n.lockTitle),
        const SizedBox(height: PosSpacing.xl),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: PosSpacing.m,
          runSpacing: PosSpacing.m,
          children: [
            for (final u in users)
              SizedBox(
                width: 200,
                child: _UserCard(
                  user: u,
                  subtitle: u.pinHash == null
                      ? l10n.lockNoPin
                      : roleLabel(l10n, u.role),
                  onTap: u.pinHash == null
                      ? null
                      : () => setState(() {
                          _user = u;
                          _pin = '';
                          _error = null;
                        }),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _enterPin(AppLocalizations l10n, StaffUser user) {
    final p = PosPalette.of(context);
    final error = _locked ? l10n.lockLockedOut(_secondsLeft) : _error;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () {
          if (!_busy) _back();
        },
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Avatar(name: user.fullName, size: 64),
          const SizedBox(height: PosSpacing.m),
          Text(
            user.fullName,
            textAlign: TextAlign.center,
            style: PosTypography.h2.copyWith(color: p.text),
          ),
          Text(
            l10n.lockEnterPin,
            textAlign: TextAlign.center,
            style: PosTypography.body.copyWith(color: p.textSecondary),
          ),
          const SizedBox(height: PosSpacing.l),
          Center(
            child: PosPinPad(
              filled: _pin.length,
              onDigit: _digit,
              onBackspace: _backspace,
              onSubmit: () => unawaited(_submit()),
              submitTooltip: l10n.lockSubmit,
              backspaceTooltip: l10n.actionBackspace,
              errorText: error,
              enabled: !_busy && !_locked,
            ),
          ),
          const SizedBox(height: PosSpacing.m),
          PosButton(
            label: l10n.lockBack,
            variant: PosButtonVariant.ghost,
            icon: Icons.arrow_back,
            shortcut: 'Esc',
            onPressed: _busy ? null : _back,
          ),
        ],
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  const _UserCard({required this.user, required this.subtitle, this.onTap});

  final StaffUser user;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    final enabled = onTap != null;
    return PosCard(
      onTap: onTap,
      muted: !enabled,
      child: Column(
        children: [
          _Avatar(name: user.fullName, size: 56, enabled: enabled),
          const SizedBox(height: PosSpacing.s),
          Text(
            user.fullName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: PosTypography.bodyStrong.copyWith(
              color: enabled ? p.text : p.disabled,
            ),
          ),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: PosTypography.small.copyWith(
              color: enabled ? p.textSecondary : p.disabled,
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.name, required this.size, this.enabled = true});

  final String name;
  final double size;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final p = PosPalette.of(context);
    final initial = name.trim().isEmpty ? '?' : name.trim()[0].toUpperCase();
    return Center(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: enabled ? p.primarySoft : p.surfaceMuted,
          shape: BoxShape.circle,
        ),
        child: Text(
          initial,
          style: PosTypography.h2.copyWith(
            color: enabled ? p.onPrimarySoft : p.disabled,
          ),
        ),
      ),
    );
  }
}

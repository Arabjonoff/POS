import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pos_app/app/session/session.dart';
import 'package:pos_app/data/db/app_database.dart';
import 'package:pos_app/data/device/device_registration.dart';
import 'package:pos_app/data/remote/api.dart';
import 'package:pos_app/data/sync/pull.dart';
import 'package:pos_app/features/auth/auth_layout.dart';
import 'package:pos_app/l10n/gen/app_localizations.dart';
import 'package:pos_ui/pos_ui.dart';

enum _Step { credentials, deviceName, syncing, syncFailed }

/// Birinchi ishga tushirish: ega telefon + parol → kassa nomi → birinchi
/// sinxron (progress bilan). Uzilsa — keyingi ochilishda sinxrondan davom.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _name = TextEditingController();
  final _passwordFocus = FocusNode();

  late _Step _step;
  bool _busy = false;
  bool _showRequired = false;
  SetupError? _error;
  int _synced = 0;

  @override
  void initState() {
    super.initState();
    final resume = ref.read(sessionProvider).stage == SessionStage.initialSync;
    _step = resume ? _Step.syncing : _Step.credentials;
    if (resume) WidgetsBinding.instance.addPostFrameCallback((_) => _sync());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_name.text.isEmpty) {
      _name.text = AppLocalizations.of(context).setupDeviceNameDefault;
    }
  }

  @override
  void dispose() {
    _phone.dispose();
    _password.dispose();
    _name.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _next() {
    if (_phone.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _showRequired = true);
      return;
    }
    setState(() {
      _showRequired = false;
      _error = null;
      _step = _Step.deviceName;
    });
  }

  Future<void> _connect() async {
    if (_name.text.trim().isEmpty) {
      setState(() => _showRequired = true);
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
      _showRequired = false;
    });
    try {
      final device =
          await DeviceRegistration(
            db: ref.read(appDatabaseProvider),
            tokens: ref.read(deviceTokenStoreProvider),
            dio: ref.read(dioFactoryProvider),
          ).register(
            phone: _phone.text.trim(),
            password: _password.text,
            deviceName: _name.text,
          );
      ref.read(sessionProvider.notifier).deviceRegistered(device);
      if (!mounted) return;
      setState(() => _step = _Step.syncing);
      await _sync();
    } on SetupException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.error;
        // Kirish ma'lumoti xato — birinchi qadamga qaytamiz.
        if (e.error == SetupError.invalidCredentials ||
            e.error == SetupError.notOwner) {
          _step = _Step.credentials;
        }
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _sync() async {
    setState(() {
      _step = _Step.syncing;
      _synced = 0;
    });
    try {
      final token = await ref.read(deviceTokenStoreProvider).read();
      final api = deviceApi(ref.read(dioFactoryProvider), token ?? '');
      await SyncPuller(ref.read(appDatabaseProvider), api).pullAll(
        onProgress: (n) {
          if (mounted) setState(() => _synced = n);
        },
      );
      await ref.read(sessionProvider.notifier).initialSyncDone();
    } on Object {
      if (mounted) setState(() => _step = _Step.syncFailed);
    }
  }

  String _errorText(AppLocalizations l10n, SetupError error) => switch (error) {
    SetupError.invalidCredentials => l10n.setupErrorInvalidCredentials,
    SetupError.notOwner => l10n.setupErrorNotOwner,
    SetupError.deviceLimit => l10n.setupErrorDeviceLimit,
    SetupError.noSubscription => l10n.setupErrorNoSubscription,
    SetupError.deviceBlocked => l10n.setupErrorDeviceBlocked,
    SetupError.network => l10n.setupErrorNetwork,
    SetupError.unknown => l10n.setupErrorUnknown,
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AuthLayout(
      child: PosCard(
        padding: const EdgeInsets.all(PosSpacing.xl),
        child: AnimatedSwitcher(
          duration: PosMotion.overlay,
          child: KeyedSubtree(
            key: ValueKey(_step),
            child: switch (_step) {
              _Step.credentials => _credentials(l10n),
              _Step.deviceName => _deviceName(l10n),
              _Step.syncing => _syncing(l10n),
              _Step.syncFailed => _syncFailed(l10n),
            },
          ),
        ),
      ),
    );
  }

  Widget _errorBanner(AppLocalizations l10n) {
    if (_error == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: PosSpacing.l),
      child: PosToast(
        message: _errorText(l10n, _error!),
        tone: PosTone.danger,
      ),
    );
  }

  Widget _credentials(AppLocalizations l10n) {
    String? required(TextEditingController c) =>
        _showRequired && c.text.trim().isEmpty ? l10n.fieldRequired : null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthHeading(title: l10n.setupTitle, subtitle: l10n.setupSubtitle),
        const SizedBox(height: PosSpacing.xl),
        _errorBanner(l10n),
        PosTextField(
          controller: _phone,
          label: l10n.setupPhoneLabel,
          hint: l10n.setupPhoneHint,
          prefixIcon: Icons.phone_outlined,
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.next,
          autofocus: true,
          large: true,
          errorText: required(_phone),
          onSubmitted: (_) => _passwordFocus.requestFocus(),
        ),
        const SizedBox(height: PosSpacing.l),
        PosTextField(
          controller: _password,
          focusNode: _passwordFocus,
          label: l10n.setupPasswordLabel,
          prefixIcon: Icons.lock_outline,
          obscureText: true,
          textInputAction: TextInputAction.done,
          large: true,
          errorText: required(_password),
          onSubmitted: (_) => _next(),
        ),
        const SizedBox(height: PosSpacing.xl),
        PosButton(
          label: l10n.setupNext,
          expand: true,
          shortcut: 'Enter',
          onPressed: _next,
        ),
      ],
    );
  }

  Widget _deviceName(AppLocalizations l10n) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      AuthHeading(title: l10n.setupDeviceNameTitle),
      const SizedBox(height: PosSpacing.xl),
      _errorBanner(l10n),
      PosTextField(
        controller: _name,
        label: l10n.setupDeviceNameLabel,
        helper: l10n.setupDeviceNameHelper,
        prefixIcon: Icons.point_of_sale_outlined,
        autofocus: true,
        large: true,
        enabled: !_busy,
        errorText: _showRequired && _name.text.trim().isEmpty
            ? l10n.fieldRequired
            : null,
        onSubmitted: (_) => _connect(),
      ),
      const SizedBox(height: PosSpacing.xl),
      PosButton(
        label: l10n.setupConnect,
        expand: true,
        loading: _busy,
        onPressed: _connect,
      ),
    ],
  );

  Widget _syncing(AppLocalizations l10n) {
    final p = PosPalette.of(context);
    return Column(
      children: [
        AuthHeading(title: l10n.setupSyncTitle),
        const SizedBox(height: PosSpacing.xl),
        const SizedBox.square(
          dimension: PosSizes.keypadKey,
          child: CircularProgressIndicator(strokeWidth: 5),
        ),
        const SizedBox(height: PosSpacing.l),
        Text(
          l10n.setupSyncProgress(_synced),
          style: PosTypography.body.copyWith(
            color: p.textSecondary,
            fontFeatures: PosTypography.tabular,
          ),
        ),
      ],
    );
  }

  Widget _syncFailed(AppLocalizations l10n) => PosEmptyState(
    icon: Icons.cloud_off,
    tone: PosTone.danger,
    title: l10n.setupSyncFailed,
    action: PosButton(
      label: l10n.actionRetry,
      icon: Icons.refresh,
      onPressed: () => unawaited(_sync()),
    ),
  );
}

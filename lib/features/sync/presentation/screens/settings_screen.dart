import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/services/exchange_rate_service.dart';
import '../../../../core/utils/currency_helper.dart';
import '../../../search/data/igdb_cache_service.dart';
import '../../../search/data/igdb_service.dart';
import '../../../tracker/presentation/controllers/library_notifier.dart';
import '../controllers/settings_notifier.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _proxyUrlController;
  late final TextEditingController _clientIdController;
  late final TextEditingController _clientSecretController;

  bool _isTestingConnection = false;
  String? _testConnectionResult;
  bool _isSyncingRates = false;
  bool _showDirectCredentials = false;
  bool _showTwitchTutorial = false;
  bool _isEditingSecret = false;

  int _cacheSizeBytes = 0;
  int _cachedGamesCount = 0;
  int _cachedQueriesCount = 0;
  bool _isClearingCache = false;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsNotifierProvider);
    _proxyUrlController = TextEditingController(
      text: settings.workerProxyUrl.isNotEmpty ? settings.workerProxyUrl : ApiConstants.igdbProxyUrl,
    );
    _clientIdController = TextEditingController(text: settings.twitchClientId);
    _clientSecretController = TextEditingController();
    _showDirectCredentials = settings.twitchClientId.isNotEmpty || settings.hasTwitchClientSecret;
    _loadCacheStats();
  }

  @override
  void dispose() {
    _proxyUrlController.dispose();
    _clientIdController.dispose();
    _clientSecretController.dispose();
    super.dispose();
  }

  Future<void> _loadCacheStats() async {
    final cacheService = ref.read(igdbCacheServiceProvider);
    final bytes = await cacheService.getSizeBytes();
    if (mounted) {
      setState(() {
        _cacheSizeBytes = bytes;
        _cachedGamesCount = cacheService.cachedGamesCount;
        _cachedQueriesCount = cacheService.cachedQueriesCount;
      });
    }
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTestingConnection = true;
      _testConnectionResult = null;
    });

    final settingsRepo = ref.read(settingsRepositoryProvider);
    final secret = _clientSecretController.text.trim().isNotEmpty
        ? _clientSecretController.text.trim()
        : settingsRepo.getDecryptedTwitchClientSecret();

    final service = IGDBService(
      workerProxyUrl: _proxyUrlController.text.trim(),
      twitchClientId: _clientIdController.text.trim(),
      twitchClientSecret: secret,
      cacheService: ref.read(igdbCacheServiceProvider),
    );
    final success = await service.testConnection();

    if (mounted) {
      setState(() {
        _isTestingConnection = false;
        _testConnectionResult = success
            ? (service.hasDirectTwitchCredentials
                ? 'Connection successful! Direct Twitch OAuth & IGDB v4 operational.'
                : 'Connection successful! Cloudflare Worker proxy is operational.')
            : 'Connection failed. Verify endpoint URL, Twitch credentials, or internet access.';
      });
    }
  }

  Future<void> _saveSettings() async {
    final notifier = ref.read(settingsNotifierProvider.notifier);
    final proxyUrl = _proxyUrlController.text.trim();
    await notifier.updateWorkerProxyUrl(proxyUrl);
    await notifier.updateTwitchCredentials(
      clientId: _clientIdController.text.trim(),
      clientSecret: _clientSecretController.text.trim().isNotEmpty
          ? _clientSecretController.text.trim()
          : null,
    );
    _clientSecretController.clear();

    if (mounted) {
      setState(() {
        _isEditingSecret = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('API & Credentials saved successfully!'),
          backgroundColor: LycorisColors.success,
        ),
      );
    }
  }

  Future<void> _resetProxyToDefault() async {
    final notifier = ref.read(settingsNotifierProvider.notifier);
    await notifier.resetWorkerProxyUrl();
    _proxyUrlController.text = ApiConstants.igdbProxyUrl;
    if (mounted) {
      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Proxy URL reset to default.'),
          backgroundColor: LycorisColors.info,
        ),
      );
    }
  }

  Future<void> _confirmClearCache() async {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colorScheme.surfaceContainerHigh,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: colorScheme.outlineVariant.withAlpha(60)),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: colorScheme.error, size: 28),
            const SizedBox(width: 10),
            const Text('Clear Metadata Cache?'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Clearing the local metadata cache will permanently delete all stored game details and search indexes.',
              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: colorScheme.errorContainer.withAlpha(40),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: colorScheme.error.withAlpha(90)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '⚠️ Warning:',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: colorScheme.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '• Future searches will need to query IGDB over the network, causing slower searches.\n'
                    '• Sending frequent queries without cache may trigger IGDB rate limits (Too Many Requests / HTTP 429).\n'
                    '• Offline search for uncached titles will be unavailable.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurface,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Are you sure you want to proceed?',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: colorScheme.error,
              foregroundColor: colorScheme.onError,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isClearingCache = true);
      await ref.read(igdbCacheServiceProvider).clearCache();
      await _loadCacheStats();
      if (mounted) {
        setState(() => _isClearingCache = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Metadata cache successfully cleared.'),
            backgroundColor: LycorisColors.success,
          ),
        );
      }
    }
  }

  Future<void> _handleFileExport() async {
    final jsonPayload = ref.read(settingsNotifierProvider.notifier).exportToJson();
    await Clipboard.setData(ClipboardData(text: jsonPayload));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Library JSON backup copied to clipboard! Save to your backup file.'),
          backgroundColor: LycorisColors.success,
        ),
      );
    }
  }

  Future<void> _handleFileImport() async {
    try {
      final pickedFiles = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
      );

      if (pickedFiles.isNotEmpty) {
        final file = pickedFiles.first;
        final fileBytes = await file.readAsBytes();
        final content = utf8.decode(fileBytes);

        if (content.isNotEmpty) {
          final count = await ref.read(settingsNotifierProvider.notifier).importFromJson(content);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Imported $count entries via LWW merge!'),
                backgroundColor: LycorisColors.success,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            backgroundColor: LycorisColors.error,
          ),
        );
      }
    }
  }

  Future<void> _handleSyncRates({bool force = false}) async {
    setState(() => _isSyncingRates = true);
    final success = await ref
        .read(exchangeRatesNotifierProvider.notifier)
        .manualSync(force: force);

    if (mounted) {
      setState(() => _isSyncingRates = false);
      if (success) {
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            const SnackBar(
              content: Text('Exchange rates updated successfully!'),
              backgroundColor: LycorisColors.success,
            ),
          );
      } else {
        final rates = ref.read(exchangeRatesNotifierProvider);
        final remaining = ExchangeRateService.timeUntilNextSync(rates: rates);
        final cooldownText = ExchangeRateService.formatCooldownRemaining(remaining);
        ScaffoldMessenger.of(context)
          ..clearSnackBars()
          ..showSnackBar(
            SnackBar(
              content: Text(
                ExchangeRateService.canSync(rates: rates)
                    ? 'Failed to fetch live exchange rates. Check connection.'
                    : '24-hour sync cooldown active. Next sync in $cooldownText.',
              ),
              backgroundColor: LycorisColors.warning,
            ),
          );
      }
    }
  }

  Future<void> _showCurrencyPicker(BuildContext context, String currentCurrency) async {
    await CurrencyHelper.showCurrencyPicker(
      context,
      currentCurrency: currentCurrency,
      onSelected: (code) async {
        await ref.read(settingsNotifierProvider.notifier).updatePrimaryCurrency(code);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = ref.watch(settingsNotifierProvider);
    final exchangeRates = ref.watch(exchangeRatesNotifierProvider);
    final currentCurrencyOption = CurrencyHelper.getOption(settings.primaryCurrency);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Settings',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 1. Cloudflare Worker Proxy & IGDB v4
          // 1. Cloudflare Worker Proxy & IGDB v4
          _buildCard(
            context: context,
            title: 'IGDB Metadata Proxy & API',
            subtitle: 'Secure Cloudflare Worker proxy forwarding APICalypse queries to IGDB v4, or your own direct Twitch API.',
            icon: Icons.cloud_outlined,
            children: [
              TextField(
                controller: _proxyUrlController,
                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
                decoration: _inputDecoration(
                  context,
                  label: 'Cloudflare Worker Proxy URL',
                  hint: 'https://lycoris-proxy.workers.dev',
                  icon: Icons.link_rounded,
                ),
              ),
              if (_proxyUrlController.text.trim() != ApiConstants.igdbProxyUrl) ...[
                const SizedBox(height: 6),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                    icon: const Icon(Icons.restart_alt_rounded, size: 16),
                    label: const Text('Reset to Default Proxy'),
                    onPressed: _resetProxyToDefault,
                  ),
                ),
              ],
              const SizedBox(height: 12),

              // Direct Twitch Credentials Accordion
              Container(
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest.withAlpha(50),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outlineVariant.withAlpha(50)),
                ),
                child: Column(
                  children: [
                    ListTile(
                      dense: true,
                      leading: Icon(
                        Icons.vpn_key_rounded,
                        color: _showDirectCredentials ? colorScheme.primary : colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      title: Text(
                        'Direct Twitch Developer API',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      subtitle: Text(
                        settings.hasTwitchClientSecret
                            ? 'Custom credentials configured (Write-only protected)'
                            : 'Host your own credentials to bypass shared worker limits',
                        style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                      trailing: Switch(
                        value: _showDirectCredentials,
                        onChanged: (val) {
                          setState(() {
                            _showDirectCredentials = val;
                          });
                        },
                      ),
                    ),
                    if (_showDirectCredentials) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Divider(height: 1),
                            const SizedBox(height: 10),

                            // Tutorial Expander
                            InkWell(
                              onTap: () => setState(() => _showTwitchTutorial = !_showTwitchTutorial),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                decoration: BoxDecoration(
                                  color: colorScheme.primaryContainer.withAlpha(50),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: colorScheme.primary.withAlpha(60)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.school_rounded, size: 18, color: colorScheme.primary),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'How to get Twitch Client ID & Secret',
                                        style: theme.textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w700,
                                          color: colorScheme.primary,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      _showTwitchTutorial ? Icons.expand_less_rounded : Icons.expand_more_rounded,
                                      size: 18,
                                      color: colorScheme.primary,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            if (_showTwitchTutorial) ...[
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest.withAlpha(80),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '1. Go to dev.twitch.tv/console and log in.\n'
                                      '2. Click "Register Your Application".\n'
                                      '3. Set Name to "Lycoris", OAuth Redirect to "http://localhost", and Category to "Application Integration".\n'
                                      '4. Click "Create", then copy your Client ID.\n'
                                      '5. Click "New Secret" to generate your Client Secret.\n'
                                      '6. Paste both below. Your secret is encrypted on-device and write-only.',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        height: 1.45,
                                        color: colorScheme.onSurface,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            const SizedBox(height: 12),
                            TextField(
                              controller: _clientIdController,
                              style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
                              decoration: _inputDecoration(
                                context,
                                label: 'Twitch Client ID',
                                hint: 'e.g. 9y5k10abcdef...',
                                icon: Icons.badge_outlined,
                              ),
                            ),
                            const SizedBox(height: 10),

                            // Write-Only Secret Field
                            if (settings.hasTwitchClientSecret && !_isEditingSecret) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: colorScheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: colorScheme.outlineVariant.withAlpha(80)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.lock_rounded, size: 18, color: LycorisColors.success),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Client Secret: ••••••••••••••••',
                                            style: theme.textTheme.bodyMedium?.copyWith(
                                              fontWeight: FontWeight.w700,
                                              color: colorScheme.onSurface,
                                              letterSpacing: 1.5,
                                            ),
                                          ),
                                          Text(
                                            'Protected & encrypted on-device (Write-only)',
                                            style: theme.textTheme.bodySmall?.copyWith(
                                              color: colorScheme.onSurfaceVariant,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () => setState(() => _isEditingSecret = true),
                                      child: const Text('Change'),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline_rounded, size: 18),
                                      tooltip: 'Remove Secret',
                                      onPressed: () async {
                                        await ref.read(settingsNotifierProvider.notifier).clearTwitchCredentials();
                                        _clientIdController.clear();
                                        _clientSecretController.clear();
                                      },
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              TextField(
                                controller: _clientSecretController,
                                obscureText: true,
                                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
                                decoration: _inputDecoration(
                                  context,
                                  label: 'Twitch Client Secret',
                                  hint: 'Paste new Client Secret...',
                                  icon: Icons.password_rounded,
                                ),
                              ),
                              if (settings.hasTwitchClientSecret) ...[
                                const SizedBox(height: 4),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton(
                                    onPressed: () => setState(() => _isEditingSecret = false),
                                    child: const Text('Cancel changing secret'),
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 14),
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  FilledButton.tonalIcon(
                    icon: _isTestingConnection
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.primary,
                            ),
                          )
                        : const Icon(Icons.network_check_rounded, size: 18),
                    label: const Text('Test Connection'),
                    onPressed: _isTestingConnection ? null : _testConnection,
                  ),
                  FilledButton.icon(
                    icon: const Icon(Icons.save_rounded, size: 18),
                    label: const Text('Save Settings'),
                    onPressed: _saveSettings,
                  ),
                ],
              ),
              if (_testConnectionResult != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _testConnectionResult!.startsWith('Connection successful')
                        ? LycorisColors.success.withAlpha(25)
                        : colorScheme.errorContainer.withAlpha(50),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _testConnectionResult!.startsWith('Connection successful')
                          ? LycorisColors.success.withAlpha(120)
                          : colorScheme.error.withAlpha(120),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _testConnectionResult!.startsWith('Connection successful')
                            ? Icons.check_circle_rounded
                            : Icons.error_outline_rounded,
                        size: 18,
                        color: _testConnectionResult!.startsWith('Connection successful')
                            ? LycorisColors.success
                            : colorScheme.error,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _testConnectionResult!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _testConnectionResult!.startsWith('Connection successful')
                                ? LycorisColors.success
                                : colorScheme.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),

          const SizedBox(height: 14),

          // Metadata Cache Management Card
          _buildCard(
            context: context,
            title: 'Game Metadata Cache',
            subtitle: 'Permanent client-side storage for instant offline searches and zero repeated network requests.',
            icon: Icons.storage_rounded,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest.withAlpha(80),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Current Cache Size',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            IGDBCacheService.formatBytes(_cacheSizeBytes),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '$_cachedGamesCount games · $_cachedQueriesCount searches',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: colorScheme.error,
                      side: BorderSide(color: colorScheme.error.withAlpha(120)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    ),
                    icon: _isClearingCache
                        ? SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.error,
                            ),
                          )
                        : const Icon(Icons.delete_sweep_rounded, size: 18),
                    label: const Text('Clear Cache'),
                    onPressed: _isClearingCache ? null : _confirmClearCache,
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 2. Display Currency & Live FX Rates
          _buildCard(
            context: context,
            title: 'Display Currency & FX Rates',
            subtitle: 'Standardize multi-currency purchase values across all library entries with live or offline conversion.',
            icon: Icons.currency_exchange_rounded,
            children: [
              // Primary Currency Tile
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CurrencySymbolBox(
                  currencyCode: currentCurrencyOption.code,
                  size: 38,
                  backgroundColor: colorScheme.primaryContainer.withAlpha(120),
                  textColor: colorScheme.primary,
                ),
                title: const Text(
                  'Primary Currency',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  '${currentCurrencyOption.name} (${currentCurrencyOption.symbol})',
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14),
                onTap: () => _showCurrencyPicker(context, settings.primaryCurrency),
              ),

              Divider(color: colorScheme.outlineVariant.withAlpha(50), height: 24),

              // Exchange Rates Sync Tile
              Builder(
                builder: (context) {
                  final canSync = ExchangeRateService.canSync(rates: exchangeRates);
                  final remaining = ExchangeRateService.timeUntilNextSync(rates: exchangeRates);
                  final cooldownText = ExchangeRateService.formatCooldownRemaining(remaining);

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: colorScheme.primaryContainer.withAlpha(120),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.sync_rounded, color: colorScheme.primary, size: 22),
                    ),
                    title: const Text(
                      'Live Exchange Rates',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      exchangeRates.isSeed
                          ? 'Using baseline offline rates. Tap to sync live rates.'
                          : 'Synced: ${DateFormat.yMMMd().add_jm().format(exchangeRates.lastUpdated)} ${canSync ? "• Ready to sync" : "• Next in $cooldownText"}',
                      style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                    ),
                    trailing: _isSyncingRates
                        ? SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colorScheme.primary,
                            ),
                          )
                        : IconButton(
                            icon: const Icon(Icons.refresh_rounded),
                            tooltip: canSync ? 'Fetch live FX rates' : 'Cooldown active ($cooldownText)',
                            onPressed: () => _handleSyncRates(),
                          ),
                  );
                },
              ),

              const SizedBox(height: 12),

              // Live Rates Overview Matrix
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outlineVariant.withAlpha(60)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'CONVERSION BENCHMARK (BASE: 1 USD)',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: CurrencyHelper.supportedCurrencies
                          .where((c) => c.code != 'USD')
                          .map((c) {
                        final rate = exchangeRates.rates[c.code] ?? 1.0;
                        final formattedRate = c.code == 'JPY'
                            ? rate.toStringAsFixed(0)
                            : rate.toStringAsFixed(2);
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: colorScheme.surfaceContainer,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: colorScheme.outlineVariant.withAlpha(40)),
                          ),
                          child: Text(
                            '${c.code}: ${c.symbol}$formattedRate',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 3. Google Drive AppData Sync
          _buildCard(
            context: context,
            title: 'Google Drive Sync',
            subtitle: 'Backup to the Lycoris folder in your Google Drive with Last-Write-Wins (LWW) conflict merge.',
            icon: Icons.cloud_sync_rounded,
            children: [
              if (settings.lastSyncedAt != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    children: [
                      Icon(Icons.schedule, size: 14, color: colorScheme.onSurfaceVariant),
                      const SizedBox(width: 6),
                      Text(
                        'Last Synced: ${DateFormat.yMMMd().add_jms().format(settings.lastSyncedAt!)}',
                        style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              if (settings.syncStatusMessage != null) ...[
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    settings.syncStatusMessage!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.cloud_upload_outlined, size: 18),
                      label: const Text('Backup'),
                      onPressed: settings.isSyncing
                          ? null
                          : () => ref.read(settingsNotifierProvider.notifier).backupToDrive(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.cloud_download_outlined, size: 18),
                      label: const Text('Restore'),
                      onPressed: settings.isSyncing
                          ? null
                          : () => ref.read(settingsNotifierProvider.notifier).restoreFromDrive(),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 4. Offline JSON File Backup & Portability
          _buildCard(
            context: context,
            title: 'Offline JSON Backup',
            subtitle: '100% offline portability. Copy raw JSON to clipboard or import from local storage.',
            icon: Icons.folder_zip_outlined,
            children: [
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.content_copy_rounded, size: 18),
                      label: const Text('Copy JSON'),
                      onPressed: _handleFileExport,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.file_open_rounded, size: 18),
                      label: const Text('Import JSON'),
                      onPressed: _handleFileImport,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 14),

          // 5. Data Management (Danger Zone)
          _buildCard(
            context: context,
            title: 'Reset Library',
            subtitle: 'Permanently remove all local game records and clear local Hive cache.',
            icon: Icons.delete_outline_rounded,
            isDestructive: true,
            children: [
              FilledButton.tonalIcon(
                icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                label: const Text('Clear All Game Records'),
                style: FilledButton.styleFrom(
                  backgroundColor: colorScheme.errorContainer.withAlpha(70),
                  foregroundColor: colorScheme.error,
                ),
                onPressed: () async {
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Clear All Game Records?'),
                      content: const Text(
                        'This will delete all games, DLCs, and playtime logs from your local database. This cannot be undone unless you have a backup.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
                          onPressed: () => Navigator.pop(ctx, true),
                          child: const Text('Delete Everything'),
                        ),
                      ],
                    ),
                  );

                  if (confirm == true) {
                    await ref.read(libraryNotifierProvider.notifier).clearAll();
                  }
                },
              ),
            ],
          ),

          const SizedBox(height: 24),

          // 6. About Lycoris
          Center(
            child: Column(
              children: [
                Icon(Icons.sports_esports_rounded, size: 28, color: colorScheme.primary),
                const SizedBox(height: 6),
                Text(
                  'Lycoris',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'v1.0.0 • com.ytfl.lycoris',
                  style: theme.textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 4),
                Text(
                  'Offline-first gaming library & investment ROI tracker',
                  style: theme.textTheme.labelSmall?.copyWith(color: colorScheme.onSurfaceVariant.withAlpha(160)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final iconColor = isDestructive ? colorScheme.error : colorScheme.primary;

    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainer,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDestructive
              ? colorScheme.error.withAlpha(60)
              : colorScheme.outlineVariant.withAlpha(50),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDestructive
                        ? colorScheme.errorContainer.withAlpha(60)
                        : colorScheme.primaryContainer.withAlpha(100),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: iconColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    BuildContext context, {
    required String label,
    String? hint,
    IconData? icon,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, size: 20, color: colorScheme.onSurfaceVariant) : null,
      filled: true,
      fillColor: colorScheme.surfaceContainerHigh,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outlineVariant.withAlpha(80)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.outlineVariant.withAlpha(80)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 1.5),
      ),
    );
  }
}

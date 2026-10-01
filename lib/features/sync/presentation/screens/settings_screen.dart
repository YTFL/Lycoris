import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/colors.dart';
import '../../../../core/utils/currency_converter.dart';
import '../../../search/data/igdb_service.dart';
import '../../../tracker/presentation/controllers/vault_notifier.dart';
import '../controllers/settings_notifier.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  late final TextEditingController _proxyUrlController;
  late final TextEditingController _clientIdController;
  late final TextEditingController _bearerTokenController;

  bool _isTestingConnection = false;
  String? _testConnectionResult;

  @override
  void initState() {
    super.initState();
    final settings = ref.read(settingsNotifierProvider);
    _proxyUrlController = TextEditingController(
      text: settings.workerProxyUrl.isNotEmpty ? settings.workerProxyUrl : ApiConstants.igdbProxyUrl,
    );
    _clientIdController = TextEditingController(text: settings.twitchClientId);
    _bearerTokenController = TextEditingController(text: settings.twitchBearerToken);
  }

  @override
  void dispose() {
    _proxyUrlController.dispose();
    _clientIdController.dispose();
    _bearerTokenController.dispose();
    super.dispose();
  }

  Future<void> _testConnection() async {
    setState(() {
      _isTestingConnection = true;
      _testConnectionResult = null;
    });

    final service = IGDBService(workerProxyUrl: _proxyUrlController.text.trim());
    final success = await service.testConnection();

    if (mounted) {
      setState(() {
        _isTestingConnection = false;
        _testConnectionResult = success
            ? 'Connection successful! IGDB v4 proxy is operational.'
            : 'Connection failed. Verify worker endpoint URL or internet access.';
      });
    }
  }

  Future<void> _saveSettings() async {
    final notifier = ref.read(settingsNotifierProvider.notifier);
    final proxyUrl = _proxyUrlController.text.trim();
    await notifier.updateWorkerProxyUrl(proxyUrl);
    await notifier.updateTwitchCredentials(
      clientId: _clientIdController.text.trim(),
      bearerToken: _bearerTokenController.text.trim(),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Settings saved successfully!'),
          backgroundColor: LycorisColors.success,
        ),
      );
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final settings = ref.watch(settingsNotifierProvider);

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
          _buildCard(
            context: context,
            title: 'IGDB Metadata Proxy',
            subtitle: 'Secure Cloudflare Worker proxy forwarding APICalypse queries to IGDB v4.',
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
                    label: const Text('Save Proxy'),
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

          // 2. Primary Display Currency
          _buildCard(
            context: context,
            title: 'Display Currency',
            subtitle: 'Standardize multi-currency purchase values across all library entries.',
            icon: Icons.currency_exchange_rounded,
            children: [
              DropdownButtonFormField<String>(
                initialValue: settings.primaryCurrency,
                dropdownColor: colorScheme.surfaceContainerHigh,
                style: theme.textTheme.bodyMedium?.copyWith(color: colorScheme.onSurface),
                decoration: _inputDecoration(
                  context,
                  label: 'Primary Currency',
                  icon: Icons.payments_outlined,
                ),
                items: CurrencyConverter.supportedCurrencies.map((c) {
                  return DropdownMenuItem(
                    value: c,
                    child: Text('$c (${CurrencyConverter.symbolFor(c)})'),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) {
                    ref.read(settingsNotifierProvider.notifier).updatePrimaryCurrency(val);
                  }
                },
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
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  FilledButton.icon(
                    icon: const Icon(Icons.cloud_upload_rounded, size: 18),
                    label: const Text('Backup Now'),
                    onPressed: settings.isSyncing
                        ? null
                        : () => ref.read(settingsNotifierProvider.notifier).backupToDrive(),
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.cloud_download_rounded, size: 18),
                    label: const Text('Restore from Drive'),
                    onPressed: settings.isSyncing
                        ? null
                        : () => ref.read(settingsNotifierProvider.notifier).restoreFromDrive(),
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
              Wrap(
                spacing: 12,
                runSpacing: 10,
                children: [
                  OutlinedButton.icon(
                    icon: const Icon(Icons.content_copy_rounded, size: 18),
                    label: const Text('Copy JSON'),
                    onPressed: _handleFileExport,
                  ),
                  OutlinedButton.icon(
                    icon: const Icon(Icons.file_open_rounded, size: 18),
                    label: const Text('Import JSON'),
                    onPressed: _handleFileImport,
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
                    await ref.read(vaultNotifierProvider.notifier).clearAll();
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
                  'Offline-first gaming ledger & investment ROI tracker',
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

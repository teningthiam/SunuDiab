import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../core/config.dart';
import '../core/theme.dart';
import '../l10n/strings.dart';
import 'common.dart';

/// Permet de régler l'adresse du backend sans recompiler (appui long sur le logo).
Future<void> showServerDialog(BuildContext context) async {
  final ctrl = TextEditingController(text: ServerConfig.baseUrl);
  String? result;
  bool? ok;
  bool testing = false;

  await showDialog<void>(
    context: context,
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setState) => AlertDialog(
        title: Text(ctx.t('server_title')),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: ctrl,
                keyboardType: TextInputType.url,
                decoration: deco(
                  ctx.t('server_current'),
                  hint: ctx.t('server_hint'),
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(44),
                ),
                onPressed: testing
                    ? null
                    : () async {
                        setState(() {
                          testing = true;
                          result = null;
                        });
                        final url = ServerConfig.normalize(ctrl.text);
                        try {
                          final r = await http
                              .get(Uri.parse('$url/v3/api-docs'))
                              .timeout(const Duration(seconds: 8));
                          ok = r.statusCode == 200;
                        } catch (_) {
                          ok = false;
                        }
                        setState(() {
                          testing = false;
                          result = ctx.t(
                            ok == true ? 'server_ok' : 'server_fail',
                          );
                        });
                      },
                icon: testing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.wifi_tethering),
                label: Text(ctx.t('server_test')),
              ),
              if (result != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    result!,
                    style: TextStyle(
                      color: ok == true ? AppColors.green : AppColors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await ServerConfig.reset();
              ctrl.text = ServerConfig.baseUrl;
              setState(() => result = null);
            },
            child: Text(ctx.t('server_default')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(ctx.t('cancel')),
          ),
          TextButton(
            onPressed: () async {
              await ServerConfig.save(ctrl.text);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text(ctx.t('save')),
          ),
        ],
      ),
    ),
  );
  ctrl.dispose();
}

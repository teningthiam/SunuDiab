import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../core/theme.dart';
import '../l10n/strings.dart';
import '../models/models.dart';
import '../providers/data_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/common.dart';

class AdviceScreen extends StatelessWidget {
  const AdviceScreen({super.key});

  void _open(BuildContext context, Conseil c, String lang) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    c.title(lang),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                AudioButton(text: '${c.title(lang)}. ${c.body(lang)}'),
              ],
            ),
            const SizedBox(height: 10),
            Flexible(
              child: SingleChildScrollView(
                child: Text(
                  c.body(lang),
                  style: const TextStyle(fontSize: 16, height: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataProvider>();
    final lang = context.watch<SettingsProvider>().lang;
    return Scaffold(
      appBar: AppBar(title: Text(context.t('advice'))),
      body: SafeArea(
        child: Column(
          children: [
            const OfflineBanner(),
            Expanded(
              child: data.conseils.isEmpty
                  ? Center(
                      child: Text(
                        context.t('no_tips'),
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: data.conseils
                          .map(
                            (c) => AppCard(
                              onTap: () => _open(context, c, lang),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (c.categorie != null)
                                    Chip2(
                                      label: c.categorie!,
                                      color: AppColors.green,
                                      soft: AppColors.greenSoft,
                                    ),
                                  const SizedBox(height: 8),
                                  Text(
                                    c.title(lang),
                                    style: const TextStyle(
                                      fontSize: 16.5,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    c.body(lang),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: AppColors.muted,
                                      height: 1.35,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

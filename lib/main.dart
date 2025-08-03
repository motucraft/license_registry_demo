import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  LicenseRegistry.addLicense(() async* {
    final license = await rootBundle.loadString('assets/license/OFL.txt');
    yield LicenseEntryWithLineBreaks(['SIL Open Font License'], license);
  });

  runApp(const MaterialApp(home: Home()));
}

class Home extends StatelessWidget {
  const Home({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ライセンス')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              child: const Text('showLicensePage'),
              onPressed: () => showLicensePage(context: context),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              child: const Text('カスタムライセンス表示'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const LicenseSummary(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class LicenseSummary extends StatelessWidget {
  const LicenseSummary({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('カスタムライセンス')),
      body: SafeArea(
        child: FutureBuilder(
          future: LicenseRegistry.licenses.toList(),
          builder: (context, snapshot) {
            if (snapshot.data case final data?
                when snapshot.connectionState == ConnectionState.done) {
              return _LicenseSummaryBody(entries: data);
            } else {
              return Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }
}

class _LicenseSummaryBody extends StatelessWidget {
  const _LicenseSummaryBody({required this.entries});

  final List<LicenseEntry> entries;

  @override
  Widget build(BuildContext context) {
    final Map<String, Set<LicenseEntry>> packageToEntries = {};
    for (final entry in entries) {
      for (final pkg in entry.packages) {
        packageToEntries.putIfAbsent(pkg, () => <LicenseEntry>{}).add(entry);
      }
    }

    final packageNames = packageToEntries.keys.toList()..sort();

    return ListView.builder(
      itemCount: packageNames.length,
      itemBuilder: (context, index) {
        final pkg = packageNames[index];
        final entries = packageToEntries[pkg]!.toList();
        return ListTile(
          title: Text(pkg),
          subtitle: Text('ライセンス: ${entries.length} 件'),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) {
                  return LicenseDetail(packageName: pkg, entries: entries);
                },
              ),
            );
          },
        );
      },
    );
  }
}

class LicenseDetail extends StatelessWidget {
  const LicenseDetail({
    super.key,
    required this.packageName,
    required this.entries,
  });

  final String packageName;
  final List<LicenseEntry> entries;

  @override
  Widget build(BuildContext context) {
    final licenseWidgets = [
      for (final entry in entries) ...[
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 16),
          child: Divider(),
        ),
        for (final paragraph in entry.paragraphs)
          if (paragraph.indent == LicenseParagraph.centeredIndent)
            Text(paragraph.text, textAlign: TextAlign.center)
          else
            Padding(
              padding: EdgeInsetsDirectional.only(
                top: 8,
                start: 16.0 * paragraph.indent,
              ),
              child: Text(paragraph.text),
            ),
      ],
    ];

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(packageName, style: TextStyle(fontSize: 16)),
            Text('ライセンス: ${entries.length} 件', style: TextStyle(fontSize: 12)),
          ],
        ),
      ),
      body: SafeArea(
        child: ListView(padding: EdgeInsets.all(16), children: licenseWidgets),
      ),
    );
  }
}

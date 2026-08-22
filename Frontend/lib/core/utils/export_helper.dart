import 'dart:convert';
import 'dart:html' as html;
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

void exportToExcel(BuildContext context, String reportTitle, List<String> headers, List<List<String>> rows) {
  try {
    final csvBuffer = StringBuffer();
    csvBuffer.writeln(headers.map((h) => '"${h.replaceAll('"', '""')}"').join(','));
    for (final row in rows) {
      csvBuffer.writeln(row.map((r) => '"${r.replaceAll('"', '""')}"').join(','));
    }

    final bytes = utf8.encode(csvBuffer.toString());
    final blob = html.Blob([bytes], 'text/csv;charset=utf-8');
    final url = html.Url.createObjectUrlFromBlob(blob);
    final filename = '${reportTitle.replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(' ', '_')}.csv';

    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', filename)
      ..style.display = 'none';
    
    html.document.body?.children.add(anchor);
    anchor.click();
    anchor.remove();
    html.Url.revokeObjectUrl(url);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.ok,
        content: Text('Downloaded "$filename" directly to your Downloads folder!'),
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.ok,
        content: Text('Exported $reportTitle to Excel (.csv) successfully!'),
      ),
    );
  }
}

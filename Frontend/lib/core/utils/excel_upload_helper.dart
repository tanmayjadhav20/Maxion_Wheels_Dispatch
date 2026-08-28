import 'dart:convert';
import 'dart:html' as html;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import '../../data/datasources/remote_api.dart';
import '../constants/app_colors.dart';

/// Helper to open native file picker for Excel (.xlsx, .xls, .csv) and parse records for SAP dump
void pickAndParseSapExcelFile({
  required BuildContext context,
  required RemoteApi remoteApi,
  required Function(List<Map<String, dynamic>> items, String? invoiceNumber, String? customerName, String? vehicleNumber) onParsed,
}) {
  try {
    final uploadInput = html.FileUploadInputElement()
      ..accept = '.xlsx, .xls, .csv, text/csv, application/vnd.openxmlformats-officedocument.spreadsheetml.sheet, application/vnd.ms-excel'
      ..style.display = 'none';

    html.document.body?.children.add(uploadInput);

    uploadInput.onChange.listen((e) async {
      final files = uploadInput.files;
      if (files == null || files.isEmpty) return;

      final file = files[0];
      final reader = html.FileReader();

      reader.onLoadEnd.listen((e) async {
        final rawResult = reader.result;
        if (rawResult == null) return;

        try {
          // Convert array buffer to base64
          Uint8List bytes;
          if (rawResult is ByteBuffer) {
            bytes = Uint8List.view(rawResult);
          } else if (rawResult is Uint8List) {
            bytes = rawResult;
          } else if (rawResult is List<int>) {
            bytes = Uint8List.fromList(rawResult);
          } else {
            bytes = Uint8List.fromList(utf8.encode(rawResult.toString()));
          }

          final base64String = base64Encode(bytes);

          // Show parsing progress
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.ribbonPink,
              duration: const Duration(seconds: 1),
              content: Text('Parsing "${file.name}" through SAP Excel engine...'),
            ),
          );

          // Call backend Excel parser
          final response = await remoteApi.parseExcelDump(base64String, file.name);

          if (response['success'] == true && response['items'] != null) {
            final List<dynamic> rawItems = response['items'];
            final List<Map<String, dynamic>> parsedItems = rawItems.map((i) => Map<String, dynamic>.from(i)).toList();
            final invNo = response['invoiceNumber'] as String?;
            final cust = response['customerName'] as String?;
            final veh = response['vehicleNumber'] as String?;

            onParsed(parsedItems, invNo, cust, veh);

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.ok,
                content: Text('Successfully parsed "${file.name}" -> ${parsedItems.length} lines loaded!'),
              ),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: AppColors.warn,
                content: Text(response['message'] ?? 'Failed to parse Excel file format.'),
              ),
            );
          }
        } catch (err) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors.danger,
              content: Text('Error parsing Excel file: $err'),
            ),
          );
        }
      });

      reader.readAsArrayBuffer(file);
      uploadInput.remove();
    });

    uploadInput.click();
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.danger,
        content: Text('File picker not supported in this environment: $e'),
      ),
    );
  }
}

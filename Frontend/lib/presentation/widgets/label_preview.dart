import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../core/utils/label_stock.dart';

/// On-screen proof of a physical label, drawn at the stock's true aspect ratio.
///
/// The preview used to be a square card regardless of what was being printed,
/// so an operator could not tell a 100x75 pallet label from a 50x25 scanning
/// strip until the roll came off the printer. This mirrors the print template
/// one-to-one: same proportions, same element order, same relative sizes.
class LabelPreview extends StatelessWidget {
  const LabelPreview({
    super.key,
    required this.stock,
    required this.qrData,
    required this.itemCode,
    this.codeText,
    this.itemDescription,
    this.details = const [],
    this.index,
    this.total,
  });

  final LabelStock stock;
  final String qrData;
  final String itemCode;
  final String? codeText;
  final String? itemDescription;
  final List<MapEntry<String, String>> details;
  final int? index;
  final int? total;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: stock.aspectRatio,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // One scale factor drives everything, so the preview stays faithful
          // at any card size: 1 unit == 1 mm on the real label.
          final mm = constraints.maxWidth / stock.widthMm;
          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(2 * mm),
              border: Border.all(color: const Color(0xFFBFBFBF)),
            ),
            clipBehavior: Clip.antiAlias,
            child: stock == LabelStock.pallet
                ? _pallet(mm)
                : _scanning(mm),
          );
        },
      ),
    );
  }

  Widget _qr(double sizeMm, double mm) {
    return SizedBox(
      width: sizeMm * mm,
      height: sizeMm * mm,
      child: QrImageView(
        data: qrData.isEmpty ? ' ' : qrData,
        version: QrVersions.auto,
        padding: EdgeInsets.all(1.2 * mm),
        backgroundColor: Colors.white,
        errorCorrectionLevel: stock == LabelStock.pallet
            ? QrErrorCorrectLevel.Q
            : QrErrorCorrectLevel.M,
        eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Colors.black,
        ),
      ),
    );
  }

  Widget _pallet(double mm) {
    return Padding(
      padding: EdgeInsets.all(3 * mm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2 * mm, vertical: 1.1 * mm),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(0.8 * mm),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'MAXION WHEELS',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 3.2 * mm,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  'PALLET MASTER',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 2 * mm,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 2.2 * mm),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _qr(stock.qrSizeMm, mm),
                  SizedBox(width: 3 * mm),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            codeText ?? '—',
                            maxLines: 1,
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 6.7 * mm,
                              fontWeight: FontWeight.w800,
                              height: 1.02,
                            ),
                          ),
                        ),
                        SizedBox(height: 0.8 * mm),
                        Text(
                          itemCode,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 3.9 * mm,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (itemDescription != null && itemDescription!.isNotEmpty) ...[
                          SizedBox(height: 0.5 * mm),
                          Text(
                            itemDescription!,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.black87, fontSize: 2.3 * mm),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          Container(height: 0.4 * mm, color: Colors.black),
          SizedBox(height: 1.5 * mm),
          Wrap(
            spacing: 3 * mm,
            runSpacing: 0.8 * mm,
            children: [
              for (final d in details.take(6))
                SizedBox(
                  width: (stock.widthMm - 6) / 2 * mm - 1.5 * mm,
                  child: Text(
                    '${d.key} ${d.value}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.black, fontSize: 2.3 * mm),
                  ),
                ),
            ],
          ),
          const Spacer(),
          Row(
            children: [
              Expanded(
                child: Text(
                  qrData,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 1.8 * mm,
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              if (index != null && total != null)
                Text(
                  '$index / $total',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 1.8 * mm,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _scanning(double mm) {
    final parts = qrData.split('|');
    final serial = parts.length > 3 ? parts[3] : (codeText ?? '—');
    final shift = parts.length > 5 ? parts[5] : 'A';
    final line = parts.length > 6 ? parts[6] : 'PL2';

    return Padding(
      padding: EdgeInsets.all(1.5 * mm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _qr(stock.qrSizeMm, mm),
          SizedBox(width: 1.5 * mm),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        itemCode,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: 2.5 * mm,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    SizedBox(width: 1 * mm),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 1 * mm,
                        vertical: 0.3 * mm,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black,
                        borderRadius: BorderRadius.circular(0.6 * mm),
                      ),
                      child: Text(
                        shift,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 1.8 * mm,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 0.4 * mm),
                Text(
                  serial,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 2.9 * mm,
                    fontWeight: FontWeight.w700,
                    fontFamily: 'monospace',
                  ),
                ),
                SizedBox(height: 0.4 * mm),
                Text(
                  'LINE $line${index != null && total != null ? ' · $index/$total' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 1.8 * mm,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

import '../../core/constants/api_endpoints.dart';
import '../../core/network/api_client.dart';

class RemoteApi {
  final ApiClient client;

  RemoteApi(this.client);

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? queryParameters}) async {
    try {
      final response = await client.dio.get(path, queryParameters: queryParameters);
      return response.data is Map<String, dynamic> ? response.data : {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> post(String path, [dynamic data]) async {
    try {
      final response = await client.dio.post(path, data: data);
      return response.data is Map<String, dynamic> ? response.data : {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> login({
    String? badgeBarcode,
    String? employeeCode,
    String? pin,
  }) async {
    try {
      final response = await client.dio.post(
        ApiEndpoints.login,
        data: {
          if (badgeBarcode != null) 'badgeBarcode': badgeBarcode,
          if (employeeCode != null) 'employeeCode': employeeCode,
          if (pin != null) 'pin': pin,
        },
      );
      return response.data is Map<String, dynamic> ? response.data : {'success': true, 'data': response.data};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getPaintPlans() async {
    final response = await client.dio.get(ApiEndpoints.paintPlan);
    return response.data;
  }

  Future<Map<String, dynamic>> getPlanVsActual() async {
    final response = await client.dio.get(ApiEndpoints.planVsActual);
    return response.data;
  }

  Future<Map<String, dynamic>> getPrepChecklist() async {
    final response = await client.dio.get(ApiEndpoints.prepChecklist);
    return response.data;
  }

  Future<Map<String, dynamic>> printWheelQr(String itemCode, {int count = 1}) async {
    final response = await client.dio.post(
      ApiEndpoints.printWheelQr,
      data: {'itemCode': itemCode, 'count': count},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> scanWheel(String itemCode, String? wheelQr) async {
    final response = await client.dio.post(
      ApiEndpoints.scanWheel,
      data: {
        'itemCode': itemCode,
        if (wheelQr != null) 'wheelQr': wheelQr,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> closePallet(String reason) async {
    final response = await client.dio.post(
      ApiEndpoints.closePallet,
      data: {'reason': reason},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> resumeHalfPallet(String halfPalletNumber) async {
    final response = await client.dio.post(
      ApiEndpoints.resumeHalfPallet,
      data: {'halfPalletNumber': halfPalletNumber},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getWarehouseMap() async {
    final response = await client.dio.get(ApiEndpoints.warehouseMap);
    return response.data;
  }

  Future<Map<String, dynamic>> getHalfPalletRegister() async {
    final response = await client.dio.get(ApiEndpoints.halfPalletRegister);
    return response.data;
  }

  Future<Map<String, dynamic>> executePutaway(String palletNumber, String scannedLocationCode) async {
    final response = await client.dio.post(
      ApiEndpoints.putaway,
      data: {
        'palletNumber': palletNumber,
        'scannedLocationCode': scannedLocationCode,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getIndents() async {
    final response = await client.dio.get(ApiEndpoints.indents);
    return response.data;
  }

  Future<Map<String, dynamic>> createIndent(Map<String, dynamic> data) async {
    final response = await client.dio.post(ApiEndpoints.indents, data: data);
    return response.data;
  }

  Future<Map<String, dynamic>> getPickLists() async {
    final response = await client.dio.get(ApiEndpoints.pickLists);
    return response.data;
  }

  Future<Map<String, dynamic>> scanPick(String pickListNumber, String locationCode, String palletNumber) async {
    final response = await client.dio.post(
      ApiEndpoints.scanPick,
      data: {
        'pickListNumber': pickListNumber,
        'scannedLocationCode': locationCode,
        'scannedPalletNumber': palletNumber,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> reassignPickList(String pickListNumber, String assignedToCode, String assignedToName) async {
    final response = await client.dio.post(
      '/picking/reassign-picklist',
      data: {
        'pickListNumber': pickListNumber,
        'assignedToCode': assignedToCode,
        'assignedToName': assignedToName,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getGatePasses() async {
    final response = await client.dio.get(ApiEndpoints.gatePasses);
    return response.data;
  }

  Future<Map<String, dynamic>> scanLoading(String gatePassNumber, String palletNumber) async {
    final response = await client.dio.post(
      ApiEndpoints.scanLoading,
      data: {
        'gatePassNumber': gatePassNumber,
        'scannedPalletNumber': palletNumber,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> verifyGateOut(String gatePassNumber, String action, String holdReason) async {
    final response = await client.dio.post(
      ApiEndpoints.verifyGateOut,
      data: {
        'gatePassNumber': gatePassNumber,
        'action': action,
        'holdReason': holdReason,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> getReturnables() async {
    final response = await client.dio.get(ApiEndpoints.returnableAssets);
    return response.data;
  }

  Future<Map<String, dynamic>> receiveReturnable(String assetNumber, String condition) async {
    final response = await client.dio.post(
      ApiEndpoints.receiveAsset,
      data: {
        'assetNumber': assetNumber,
        'condition': condition,
      },
    );
    return response.data;
  }

  Future<Map<String, dynamic>> traceLookup(String query) async {
    final response = await client.dio.get(
      ApiEndpoints.traceLookup,
      queryParameters: {'query': query},
    );
    return response.data;
  }

  Future<Map<String, dynamic>> scanToKnow(String code) async {
    final response = await client.dio.post(
      ApiEndpoints.scanToKnow,
      data: {'code': code},
    );
    return response.data;
  }
}

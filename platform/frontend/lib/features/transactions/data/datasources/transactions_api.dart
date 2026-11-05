import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_exception.dart';
import '../../../../core/network/paginated.dart';
import '../models/transaction_draft_dto.dart';
import '../models/installment_dto.dart';
import '../models/transaction_dto.dart';

final transactionsApiProvider = Provider<TransactionsApi>(
  (ref) => TransactionsApi(ref.watch(apiClientProvider)),
);

/// One method per Transaction endpoint. Throws [ApiException].
class TransactionsApi {
  TransactionsApi(this._dio);

  final Dio _dio;

  Future<Paginated<TransactionDto>> list(Map<String, dynamic> query) async {
    final response = await _send(
      () => _dio.get<Map<String, dynamic>>(
        '/transactions',
        queryParameters: query,
      ),
    );
    return Paginated.fromJson(response.data!, TransactionDto.fromJson);
  }

  Future<TransactionDto> show(int id) async {
    final response = await _send(
      () => _dio.get<Map<String, dynamic>>('/transactions/$id'),
    );
    return _unwrap(response.data!);
  }

  Future<TransactionDto> store(Map<String, dynamic> body) async {
    final response = await _send(
      () => _dio.post<Map<String, dynamic>>('/transactions', data: body),
    );
    return _unwrap(response.data!);
  }

  Future<TransactionDto> update(int id, Map<String, dynamic> body) async {
    final response = await _send(
      () => _dio.patch<Map<String, dynamic>>('/transactions/$id', data: body),
    );
    return _unwrap(response.data!);
  }

  Future<void> delete(int id) =>
      _send(() => _dio.delete<void>('/transactions/$id'));

  Future<InstallmentDto> payInstallment(int transactionId, int installmentId) =>
      _changeInstallment(transactionId, installmentId, 'pay');

  Future<InstallmentDto> unpayInstallment(
    int transactionId,
    int installmentId,
  ) => _changeInstallment(transactionId, installmentId, 'unpay');

  Future<InstallmentDto> _changeInstallment(
    int transactionId,
    int installmentId,
    String action,
  ) async {
    final response = await _send(
      () => _dio.patch<Map<String, dynamic>>(
        '/transactions/$transactionId/installments/$installmentId/$action',
      ),
    );
    return InstallmentDto.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<TransactionDraftDto> draftFromAudio(Uint8List wav) async {
    final response = await _send(
      () => _dio.post<Map<String, dynamic>>(
        '/transactions/draft',
        data: FormData.fromMap({
          'audio': MultipartFile.fromBytes(
            wav,
            filename: 'nota.wav',
            contentType: DioMediaType('audio', 'wav'),
          ),
        }),
      ),
    );
    return TransactionDraftDto.fromJson(
      response.data!['data'] as Map<String, dynamic>,
    );
  }

  Future<void> storeRecurring(Map<String, dynamic> body) =>
      _send(() => _dio.post<void>('/recurring-transactions', data: body));

  Future<void> endRecurring(int id) =>
      _send(() => _dio.patch<void>('/recurring-transactions/$id/end'));

  TransactionDto _unwrap(Map<String, dynamic> body) =>
      TransactionDto.fromJson(body['data'] as Map<String, dynamic>);

  Future<T> _send<T>(Future<T> Function() request) async {
    try {
      return await request();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

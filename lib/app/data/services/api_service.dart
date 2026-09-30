import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' as getx;
import '../../core/values/app_constants.dart';
import '../../core/widgets/custom_snackbar.dart';
import '../../routes/app_routes.dart';
import '../models/auth_tokens_model.dart';
import '../models/breed_model.dart';
import '../models/cow_model.dart';
import '../models/gaushala_model.dart';
import '../models/role_model.dart';
import '../models/shed_model.dart';
import '../models/type_model.dart';
import '../models/user_model.dart';
import 'storage_service.dart';

/// Centralized HTTP networking service powered by Dio.
/// Platform-safe for Web, Desktop, and Mobile.
class ApiService extends getx.GetxService {
  late final Dio _dio;
  late final StorageService _storageService;

  Completer<String?>? _refreshTokenCompleter;
  bool _isRedirectingToAuth = false;

  @override
  void onInit() {
    super.onInit();
    _storageService = getx.Get.find<StorageService>();
    _initDio();
  }

  void _initDio() {
    final BaseOptions options = BaseOptions(
      baseUrl: AppConstants.baseUrl,
      connectTimeout: AppConstants.connectTimeout,
      receiveTimeout: AppConstants.receiveTimeout,
      sendTimeout: AppConstants.sendTimeout,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Cache-Control': 'no-cache, no-store, must-revalidate',
        'Pragma': 'no-cache',
      },
    );

    _dio = Dio(options);

    // Request & Response Interceptors
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (RequestOptions options, RequestInterceptorHandler handler) {
          final isAuthPath = options.path.contains('/auth/login') ||
              options.path.contains('/auth/refresh-token');
          if (!isAuthPath) {
            final String? token = _storageService.getToken();
            if (token != null && token.isNotEmpty) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }

          if (kDebugMode) {
            print('[DIO REQUEST] => ${options.method} ${options.uri}');
            if (options.data != null) print('[DIO DATA] => ${options.data}');
          }
          return handler.next(options);
        },
        onResponse: (Response response, ResponseInterceptorHandler handler) {
          if (kDebugMode) {
            print('[DIO RESPONSE] <= [${response.statusCode}] ${response.requestOptions.uri}');
          }
          return handler.next(response);
        },
        onError: (DioException error, ErrorInterceptorHandler handler) async {
          if (kDebugMode) {
            print('[DIO ERROR] !! [${error.response?.statusCode}] ${error.message}');
          }

          final requestPath = error.requestOptions.path;
          final isAuthLogin = requestPath.contains('/auth/login');
          final isRefreshToken = requestPath.contains('/auth/refresh-token');

          // Handle 401 Unauthorized: automatically refresh token and retry request
          if (error.response?.statusCode == 401 && !isAuthLogin && !isRefreshToken) {
            if (_storageService.hasRefreshToken) {
              final newAccessToken = await _performTokenRefresh();
              if (newAccessToken != null && newAccessToken.isNotEmpty) {
                // Retry failed request with new access token
                final retryOptions = error.requestOptions;
                retryOptions.headers['Authorization'] = 'Bearer $newAccessToken';
                try {
                  final retryResponse = await _dio.fetch(retryOptions);
                  return handler.resolve(retryResponse);
                } on DioException catch (retryError) {
                  return handler.next(retryError);
                }
              }
            }

            // If refresh token doesn't exist or refresh failed:
            _redirectToLogin();
            return handler.next(error);
          }

          if (isRefreshToken) {
            return handler.next(error);
          }

          _handleHttpError(error);
          return handler.next(error);
        },
      ),
    );
  }

  Future<String?> _performTokenRefresh() async {
    if (_refreshTokenCompleter != null) {
      return await _refreshTokenCompleter!.future;
    }

    _refreshTokenCompleter = Completer<String?>();
    try {
      final tokens = await refreshToken();
      final newToken = tokens?.accessToken;
      _refreshTokenCompleter!.complete(newToken);
      return newToken;
    } catch (e) {
      _refreshTokenCompleter!.complete(null);
      return null;
    } finally {
      _refreshTokenCompleter = null;
    }
  }

  void _redirectToLogin() {
    if (_isRedirectingToAuth) return; // Guard: already redirecting
    _isRedirectingToAuth = true;
    _storageService.removeToken();
    _storageService.removeUser();
    CustomSnackbar.showError(
      title: 'Session Expired',
      message: 'Your login session has expired. Please sign in again.',
    );
    getx.Get.offAllNamed(AppRoutes.auth);
    // Reset after a short delay to allow future redirects after re-login
    Future.delayed(const Duration(seconds: 2), () {
      _isRedirectingToAuth = false;
    });
  }

  void _handleHttpError(DioException error) {
    final isAuthLogin = error.requestOptions.path.contains('/auth/login');
    if (error.response?.statusCode == 401 && !isAuthLogin) {
      _redirectToLogin();
      return;
    }

    String message = 'An unexpected network error occurred.';
    if (error.response?.statusCode == 429) {
      message = 'Too many requests. Please wait a few seconds before refreshing again.';
    } else if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      message = 'Connection timed out. Please check your network connection.';
    } else if (error.type == DioExceptionType.connectionError) {
      message = 'Cannot connect to server. Please verify network access.';
    } else if (error.response?.data != null && error.response?.data is Map) {
      message = error.response?.data['message']?.toString() ?? message;
    } else if (error.response?.data is String &&
        (error.response?.data as String).trim().isNotEmpty &&
        !(error.response?.data as String).contains('<html')) {
      message = (error.response?.data as String).trim();
    }

    CustomSnackbar.showError(
      title: isAuthLogin ? 'Login Failed' : 'Request Failed',
      message: message,
    );
  }

  // -------------------------------------------------------------
  // GENERIC HTTP METHODS
  // -------------------------------------------------------------
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.get<T>(path, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.post<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.put<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
  }) async {
    return await _dio.delete<T>(path, data: data, queryParameters: queryParameters, options: options);
  }

  // -------------------------------------------------------------
  // AUTHENTICATION
  // -------------------------------------------------------------
  Future<UserModel> login({
    String? username,
    String? userId,
    String? email,
    required String password,
  }) async {
    final String userIdentifier = (username ?? userId ?? email ?? '').trim();

    final response = await _dio.post(
      '/auth/login',
      data: {
        'username': userIdentifier,
        'password': password,
      },
    );

    if (response.statusCode == 200 && response.data != null) {
      final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);

      if (responseData['success'] == true && responseData['data'] != null) {
        final data = responseData['data'] as Map<String, dynamic>;
        final String? token = data['accessToken'] as String?;
        final String? refreshToken = data['refreshToken'] as String?;
        final userJson = data['user'] as Map<String, dynamic>? ?? {};

        final user = UserModel.fromJson({
          ...userJson,
          'token': token,
          'refreshToken': refreshToken,
        });

        if (token != null && token.isNotEmpty) {
          await _storageService.saveToken(token);
        }
        if (refreshToken != null && refreshToken.isNotEmpty) {
          await _storageService.saveRefreshToken(refreshToken);
        }
        await _storageService.saveUser(user);
        return user;
      }
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: response.data?['message']?.toString() ?? 'Login failed. Please check your credentials.',
    );
  }

  /// Calls the refresh token API: POST /auth/refresh-token
  /// If [token] is provided, uses that token; otherwise retrieves the stored refresh token.
  /// On success, automatically persists new tokens and returns [AuthTokensModel].
  Future<AuthTokensModel?> refreshToken({String? token}) async {
    final String? storedRefreshToken = token ?? _storageService.getRefreshToken();
    if (storedRefreshToken == null || storedRefreshToken.isEmpty) {
      if (kDebugMode) {
        print('[REFRESH TOKEN] No refresh token available');
      }
      return null;
    }

    try {
      final response = await _dio.post(
        '/auth/refresh-token',
        data: {
          'refreshToken': storedRefreshToken,
        },
      );

      if (response.statusCode == 200 && response.data != null) {
        final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        if (responseData['success'] == true && responseData['data'] != null) {
          final tokens = AuthTokensModel.fromJson(
            Map<String, dynamic>.from(responseData['data'] as Map),
          );

          if (tokens.accessToken.isNotEmpty) {
            await _storageService.saveToken(tokens.accessToken);
          }
          if (tokens.refreshToken.isNotEmpty) {
            await _storageService.saveRefreshToken(tokens.refreshToken);
          }

          final currentUser = _storageService.getUser();
          if (currentUser != null && tokens.accessToken.isNotEmpty) {
            await _storageService.saveUser(
              currentUser.copyWith(
                token: tokens.accessToken,
                refreshToken: tokens.refreshToken,
              ),
            );
          }

          if (kDebugMode) {
            print('[REFRESH TOKEN] Token refreshed successfully.');
          }
          return tokens;
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('[REFRESH TOKEN ERROR] $e');
      }
    }
    return null;
  }

  // -------------------------------------------------------------
  // ROLES MASTER
  // -------------------------------------------------------------
  Future<List<RoleModel>> getRoles() async {
    final response = await _dio.get('/roles');
    if (response.statusCode == 200 && response.data != null) {
      final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);

      if (responseData['data'] is List) {
        final List list = responseData['data'] as List;
        return list
            .map((item) => RoleModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
    }
    return [];
  }

  Future<RoleModel> createRole(String roleName) async {
    final response = await _dio.post(
      '/roles',
      data: {
        'roleName': roleName.trim(),
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.data != null) {
        final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        if (responseData['data'] is Map) {
          return RoleModel.fromJson(Map<String, dynamic>.from(responseData['data'] as Map));
        }
      }
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: response.data?['message']?.toString() ?? 'Failed to create role.',
    );
  }

  Future<RoleModel> updateRole(String id, String roleName) async {
    final response = await _dio.put(
      '/roles/$id',
      data: {
        'roleName': roleName.trim(),
      },
    );

    if (response.statusCode == 200) {
      if (response.data != null) {
        final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        if (responseData['data'] is Map) {
          return RoleModel.fromJson(Map<String, dynamic>.from(responseData['data'] as Map));
        }
      }
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: response.data?['message']?.toString() ?? 'Failed to update role.',
    );
  }

  Future<bool> deleteRole(String id) async {
    final response = await _dio.delete('/roles/$id');
    return response.statusCode == 200 || response.statusCode == 204;
  }

  // -------------------------------------------------------------
  // GAUSHALAS MASTER
  // -------------------------------------------------------------
  Future<List<GaushalaModel>> getGaushalas() async {
    final response = await _dio.get('/gaushalas');
    if (response.statusCode == 200 && response.data != null) {
      if (response.data is List) {
        final List list = response.data as List;
        return list
            .map((item) => GaushalaModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }

      final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);

      if (responseData['data'] is List) {
        final List list = responseData['data'] as List;
        return list
            .map((item) => GaushalaModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
    }
    return [];
  }

  Future<GaushalaModel> createGaushala(String gaushalaName) async {
    final response = await _dio.post(
      '/gaushalas',
      data: {
        'gaushalaName': gaushalaName.trim(),
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.data != null) {
        final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        if (responseData['data'] is Map) {
          return GaushalaModel.fromJson(Map<String, dynamic>.from(responseData['data'] as Map));
        }
      }
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: response.data?['message']?.toString() ?? 'Failed to create gaushala.',
    );
  }

  // -------------------------------------------------------------
  // SHEDS MASTER
  // -------------------------------------------------------------
  Future<List<ShedModel>> getSheds({String? gaushalaId}) async {
    final Map<String, dynamic> queryParameters = {};
    if (gaushalaId != null && gaushalaId.trim().isNotEmpty && gaushalaId != 'all') {
      queryParameters['gaushalaId'] = gaushalaId.trim();
    }

    final response = await _dio.get(
      '/sheds',
      queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
    );
    if (response.statusCode == 200 && response.data != null) {
      if (response.data is List) {
        final List list = response.data as List;
        return list
            .map((item) => ShedModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }

      final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);

      if (responseData['data'] is List) {
        final List list = responseData['data'] as List;
        return list
            .map((item) => ShedModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      } else if (responseData['data'] is Map && (responseData['data'] as Map)['sheds'] is List) {
        final List list = (responseData['data'] as Map)['sheds'] as List;
        return list
            .map((item) => ShedModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      } else if (responseData['sheds'] is List) {
        final List list = responseData['sheds'] as List;
        return list
            .map((item) => ShedModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
    }
    return [];
  }

  Future<ShedModel> createShed({
    required String shedName,
    required String shedNumber,
    String? gaushalaId,
  }) async {
    final Map<String, dynamic> data = {
      'shedName': shedName.trim(),
      'shedNumber': shedNumber.trim().toUpperCase(),
    };
    if (gaushalaId != null && gaushalaId.trim().isNotEmpty) {
      data['gaushalaId'] = gaushalaId.trim();
      data['gaushala_id'] = gaushalaId.trim();
      data['gaushala'] = gaushalaId.trim();
    }

    final response = await _dio.post(
      '/sheds',
      data: data,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.data != null) {
        final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        if (responseData['data'] is Map) {
          return ShedModel.fromJson(Map<String, dynamic>.from(responseData['data'] as Map));
        }
      }
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: response.data?['message']?.toString() ?? 'Failed to create shed.',
    );
  }

  Future<ShedModel> updateShed(
    String id, {
    required String shedName,
    required String shedNumber,
    String? gaushalaId,
  }) async {
    final Map<String, dynamic> data = {
      'shedName': shedName.trim(),
      'shedNumber': shedNumber.trim().toUpperCase(),
    };
    if (gaushalaId != null && gaushalaId.trim().isNotEmpty) {
      data['gaushalaId'] = gaushalaId.trim();
      data['gaushala_id'] = gaushalaId.trim();
      data['gaushala'] = gaushalaId.trim();
    }

    final response = await _dio.put(
      '/sheds/$id',
      data: data,
    );

    if (response.statusCode == 200) {
      if (response.data != null) {
        final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        if (responseData['data'] is Map) {
          return ShedModel.fromJson(Map<String, dynamic>.from(responseData['data'] as Map));
        }
      }
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: response.data?['message']?.toString() ?? 'Failed to update shed.',
    );
  }

  Future<bool> deleteShed(String id) async {
    final response = await _dio.delete('/sheds/$id');
    return response.statusCode == 200 || response.statusCode == 204;
  }

  // -------------------------------------------------------------
  // BREED TYPES MASTER
  // -------------------------------------------------------------
  Future<List<BreedModel>> getBreedTypes() async {
    final response = await _dio.get('/breed-types');
    if (response.statusCode == 200 && response.data != null) {
      if (response.data is List) {
        final List list = response.data as List;
        return list
            .map((item) => BreedModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }

      final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);

      if (responseData['data'] is List) {
        final List list = responseData['data'] as List;
        return list
            .map((item) => BreedModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
    }
    return [];
  }

  Future<BreedModel> createBreedType(String breedName) async {
    final response = await _dio.post(
      '/breed-types',
      data: {
        'breedName': breedName.trim(),
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.data != null) {
        final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        if (responseData['data'] is Map) {
          return BreedModel.fromJson(Map<String, dynamic>.from(responseData['data'] as Map));
        }
      }
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: response.data?['message']?.toString() ?? 'Failed to create breed.',
    );
  }

  Future<BreedModel> updateBreedType(String id, String breedName) async {
    final response = await _dio.put(
      '/breed-types/$id',
      data: {
        'breedName': breedName.trim(),
      },
    );

    if (response.statusCode == 200) {
      if (response.data != null) {
        final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        if (responseData['data'] is Map) {
          return BreedModel.fromJson(Map<String, dynamic>.from(responseData['data'] as Map));
        }
      }
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: response.data?['message']?.toString() ?? 'Failed to update breed.',
    );
  }

  Future<bool> deleteBreedType(String id) async {
    final response = await _dio.delete('/breed-types/$id');
    return response.statusCode == 200 || response.statusCode == 204;
  }

  // -------------------------------------------------------------
  // TYPES MASTER
  // -------------------------------------------------------------
  Future<List<TypeModel>> getTypes() async {
    final response = await _dio.get('/types');
    if (response.statusCode == 200 && response.data != null) {
      if (response.data is List) {
        final List list = response.data as List;
        return list
            .map((item) => TypeModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }

      final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);

      if (responseData['data'] is List) {
        final List list = responseData['data'] as List;
        return list
            .map((item) => TypeModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
    }
    return [];
  }

  Future<TypeModel> createType(String typeName) async {
    final response = await _dio.post(
      '/types',
      data: {
        'typeName': typeName.trim(),
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.data != null) {
        final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        if (responseData['data'] is Map) {
          return TypeModel.fromJson(Map<String, dynamic>.from(responseData['data'] as Map));
        } else if (responseData['_id'] != null || responseData['typeName'] != null) {
          return TypeModel.fromJson(responseData);
        }
      }
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: response.data?['message']?.toString() ?? 'Failed to create type.',
    );
  }

  Future<TypeModel> updateType(String id, String typeName) async {
    final response = await _dio.put(
      '/types/$id',
      data: {
        'typeName': typeName.trim(),
      },
    );

    if (response.statusCode == 200) {
      if (response.data != null) {
        final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        if (responseData['data'] is Map) {
          return TypeModel.fromJson(Map<String, dynamic>.from(responseData['data'] as Map));
        } else if (responseData['_id'] != null || responseData['typeName'] != null) {
          return TypeModel.fromJson(responseData);
        }
      }
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: response.data?['message']?.toString() ?? 'Failed to update type.',
    );
  }

  Future<bool> deleteType(String id) async {
    final response = await _dio.delete('/types/$id');
    return response.statusCode == 200 || response.statusCode == 204;
  }

  // -------------------------------------------------------------
  // COWS
  // -------------------------------------------------------------
  Future<CowModel> addCow(AddCowRequestModel request) async {
    final response = await _dio.post(
      '/cows',
      data: request.toJson(),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.data != null) {
        final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        if (responseData['data'] is Map) {
          return CowModel.fromJson(Map<String, dynamic>.from(responseData['data'] as Map));
        }
      }
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: response.data?['message']?.toString() ?? 'Failed to add cow.',
    );
  }

  /// Fetches cows for a specific gaushala with optional gender filtering.
  /// GET /cows?gaushalaId=:id&gender=:gender
  Future<CowListResponse> getCows({
    String? gaushalaId,
    String? gender,
  }) async {
    final cleanGaushalaId = gaushalaId?.trim();
    if (cleanGaushalaId == null || cleanGaushalaId.isEmpty) {
      return const CowListResponse();
    }

    final Map<String, dynamic> queryParameters = {
      'gaushalaId': cleanGaushalaId,
    };
    if (gender != null && gender.trim().isNotEmpty && gender.trim().toLowerCase() != 'all') {
      queryParameters['gender'] = gender.trim().toLowerCase();
    }

    final response = await _dio.get(
      '/cows',
      queryParameters: queryParameters,
    );

    if (response.statusCode == 200 && response.data != null) {
      final responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);

      if (responseData['data'] is Map) {
        return CowListResponse.fromJson(
          Map<String, dynamic>.from(responseData['data'] as Map),
        );
      } else if (responseData['data'] is List) {
        final list = (responseData['data'] as List)
            .map((item) => CowModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
        return CowListResponse(
          total: list.length,
          femaleCount: list.where((c) => c.isFemale).length,
          maleCount: list.where((c) => !c.isFemale).length,
          counts: CowCounts(
            total: list.length,
            female: list.where((c) => c.isFemale).length,
            male: list.where((c) => !c.isFemale).length,
            cow: list.where((c) => c.isFemale).length,
            bull: list.where((c) => !c.isFemale).length,
          ),
          female: list.where((c) => c.isFemale).toList(),
          male: list.where((c) => !c.isFemale).toList(),
          allCows: list,
        );
      }
    }

    return const CowListResponse();
  }

  /// Updates a cow by ID. PUT /cows/:id (with fallback to POST /cows/:id/update)
  Future<CowModel> updateCow(String id, AddCowRequestModel request) async {
    Response response;
    try {
      response = await _dio.put(
        '/cows/$id',
        data: request.toJson(),
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        try {
          response = await _dio.post(
            '/cows/$id/update',
            data: request.toJson(),
          );
        } catch (_) {
          rethrow;
        }
      } else {
        rethrow;
      }
    }

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.data != null) {
        final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        if (responseData['data'] is Map) {
          return CowModel.fromJson(Map<String, dynamic>.from(responseData['data'] as Map));
        } else if (responseData['data'] == null && responseData['_id'] != null) {
          return CowModel.fromJson(responseData);
        }
      }
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: response.data?['message']?.toString() ?? 'Failed to update cow.',
    );
  }

  /// Deletes a cow by ID. POST /cows/:id/delete
  Future<bool> deleteCow(String id) async {
    final response = await _dio.post('/cows/$id/delete');
    if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
      if (response.data is Map && (response.data as Map).containsKey('success')) {
        return response.data['success'] == true;
      }
      return true;
    }
    return false;
  }

  /// Updates cow active status. POST /cows/:id/status
  Future<bool> updateCowStatus(String id, bool isActive) async {
    final response = await _dio.post(
      '/cows/$id/status',
      data: {'isActive': isActive},
    );
    if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
      if (response.data is Map && (response.data as Map).containsKey('success')) {
        return response.data['success'] == true;
      }
      return true;
    }
    return false;
  }

  /// Marks a cow as died. POST /cows/:id/died
  Future<bool> markCowDied(String id, String sendDiedDate) async {
    final response = await _dio.post(
      '/cows/$id/died',
      data: {'send_died_date': sendDiedDate},
    );
    if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
      if (response.data is Map && (response.data as Map).containsKey('success')) {
        return response.data['success'] == true;
      }
      return true;
    }
    return false;
  }

  /// Downloads the Excel import template for cattle.
  /// GET /cows/import-template
  Future<List<int>> downloadImportTemplate({
    ProgressCallback? onReceiveProgress,
  }) async {
    final response = await _dio.get<List<int>>(
      '/cows/import-template',
      options: Options(
        responseType: ResponseType.bytes,
      ),
      onReceiveProgress: onReceiveProgress,
    );

    if (response.statusCode == 200 && response.data != null) {
      return response.data!;
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: 'Failed to download cattle import template.',
    );
  }

  /// Uploads filled Excel spreadsheet to batch-import cows.
  /// POST /cows/upload-excel
  /// Returns a Map containing the response data (success, message, imported records count, etc.)
  Future<Map<String, dynamic>> uploadCowsExcel({
    required List<int> fileBytes,
    required String fileName,
    ProgressCallback? onSendProgress,
  }) async {
    final formData = FormData.fromMap({
      'file': MultipartFile.fromBytes(
        fileBytes,
        filename: fileName,
      ),
    });

    final response = await _dio.post(
      '/cows/upload-excel',
      data: formData,
      options: Options(
        contentType: 'multipart/form-data',
      ),
      onSendProgress: onSendProgress,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.data is Map) {
        return Map<String, dynamic>.from(response.data as Map);
      }
      return {'success': true, 'message': 'Cattle data imported successfully'};
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: response.data?['message']?.toString() ?? 'Failed to upload cattle Excel sheet.',
    );
  }

  // -------------------------------------------------------------
  // USERS MANAGEMENT
  // -------------------------------------------------------------
  /// Fetches all users from GET /users with optional gaushalaId and roleId filters.
  Future<List<UserModel>> getUsers({String? gaushalaId, String? roleId}) async {
    final Map<String, dynamic> queryParameters = {};
    if (gaushalaId != null && gaushalaId.trim().isNotEmpty && gaushalaId != 'all') {
      queryParameters['gaushalaId'] = gaushalaId.trim();
    }
    if (roleId != null && roleId.trim().isNotEmpty && roleId != 'all') {
      queryParameters['roleId'] = roleId.trim();
    }

    final response = await _dio.get(
      '/users',
      queryParameters: queryParameters.isNotEmpty ? queryParameters : null,
    );

    if (response.statusCode == 200 && response.data != null) {
      final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);

      if (responseData['data'] is List) {
        final List list = responseData['data'] as List;
        return list
            .map((item) => UserModel.fromJson(Map<String, dynamic>.from(item as Map)))
            .toList();
      }
    }
    return [];
  }

  /// Fetches a single user by ID. GET /users/:id
  Future<UserModel> getUserById(String id) async {
    final response = await _dio.get('/users/$id');
    if (response.statusCode == 200 && response.data != null) {
      final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
          ? response.data as Map<String, dynamic>
          : Map<String, dynamic>.from(response.data as Map);

      if (responseData['data'] is Map) {
        return UserModel.fromJson(Map<String, dynamic>.from(responseData['data'] as Map));
      }
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: response.data?['message']?.toString() ?? 'Failed to fetch user.',
    );
  }

  /// Creates a new user. POST /users
  Future<UserModel> createUser({
    required String name,
    required String gaushalaId,
    required String roleId,
    required String emailId,
    required String username,
    required String password,
    bool isActive = true,
    String? fcmToken,
  }) async {
    final Map<String, dynamic> data = {
      'name': name.trim(),
      'gaushalaId': gaushalaId.trim(),
      'roleId': roleId.trim(),
      'emailId': emailId.trim(),
      'username': username.trim(),
      'password': password,
      'isActive': isActive,
      'fcmToken': fcmToken,
    };

    final response = await _dio.post(
      '/users',
      data: data,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.data != null) {
        final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        if (responseData['data'] is Map) {
          return UserModel.fromJson(Map<String, dynamic>.from(responseData['data'] as Map));
        }
      }
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: response.data?['message']?.toString() ?? 'Failed to create user.',
    );
  }

  /// Updates an existing user. POST /users/:id/update
  Future<UserModel> updateUser(
    String id, {
    String? name,
    String? gaushalaId,
    String? roleId,
    String? emailId,
    String? username,
    String? password,
    bool? isActive,
  }) async {
    final Map<String, dynamic> data = {};
    if (name != null && name.trim().isNotEmpty) data['name'] = name.trim();
    if (gaushalaId != null && gaushalaId.trim().isNotEmpty) data['gaushalaId'] = gaushalaId.trim();
    if (roleId != null && roleId.trim().isNotEmpty) data['roleId'] = roleId.trim();
    if (emailId != null && emailId.trim().isNotEmpty) data['emailId'] = emailId.trim();
    if (username != null && username.trim().isNotEmpty) data['username'] = username.trim();
    if (password != null && password.trim().isNotEmpty) data['password'] = password.trim();
    if (isActive != null) data['isActive'] = isActive;

    final response = await _dio.post(
      '/users/$id/update',
      data: data,
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      if (response.data != null) {
        final Map<String, dynamic> responseData = response.data is Map<String, dynamic>
            ? response.data as Map<String, dynamic>
            : Map<String, dynamic>.from(response.data as Map);

        if (responseData['data'] is Map) {
          return UserModel.fromJson(Map<String, dynamic>.from(responseData['data'] as Map));
        }
      }
    }

    throw DioException(
      requestOptions: response.requestOptions,
      response: response,
      message: response.data?['message']?.toString() ?? 'Failed to update user.',
    );
  }

  /// Deletes a user by ID. POST /users/:id/delete
  Future<bool> deleteUser(String id) async {
    final response = await _dio.post('/users/$id/delete');
    if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
      if (response.data is Map && (response.data as Map).containsKey('success')) {
        return response.data['success'] == true;
      }
      return true;
    }
    return false;
  }

  /// Updates user active status. POST /users/:id/status
  Future<bool> updateUserStatus(String id, bool isActive) async {
    final response = await _dio.post(
      '/users/$id/status',
      data: {'isActive': isActive},
    );
    if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
      if (response.data is Map && (response.data as Map).containsKey('success')) {
        return response.data['success'] == true;
      }
      return true;
    }
    return false;
  }

  /// Changes user password. POST /auth/change-password
  Future<bool> changePassword({
    required String userId,
    String? oldPassword,
    required String newPassword,
  }) async {
    final Map<String, dynamic> data = {
      'userId': userId,
      'newPassword': newPassword.trim(),
    };
    if (oldPassword != null && oldPassword.trim().isNotEmpty) {
      data['oldPassword'] = oldPassword.trim();
    }

    try {
      final response = await _dio.post(
        '/auth/change-password',
        data: data,
      );
      if (response.statusCode == 200 || response.statusCode == 201 || response.statusCode == 204) {
        if (response.data is Map && (response.data as Map).containsKey('success')) {
          return response.data['success'] == true;
        }
        return true;
      }
      return false;
    } on DioException {
      // If /auth/change-password requires oldPassword, fallback to /users/:id/update for admin
      if (oldPassword == null || oldPassword.trim().isEmpty) {
        try {
          final fallbackResponse = await _dio.post(
            '/users/$userId/update',
            data: {'password': newPassword.trim()},
          );
          if (fallbackResponse.statusCode == 200 || fallbackResponse.statusCode == 201) {
            return true;
          }
        } catch (_) {}
      }
      rethrow;
    }
  }
}



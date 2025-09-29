import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class CloudinaryException implements Exception {
  CloudinaryException(this.message);

  final String message;

  @override
  String toString() => message;
}

class CloudinaryUploadResult {
  const CloudinaryUploadResult({
    required this.publicId,
    required this.secureUrl,
    required this.bytes,
    this.version,
    this.width,
    this.height,
    this.format,
  });

  final String publicId;
  final String secureUrl;
  final int bytes;
  final String? version;
  final int? width;
  final int? height;
  final String? format;

  factory CloudinaryUploadResult.fromJson(Map<String, dynamic> json) {
    String readString(Map<String, dynamic> source, String key) {
      final value = source[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
      return '';
    }

    final secureUrlCandidate = readString(json, 'secure_url');
    final secureUrl = secureUrlCandidate.isNotEmpty
        ? secureUrlCandidate
        : readString(json, 'url');

    var publicId = readString(json, 'public_id');
    if (publicId.isEmpty) {
      publicId = readString(json, 'asset_id');
    }

    return CloudinaryUploadResult(
      publicId: publicId,
      secureUrl: secureUrl,
      bytes: (json['bytes'] as num?)?.toInt() ?? 0,
      version: json['version']?.toString(),
      width: (json['width'] as num?)?.toInt(),
      height: (json['height'] as num?)?.toInt(),
      format: json['format'] as String?,
    );
  }
}

class CloudinaryConfig {
  const CloudinaryConfig({
    required this.cloudName,
    required this.apiKey,
    required this.apiSecret,
    required this.uploadPreset,
  });

  final String cloudName;
  final String apiKey;
  final String apiSecret;
  final String uploadPreset;

  bool get isValid =>
      cloudName.isNotEmpty &&
      apiKey.isNotEmpty &&
      apiSecret.isNotEmpty &&
      uploadPreset.isNotEmpty;

  factory CloudinaryConfig.fromEnvironment(Map<String, String?> env) {
    String readKey(String key) => env[key]?.trim() ?? '';
    return CloudinaryConfig(
      cloudName: readKey('CLOUDINARY_CLOUD_NAME'),
      apiKey: readKey('CLOUDINARY_API_KEY'),
      apiSecret: readKey('CLOUDINARY_API_SECRET'),
      uploadPreset: readKey('CLOUDINARY_UPLOAD_PRESET'),
    );
  }
}

const _reservedUploadFields = <String>{
  'file',
  'api_key',
  'signature',
  'timestamp',
  'upload_preset',
  'public_id',
  'folder',
};

class CloudinaryService {
  CloudinaryService._();

  static final CloudinaryService instance = CloudinaryService._();

  CloudinaryConfig? _config;
  bool _initialized = false;

  CloudinaryConfig? get config => _config;

  bool get isConfigured => _config?.isValid ?? false;

  @visibleForTesting
  void configureForTesting(CloudinaryConfig? config) {
    _config = config;
    _initialized = config != null;
  }

  Future<bool> ensureInitialized({bool force = false}) async {
    if (_initialized && !force) {
      return isConfigured;
    }

    try {
      _config = CloudinaryConfig.fromEnvironment(
        Map<String, String?>.from(dotenv.env),
      );
    } on Object catch (error) {
      debugPrint('CloudinaryService: failed to read environment: $error');
      _config = null;
    }

    _initialized = true;

    if (!isConfigured) {
      debugPrint(
        'CloudinaryService: configuration is incomplete, uploads disabled.',
      );
      return false;
    }

    return true;
  }

  Future<CloudinaryUploadResult> uploadBytes(
    Uint8List data, {
    String? fileName,
    String resourceType = 'image',
    String? folder,
    Map<String, String> metadata = const <String, String>{},
  }) async {
    if (data.isEmpty) {
      throw CloudinaryException('Cannot upload empty data to Cloudinary.');
    }

    final ready = await ensureInitialized();
    if (!ready) {
      throw CloudinaryException('Cloudinary is not configured.');
    }
    final resolvedConfig = _config!;

    final timestamp = (DateTime.now().millisecondsSinceEpoch ~/ 1000).toString();
    final sanitizedResourceType = resourceType.trim().isEmpty
        ? 'image'
        : resourceType.trim().toLowerCase();

    final sanitizedPublicId = _sanitizePublicId(fileName);

    final payloadFields = _buildPayload(
      config: resolvedConfig,
      timestamp: timestamp,
      folder: folder,
      publicId: sanitizedPublicId,
      metadata: metadata,
    );

    final signature = _generateSignature(
      payloadFields,
      resolvedConfig.apiSecret,
    );

    final uri = Uri.https(
      'api.cloudinary.com',
      '/v1_1/${resolvedConfig.cloudName}/$sanitizedResourceType/upload',
    );

    final request = http.MultipartRequest('POST', uri)
      ..fields.addAll(payloadFields)
      ..fields['api_key'] = resolvedConfig.apiKey
      ..fields['signature'] = signature
      ..files.add(
        http.MultipartFile.fromBytes(
          'file',
          data,
          filename: fileName ?? 'upload',
        ),
      );

    http.StreamedResponse streamedResponse;
    try {
      streamedResponse = await request.send();
    } on Exception catch (error) {
      throw CloudinaryException('Failed to send upload request: $error');
    }

    final response = await http.Response.fromStream(streamedResponse);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final errorMessage = _extractErrorMessage(response.body);
      throw CloudinaryException(
        'Upload failed (${response.statusCode}): $errorMessage',
      );
    }

    Map<String, dynamic> json;
    try {
      json = jsonDecode(response.body) as Map<String, dynamic>;
    } on Object catch (error) {
      throw CloudinaryException('Upload succeeded but decoding failed: $error');
    }

    final result = CloudinaryUploadResult.fromJson(json);
    if (result.secureUrl.isEmpty) {
      throw CloudinaryException(
        'Upload succeeded but secure_url was not returned by Cloudinary.',
      );
    }

    return result;
  }

  Map<String, String> _buildPayload({
    required CloudinaryConfig config,
    required String timestamp,
    String? folder,
    String? publicId,
    Map<String, String> metadata = const <String, String>{},
  }) {
    final fields = <String, String>{
      'timestamp': timestamp,
      if (config.uploadPreset.isNotEmpty) 'upload_preset': config.uploadPreset,
      if (publicId != null && publicId.isNotEmpty) 'public_id': publicId,
    };

    if (folder != null && folder.trim().isNotEmpty) {
      var sanitizedFolder = folder.trim();
      while (sanitizedFolder.startsWith('/')) {
        sanitizedFolder = sanitizedFolder.substring(1);
      }
      while (sanitizedFolder.endsWith('/')) {
        sanitizedFolder = sanitizedFolder.substring(0, sanitizedFolder.length - 1);
      }
      if (sanitizedFolder.isNotEmpty) {
        fields['folder'] = sanitizedFolder;
      }
    }

    for (final entry in metadata.entries) {
      final key = entry.key.trim();
      final value = entry.value.trim();
      if (key.isEmpty || value.isEmpty) {
        continue;
      }
      final normalizedKey = key.toLowerCase();
      if (_reservedUploadFields.contains(normalizedKey)) {
        continue;
      }
      fields[normalizedKey] = value;
    }

    return fields;
  }

  String _generateSignature(Map<String, String> params, String apiSecret) {
    if (apiSecret.trim().isEmpty) {
      throw CloudinaryException('Cloudinary API secret is missing.');
    }

    final entries = params.entries
        .where((entry) => entry.value.trim().isNotEmpty)
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    final buffer = StringBuffer();
    for (var i = 0; i < entries.length; i++) {
      final entry = entries[i];
      if (buffer.isNotEmpty) buffer.write('&');
      buffer.write('${entry.key}=${entry.value}');
    }

    final toSign = '${buffer.toString()}$apiSecret';
    final digest = sha1.convert(utf8.encode(toSign));
    return digest.toString();
  }

  String? _sanitizePublicId(String? fileName) {
    if (fileName == null || fileName.trim().isEmpty) {
      return null;
    }

    final trimmed = fileName.trim();
    final dotIndex = trimmed.lastIndexOf('.');
    var base = dotIndex > 0 ? trimmed.substring(0, dotIndex) : trimmed;
    base = base.toLowerCase().replaceAll(RegExp(r'[^a-z0-9_-]+'), '_');
    base = base.replaceAll(RegExp(r'_+'), '_');
    base = base.replaceAll(RegExp(r'^_|_$'), '');
    return base.isEmpty ? null : base;
  }

  String _extractErrorMessage(String body) {
    try {
      final dynamic decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final error = decoded['error'];
        if (error is Map<String, dynamic>) {
          final message = error['message'];
          if (message is String && message.trim().isNotEmpty) {
            return message.trim();
          }
        }
        final message = decoded['message'];
        if (message is String && message.trim().isNotEmpty) {
          return message.trim();
        }
      }
    } catch (_) {
      // Ignore parsing errors and fall back to body text.
    }

    final sanitized = body.trim();
    if (sanitized.isEmpty) {
      return 'Unknown error';
    }
    return sanitized.length > 200
        ? '${sanitized.substring(0, 200)}...'
        : sanitized;
  }
}

final CloudinaryService cloudinaryService = CloudinaryService.instance;

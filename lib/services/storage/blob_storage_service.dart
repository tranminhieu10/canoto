import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart';
import 'package:canoto/core/constants/azure_config.dart';
import 'package:path/path.dart' as path;

/// Azure Blob Storage Service
/// Handles image upload/download to Azure Blob Storage
class BlobStorageService {
  // Singleton pattern
  static BlobStorageService? _instance;
  static BlobStorageService get instance => _instance ??= BlobStorageService._();
  BlobStorageService._();

  final http.Client _client = http.Client();

  /// Upload image file to Azure Blob Storage
  Future<BlobUploadResult> uploadImage({
    required File imageFile,
    required String containerName,
    String? blobName,
    Map<String, String>? metadata,
  }) async {
    try {
      // Generate blob name if not provided
      final fileName = blobName ?? _generateBlobName(imageFile.path);
      
      // Read file bytes
      final bytes = await imageFile.readAsBytes();
      
      return uploadBytes(
        bytes: bytes,
        containerName: containerName,
        blobName: fileName,
        contentType: _getContentType(imageFile.path),
        metadata: metadata,
      );
    } catch (e) {
      debugPrint('BlobStorageService: Upload error: $e');
      return BlobUploadResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Upload bytes to Azure Blob Storage
  Future<BlobUploadResult> uploadBytes({
    required Uint8List bytes,
    required String containerName,
    required String blobName,
    String contentType = 'application/octet-stream',
    Map<String, String>? metadata,
  }) async {
    try {
      final url = _getBlobUrl(containerName, blobName);
      final headers = _getAuthHeaders(
        method: 'PUT',
        containerName: containerName,
        blobName: blobName,
        contentLength: bytes.length,
        contentType: contentType,
        metadata: metadata,
      );

      debugPrint('BlobStorageService: Uploading to $url');

      final response = await _client.put(
        Uri.parse(url),
        headers: headers,
        body: bytes,
      );

      if (response.statusCode == 201) {
        debugPrint('BlobStorageService: Upload successful');
        return BlobUploadResult(
          success: true,
          blobUrl: url,
          blobName: blobName,
          containerName: containerName,
          etag: response.headers['etag'],
        );
      } else {
        debugPrint('BlobStorageService: Upload failed: ${response.statusCode} ${response.body}');
        return BlobUploadResult(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      debugPrint('BlobStorageService: Upload error: $e');
      return BlobUploadResult(
        success: false,
        error: e.toString(),
      );
    }
  }

  /// Upload weighing ticket image
  Future<BlobUploadResult> uploadWeighingImage({
    required File imageFile,
    required String ticketNumber,
    required String imageType, // 'first_weight', 'second_weight', 'license_plate'
  }) async {
    final blobName = '${ticketNumber}_${imageType}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    
    return uploadImage(
      imageFile: imageFile,
      containerName: AzureConfig.blobContainerImages,
      blobName: blobName,
      metadata: {
        'ticketNumber': ticketNumber,
        'imageType': imageType,
        'uploadedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Upload license plate image
  Future<BlobUploadResult> uploadLicensePlateImage({
    required File imageFile,
    required String licensePlate,
  }) async {
    final sanitizedPlate = licensePlate.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_');
    final blobName = '${sanitizedPlate}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    
    return uploadImage(
      imageFile: imageFile,
      containerName: AzureConfig.blobContainerLicensePlates,
      blobName: blobName,
      metadata: {
        'licensePlate': licensePlate,
        'uploadedAt': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Download blob as bytes
  Future<Uint8List?> downloadBlob({
    required String containerName,
    required String blobName,
  }) async {
    try {
      final url = _getBlobUrl(containerName, blobName);
      final headers = _getAuthHeaders(
        method: 'GET',
        containerName: containerName,
        blobName: blobName,
      );

      debugPrint('BlobStorageService: Downloading from $url');

      final response = await _client.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return response.bodyBytes;
      } else {
        debugPrint('BlobStorageService: Download failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('BlobStorageService: Download error: $e');
      return null;
    }
  }

  /// Download blob to file
  Future<File?> downloadBlobToFile({
    required String containerName,
    required String blobName,
    required String localPath,
  }) async {
    try {
      final bytes = await downloadBlob(
        containerName: containerName,
        blobName: blobName,
      );

      if (bytes == null) return null;

      final file = File(localPath);
      await file.writeAsBytes(bytes);
      return file;
    } catch (e) {
      debugPrint('BlobStorageService: Download to file error: $e');
      return null;
    }
  }

  /// Delete blob
  Future<bool> deleteBlob({
    required String containerName,
    required String blobName,
  }) async {
    try {
      final url = _getBlobUrl(containerName, blobName);
      final headers = _getAuthHeaders(
        method: 'DELETE',
        containerName: containerName,
        blobName: blobName,
      );

      debugPrint('BlobStorageService: Deleting $url');

      final response = await _client.delete(
        Uri.parse(url),
        headers: headers,
      );

      return response.statusCode == 202;
    } catch (e) {
      debugPrint('BlobStorageService: Delete error: $e');
      return false;
    }
  }

  /// List blobs in container
  Future<List<BlobInfo>> listBlobs({
    required String containerName,
    String? prefix,
    int? maxResults,
  }) async {
    try {
      var url = '${AzureConfig.blobBaseUrl}/$containerName?restype=container&comp=list';
      if (prefix != null) url += '&prefix=$prefix';
      if (maxResults != null) url += '&maxresults=$maxResults';

      final headers = _getAuthHeaders(
        method: 'GET',
        containerName: containerName,
        queryString: 'restype=container&comp=list',
      );

      final response = await _client.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return _parseBlobList(response.body);
      } else {
        debugPrint('BlobStorageService: List failed: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      debugPrint('BlobStorageService: List error: $e');
      return [];
    }
  }

  /// Get blob URL
  String _getBlobUrl(String containerName, String blobName) {
    return '${AzureConfig.blobBaseUrl}/$containerName/$blobName';
  }

  /// Generate unique blob name
  String _generateBlobName(String filePath) {
    final extension = path.extension(filePath);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final uuid = _generateUuid();
    return '$uuid-$timestamp$extension';
  }

  /// Generate UUID
  String _generateUuid() {
    final random = DateTime.now().millisecondsSinceEpoch;
    return md5.convert(utf8.encode('$random')).toString().substring(0, 8);
  }

  /// Get content type from file extension
  String _getContentType(String filePath) {
    final extension = path.extension(filePath).toLowerCase();
    switch (extension) {
      case '.jpg':
      case '.jpeg':
        return 'image/jpeg';
      case '.png':
        return 'image/png';
      case '.gif':
        return 'image/gif';
      case '.bmp':
        return 'image/bmp';
      case '.webp':
        return 'image/webp';
      case '.pdf':
        return 'application/pdf';
      default:
        return 'application/octet-stream';
    }
  }

  /// Generate authentication headers for Azure Blob Storage
  Map<String, String> _getAuthHeaders({
    required String method,
    required String containerName,
    String? blobName,
    int? contentLength,
    String? contentType,
    String? queryString,
    Map<String, String>? metadata,
  }) {
    final now = HttpDate.format(DateTime.now().toUtc());
    final version = '2021-06-08';
    
    final headers = <String, String>{
      'x-ms-date': now,
      'x-ms-version': version,
      'x-ms-blob-type': 'BlockBlob',
    };

    if (contentLength != null) {
      headers['Content-Length'] = contentLength.toString();
    }

    if (contentType != null) {
      headers['Content-Type'] = contentType;
    }

    // Add metadata headers
    if (metadata != null) {
      for (final entry in metadata.entries) {
        headers['x-ms-meta-${entry.key}'] = entry.value;
      }
    }

    // Generate authorization header
    final authHeader = _generateSharedKeyAuth(
      method: method,
      containerName: containerName,
      blobName: blobName,
      headers: headers,
      queryString: queryString,
    );
    headers['Authorization'] = authHeader;

    return headers;
  }

  /// Generate Shared Key authorization
  String _generateSharedKeyAuth({
    required String method,
    required String containerName,
    String? blobName,
    required Map<String, String> headers,
    String? queryString,
  }) {
    // Build canonicalized headers
    final canonicalizedHeaders = headers.entries
        .where((e) => e.key.startsWith('x-ms-'))
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    final headersString = canonicalizedHeaders
        .map((e) => '${e.key.toLowerCase()}:${e.value}')
        .join('\n');

    // Build canonicalized resource
    var resource = '/${AzureConfig.storageAccountName}/$containerName';
    if (blobName != null) {
      resource += '/$blobName';
    }
    if (queryString != null) {
      final params = Uri.splitQueryString(queryString);
      final sortedParams = params.entries.toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      for (final param in sortedParams) {
        resource += '\n${param.key}:${param.value}';
      }
    }

    // Build string to sign
    final contentLength = headers['Content-Length'] ?? '';
    final contentType = headers['Content-Type'] ?? '';
    
    final stringToSign = [
      method,
      '', // Content-Encoding
      '', // Content-Language
      contentLength.isNotEmpty ? contentLength : '', // Content-Length
      '', // Content-MD5
      contentType, // Content-Type
      '', // Date
      '', // If-Modified-Since
      '', // If-Match
      '', // If-None-Match
      '', // If-Unmodified-Since
      '', // Range
      headersString,
      resource,
    ].join('\n');

    // Sign the string
    final key = base64.decode(AzureConfig.storageAccountKey);
    final hmac = Hmac(sha256, key);
    final signature = base64.encode(hmac.convert(utf8.encode(stringToSign)).bytes);

    return 'SharedKey ${AzureConfig.storageAccountName}:$signature';
  }

  /// Parse blob list XML response
  List<BlobInfo> _parseBlobList(String xml) {
    final blobs = <BlobInfo>[];
    
    // Simple XML parsing (for production, use xml package)
    final blobRegex = RegExp(r'<Blob>.*?</Blob>', dotAll: true);
    final matches = blobRegex.allMatches(xml);
    
    for (final match in matches) {
      final blobXml = match.group(0) ?? '';
      
      final name = _extractXmlValue(blobXml, 'Name');
      final lastModified = _extractXmlValue(blobXml, 'Last-Modified');
      final contentLength = _extractXmlValue(blobXml, 'Content-Length');
      final contentType = _extractXmlValue(blobXml, 'Content-Type');
      
      if (name != null) {
        blobs.add(BlobInfo(
          name: name,
          lastModified: lastModified != null 
              ? HttpDate.parse(lastModified) 
              : null,
          contentLength: int.tryParse(contentLength ?? ''),
          contentType: contentType,
        ));
      }
    }
    
    return blobs;
  }

  /// Extract value from XML element
  String? _extractXmlValue(String xml, String tagName) {
    final regex = RegExp('<$tagName>(.*?)</$tagName>');
    final match = regex.firstMatch(xml);
    return match?.group(1);
  }

  /// Dispose resources
  void dispose() {
    _client.close();
  }
}

/// Blob upload result
class BlobUploadResult {
  final bool success;
  final String? blobUrl;
  final String? blobName;
  final String? containerName;
  final String? etag;
  final String? error;

  BlobUploadResult({
    required this.success,
    this.blobUrl,
    this.blobName,
    this.containerName,
    this.etag,
    this.error,
  });

  @override
  String toString() {
    if (success) {
      return 'BlobUploadResult(success: true, url: $blobUrl)';
    } else {
      return 'BlobUploadResult(success: false, error: $error)';
    }
  }
}

/// Blob information
class BlobInfo {
  final String name;
  final DateTime? lastModified;
  final int? contentLength;
  final String? contentType;

  BlobInfo({
    required this.name,
    this.lastModified,
    this.contentLength,
    this.contentType,
  });

  String get url => AzureConfig.getImageUrl(
    AzureConfig.blobContainerImages, 
    name,
  );

  @override
  String toString() {
    return 'BlobInfo(name: $name, size: $contentLength, type: $contentType)';
  }
}

import 'package:extension_google_sign_in_as_googleapis_auth/extension_google_sign_in_as_googleapis_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:googleapis/drive/v3.dart' as drive;
import 'package:googleapis_auth/googleapis_auth.dart';
import 'package:logger/logger.dart';

class GoogleDriveService {
  // Singleton pattern.
  factory GoogleDriveService() {
    return _instance;
  }

  GoogleDriveService._internal();
  static final GoogleDriveService _instance = GoogleDriveService._internal();

  final Logger _logger = Logger();

  // Scopes are passed during initialization or authentication.
  static const List<String> _scopes = <String>[
    drive.DriveApi.driveAppdataScope,
  ];

  // Authenticate user and return Drive API client.
  Future<drive.DriveApi?> _getDriveApi() async {
    try {
      // Initialize GoogleSignIn instance with required scopes.
      await GoogleSignIn.instance.initialize();

      // Request authorization for the scopes.
      final GoogleSignInClientAuthorization auth = await GoogleSignIn
          .instance
          .authorizationClient
          .authorizeScopes(_scopes);

      // Use extension method 'authClient' on GoogleSignInClientAuthorization.
      final AuthClient httpClient = auth.authClient(scopes: _scopes);

      return drive.DriveApi(httpClient);
    } on Exception catch (e) {
      // Log internal error for debugging.
      _logger.e('GoogleDriveService: Authentication failed: $e');
      return null;
    }
  }

  // Upload backup ZIP to hidden appData folder.
  Future<bool> uploadBackup(
    List<int> zipBytes,
    String fileName, {
    void Function(double)? onProgress,
  }) async {
    try {
      final drive.DriveApi? driveApi = await _getDriveApi();
      if (driveApi == null) return false;

      // Check if backup already exists in appDataFolder.
      final drive.FileList fileList = await driveApi.files.list(
        q: "name = '$fileName' and 'appDataFolder' in parents",
        spaces: 'appDataFolder',
      );

      final drive.File driveFile = drive.File()
        ..name = fileName
        ..parents = <String>['appDataFolder'];

      // Wrap the stream to track progress if callback is provided.
      Stream<List<int>> mediaStream;
      if (onProgress != null) {
        int bytesUploaded = 0;
        mediaStream = Stream<List<int>>.value(zipBytes).map((List<int> chunk) {
          bytesUploaded += chunk.length;
          onProgress(bytesUploaded / zipBytes.length);
          return chunk;
        });
      } else {
        mediaStream = Stream<List<int>>.value(zipBytes);
      }

      final drive.Media media = drive.Media(
        mediaStream,
        zipBytes.length,
      );

      if (fileList.files != null && fileList.files!.isNotEmpty) {
        // Update existing file.
        final String existingId = fileList.files!.first.id!;
        await driveApi.files.update(driveFile, existingId, uploadMedia: media);
        _logger.d('GoogleDriveService: Existing backup updated.');
      } else {
        // Create new file.
        await driveApi.files.create(driveFile, uploadMedia: media);
        _logger.d('GoogleDriveService: New backup created.');
      }

      return true;
    } on Exception catch (e) {
      _logger.e('GoogleDriveService: Upload failed: $e');
      return false;
    }
  }

  // Download latest backup from appData folder.
  Future<List<int>?> downloadBackup(
    String fileName, {
    void Function(double)? onProgress,
  }) async {
    try {
      final drive.DriveApi? driveApi = await _getDriveApi();
      if (driveApi == null) return null;

      final drive.FileList fileList = await driveApi.files.list(
        q: "name = '$fileName' and 'appDataFolder' in parents",
        spaces: 'appDataFolder',
        $fields: 'files(id, name, size)',
      );

      if (fileList.files == null || fileList.files!.isEmpty) {
        _logger.w('GoogleDriveService: No backup found on Drive.');
        return null;
      }

      final drive.File firstFile = fileList.files!.first;
      final String fileId = firstFile.id!;
      final int totalSize = int.tryParse(firstFile.size ?? '0') ?? 0;

      final drive.Media media =
          await driveApi.files.get(
                fileId,
                downloadOptions: drive.DownloadOptions.fullMedia,
              )
              as drive.Media;

      final List<int> data = <int>[];
      int bytesDownloaded = 0;

      await for (final List<int> chunk in media.stream) {
        data.addAll(chunk);
        if (onProgress != null && totalSize > 0) {
          bytesDownloaded += chunk.length;
          onProgress(bytesDownloaded / totalSize);
        }
      }

      return data;
    } on Exception catch (e) {
      _logger.e('GoogleDriveService: Download failed: $e');
      return null;
    }
  }
}

// Globalize GoogleDriveService.
final GoogleDriveService googleDriveService = GoogleDriveService();

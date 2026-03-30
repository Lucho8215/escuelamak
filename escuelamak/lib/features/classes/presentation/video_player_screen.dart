// ============================================================
// VIDEO PLAYER SCREEN — Reproductor de video
// ============================================================
// Usa WebView para reproducir videos embebidos (YouTube, Vimeo, etc.)
//直接从 lib/features/classes/presentation/video_player_screen.dart 加载
// ============================================================

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:escuelamak/core/theme/app_theme.dart';

class VideoPlayerScreen extends StatefulWidget {
  final String videoUrl;
  final String title;

  const VideoPlayerScreen({
    super.key,
    required this.videoUrl,
    required this.title,
  });

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  late WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String? _errorMessage;
  bool _isEmbedUrl = false;

  @override
  void initState() {
    super.initState();
    _checkUrlAndInit();
  }

  void _checkUrlAndInit() {
    final url = widget.videoUrl.toLowerCase();

    // Detectar si es URL embed de YouTube
    _isEmbedUrl = url.contains('youtube.com/embed') ||
        url.contains('player.vimeo.com') ||
        url.contains('dailymotion.com/embed');

    // Si no es URL embed, intentar convertirla
    String videoUrl = widget.videoUrl;
    if (url.contains('youtube.com/watch') && !_isEmbedUrl) {
      // Extraer ID del video de YouTube
      final uri = Uri.parse(widget.videoUrl);
      final videoId = uri.queryParameters['v'];
      if (videoId != null) {
        videoUrl = 'https://www.youtube.com/embed/$videoId';
        _isEmbedUrl = true;
      }
    } else if (url.contains('youtu.be/') && !_isEmbedUrl) {
      // YouTube short URL
      final videoId = url.split('youtu.be/')[1].split('?')[0];
      videoUrl = 'https://www.youtube.com/embed/$videoId';
      _isEmbedUrl = true;
    }

    _initWebView(videoUrl);
  }

  void _initWebView(String url) {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            setState(() {
              _isLoading = true;
            });
          },
          onPageFinished: (String url) {
            setState(() {
              _isLoading = false;
            });
          },
          onWebResourceError: (WebResourceError error) {
            setState(() {
              _isLoading = false;
              _hasError = true;
              _errorMessage = 'Error al cargar el video';
            });
          },
        ),
      )
      ..loadRequest(Uri.parse(url));
  }

  Future<void> _openInBrowser() async {
    final uri = Uri.parse(widget.videoUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          widget.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          // Botón para abrir en navegador
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            onPressed: _openInBrowser,
            tooltip: 'Abrir en navegador',
          ),
        ],
      ),
      body: _hasError
          ? _buildError()
          : Column(
              children: [
                // Video embebido
                Expanded(
                  child: _isEmbedUrl
                      ? WebViewWidget(controller: _controller)
                      : _buildDirectVideo(),
                ),
                // Indicador de carga
                if (_isLoading)
                  const LinearProgressIndicator(
                    color: Colors.red,
                    backgroundColor: Colors.grey,
                  ),
              ],
            ),
    );
  }

  Widget _buildDirectVideo() {
    // Si no es embed, intentar reproducir directamente
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(
          Icons.play_circle_outline,
          color: Colors.white,
          size: 64,
        ),
        const SizedBox(height: 16),
        const Text(
          'Video no embebido',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: _openInBrowser,
          icon: const Icon(Icons.open_in_new),
          label: const Text('Abrir en app de video'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 64,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Error al cargar el video',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _isLoading = true;
                });
                _checkUrlAndInit();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.studentColor,
                foregroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _openInBrowser,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Abrir en navegador'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Volver'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

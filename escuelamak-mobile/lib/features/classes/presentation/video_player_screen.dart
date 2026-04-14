// lib/features/classes/presentation/video_player_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';
import 'package:url_launcher/url_launcher.dart';

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
  late final VideoPlayerController _controller;
  late final Future<void> _initializeVideo;
  String? _errorMessage;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializeVideoPlayer();
  }

  void _initializeVideoPlayer() {
    _errorMessage = null;
    _hasError = false;

    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.videoUrl));
    _initializeVideo = _controller.initialize().catchError((error) {
      setState(() {
        _hasError = true;
        _errorMessage = 'No se pudo cargar el video: ${error.toString()}';
      });
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Convierte URL de YouTube a formato embed para WebView
  String _toEmbedUrl(String url) {
    final u = url.trim().toLowerCase();

    if (u.contains('youtube.com/embed') || u.contains('player.vimeo.com')) {
      return url.trim();
    }

    if (u.contains('youtube.com/watch')) {
      final uri = Uri.parse(url);
      final id = uri.queryParameters['v'];
      if (id != null && id.isNotEmpty)
        return 'https://www.youtube.com/embed/$id';
    }

    if (u.contains('youtu.be/')) {
      final parts = url.split('youtu.be/');
      if (parts.length > 1 && parts[1].isNotEmpty) {
        final id = parts[1].split('?')[0];
        if (id.isNotEmpty) return 'https://www.youtube.com/embed/$id';
      }
    }

    return url.trim();
  }

  bool _isYouTubeUrl(String url) {
    final u = url.toLowerCase();
    return u.contains('youtube.com') || u.contains('youtu.be');
  }

  Future<void> _openInBrowser() async {
    final url = widget.videoUrl;
    Uri uri;

    // Si es YouTube, abrir la URL de YouTube directamente
    if (_isYouTubeUrl(url)) {
      if (url.contains('youtube.com/embed')) {
        // Convertir de embed a watch
        final id = url.split('embed/')[1].split('?')[0];
        uri = Uri.parse('https://www.youtube.com/watch?v=$id');
      } else {
        uri = Uri.parse(url);
      }
    } else {
      uri = Uri.parse(url);
    }

    try {
      final launched =
          await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir el navegador')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.open_in_browser),
            tooltip: 'Abrir en navegador',
            onPressed: _openInBrowser,
          ),
        ],
      ),
      body: _hasError
          ? _buildErrorWidget()
          : FutureBuilder(
              future: _initializeVideo,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return _buildErrorWidget(
                    message: snapshot.error?.toString() ?? 'Error desconocido',
                  );
                }

                return _buildVideoPlayer();
              },
            ),
    );
  }

  Widget _buildVideoPlayer() {
    return Column(
      children: [
        AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              VideoPlayer(_controller),
              // Indicador de play/pause
              ValueListenableBuilder(
                valueListenable: _controller,
                builder: (context, value, child) {
                  if (value.isPlaying) return const SizedBox.shrink();
                  return Container(
                    color: Colors.black26,
                    child: const Center(
                      child: Icon(
                        Icons.play_circle_outline,
                        size: 64,
                        color: Colors.white,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        // Controles
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Barra de progreso
              VideoProgressIndicator(
                _controller,
                allowScrubbing: true,
                colors: VideoProgressColors(
                  playedColor: Theme.of(context).colorScheme.primary,
                  bufferedColor:
                      Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  backgroundColor: Colors.grey.shade300,
                ),
              ),
              const SizedBox(height: 16),
              // Botones de control
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Retroceder 10s
                  IconButton(
                    icon: const Icon(Icons.replay_10),
                    iconSize: 36,
                    onPressed: () {
                      final position = _controller.value.position;
                      _controller
                          .seekTo(position - const Duration(seconds: 10));
                    },
                  ),
                  // Play/Pause
                  ValueListenableBuilder(
                    valueListenable: _controller,
                    builder: (context, value, child) {
                      return IconButton(
                        icon: Icon(
                          value.isPlaying
                              ? Icons.pause_circle
                              : Icons.play_circle,
                        ),
                        iconSize: 56,
                        onPressed: () {
                          if (value.isPlaying) {
                            _controller.pause();
                          } else {
                            _controller.play();
                          }
                        },
                      );
                    },
                  ),
                  // Avanzar 10s
                  IconButton(
                    icon: const Icon(Icons.forward_10),
                    iconSize: 36,
                    onPressed: () {
                      final position = _controller.value.position;
                      final duration = _controller.value.duration;
                      final newPosition =
                          position + const Duration(seconds: 10);
                      if (newPosition < duration) {
                        _controller.seekTo(newPosition);
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Tiempo actual / Duración total
              ValueListenableBuilder(
                valueListenable: _controller,
                builder: (context, value, child) {
                  return Text(
                    '${_formatDuration(value.position)} / ${_formatDuration(value.duration)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorWidget({String? message}) {
    final errorMsg = message ?? _errorMessage ?? 'No se pudo cargar el video';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              errorMsg,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 24),
            if (_isYouTubeUrl(widget.videoUrl))
              FilledButton.icon(
                onPressed: _openInBrowser,
                icon: const Icon(Icons.open_in_browser),
                label: const Text('Abrir en YouTube'),
              ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _errorMessage = null;
                });
                _initializeVideoPlayer();
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
            ),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: () =>
                  Clipboard.setData(ClipboardData(text: widget.videoUrl)),
              icon: const Icon(Icons.copy),
              label: const Text('Copiar URL'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    final hours = twoDigits(duration.inHours);
    final minutes = twoDigits(duration.inMinutes.remainder(60));
    final seconds = twoDigits(duration.inSeconds.remainder(60));
    return duration.inHours > 0
        ? '$hours:$minutes:$seconds'
        : '$minutes:$seconds';
  }
}

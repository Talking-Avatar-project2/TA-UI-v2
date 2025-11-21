import 'package:flutter/material.dart';
import 'package:livekit_client/livekit_client.dart';

class LiveKitAvatarPlayerScreen extends StatefulWidget {
  final String livekitUrl;
  final String token;

  const LiveKitAvatarPlayerScreen({
    super.key,
    required this.livekitUrl,
    required this.token,
  });

  @override
  State<LiveKitAvatarPlayerScreen> createState() =>
      _LiveKitAvatarPlayerScreenState();
}

class _LiveKitAvatarPlayerScreenState extends State<LiveKitAvatarPlayerScreen> {
  Room? _room;
  bool _connecting = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _connect();
  }

  Future<void> _connect() async {
    try {
      final room = Room();

      // Escuchar eventos del Room
      room.events.listen((event) async {
        if (event is RoomConnectedEvent) {
          try {
            await room.localParticipant?.setMicrophoneEnabled(true);
          } catch (e) {
            debugPrint("Error al activar micrófono: $e");
          }
        }
      });

      await room.connect(
        widget.livekitUrl,
        widget.token,
        roomOptions: const RoomOptions(
          adaptiveStream: true,
          dynacast: true,
        ),
      );

      room.addListener(_onRoomChanged);

      setState(() {
        _room = room;
        _connecting = false;
      });

    } catch (e) {
      setState(() {
        _error = "Error al conectar a LiveKit: $e";
        _connecting = false;
      });
    }
  }

  void _onRoomChanged() {
    if (!mounted) return;
    setState(() {});
  }

  @override
  void dispose() {
    _room?.removeListener(_onRoomChanged);
    _room?.disconnect();
    _room?.dispose();
    super.dispose();
  }

  Widget _buildVideo() {
    final room = _room;
    if (room == null) return const Text("Conectando...");

    for (final participant in room.remoteParticipants.values) {
      for (final pub in participant.videoTrackPublications) {
        final track = pub.track;
        if (track is RemoteVideoTrack) {
          return AspectRatio(
            aspectRatio: 9 / 16,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: VideoTrackRenderer(track),
            ),
          );
        }
      }
    }

    return const Text("Esperando video del avatar...");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Sesión LiveAvatar")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: _connecting
              ? const CircularProgressIndicator()
              : _error != null
              ? Text(
            _error!,
            style: const TextStyle(color: Colors.red),
          )
              : Column(
            children: [
              Expanded(child: Center(child: _buildVideo())),
              const SizedBox(height: 12),
              const Text(
                "Habla con normalidad. El avatar escucha tu voz automáticamente.",
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:readmore/readmore.dart';
import 'package:toffee_gravy/toffee_gravy.dart';

/// Stateful widget to fetch and then display video content.
class VideoApp extends StatefulWidget {
  final bool isDesktop;
  final String videoId;
  final YoutubeClient _client;
  final Cquality defaultQuality;
  final Cquality defaultAudioQuality;
  const VideoApp({
    required this.isDesktop,
    required this.videoId,
    required YoutubeClient client,
    required this.defaultQuality,
    required this.defaultAudioQuality,
    super.key,
  }) : _client = client;

  @override
  State<VideoApp> createState() => _VideoAppState();
}

class _VideoAppState extends State<VideoApp> {
  Player? player;
  WatchInfo? watchInfo;
  VideoController? controller;
  Cquality? quality;
  VideoCodecType? codec;
  AudioCodecType? audioCodec;
  Cquality? audioQuality;

  Future<void> init() async {
    await watchInfo!.initStream(widget.videoId);

    final List<Cquality> videoQualities = [];
    final List<Cquality> audioQualities = [];

    for (final i in VideoCodecType.values.reversed) {
      videoQualities.addAll(watchInfo!.getAvailableVideoFormats(i)!);
      if (videoQualities.isNotEmpty) {
        codec = i;
        break;
      }
    }

    for (final i in AudioCodecType.values.reversed) {
      audioQualities.addAll(watchInfo!.getAvailableAudioFormats(i)!);
      if (audioQualities.isNotEmpty) {
        audioCodec = i;
        break;
      }
    }

    if (videoQualities.isEmpty) {
      throw UnimplementedError();
    }

    if (audioQualities.isEmpty) {
      throw UnimplementedError();
    }

    if (videoQualities.contains(widget.defaultQuality)) {
      quality = widget.defaultQuality;
    } else {
      quality = videoQualities.lastOrNull;
    }
    if (audioQualities.contains(widget.defaultAudioQuality)) {
      audioQuality = widget.defaultAudioQuality;
    } else {
      audioQuality = audioQualities.lastOrNull;
    }

    final videoUrl = watchInfo!.getVideoUrl(codec!, quality!)!;
    final audioUrl = watchInfo!.getAudioUrl(audioCodec!, audioQuality!)!;

    player!.open(Media(videoUrl));
    player!.setAudioTrack(AudioTrack.uri(audioUrl));
  }

  @override
  void initState() {
    super.initState();
    watchInfo = WatchInfo(client: widget._client);

    player = Player(configuration: PlayerConfiguration(title: "Toffee Tube"));
    controller = VideoController(player!);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder(
      future: init(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          return Scaffold(
            appBar: AppBar(leading: widget.isDesktop ? BackButton() : null),
            body:
                widget.isDesktop
                    ? _desktopVideoPlayerLayout(
                      controller!,
                      watchInfo!,
                      context,
                      theme,
                    )
                    : _mobileVideoPlayerLayout(controller!, watchInfo!),
          );
        }
      },
    );
  }

  @override
  Future<void> dispose() async {
    super.dispose();
    await player!.dispose();
  }
}

Widget _desktopVideoPlayerLayout(
  VideoController controller,
  WatchInfo info,
  BuildContext context,
  ThemeData theme,
) {
  final screenHeight = MediaQuery.of(context).size.height;

  // Sample dynamic data
  final relatedVideos = List.generate(5, (i) => 'Related Video ${i + 1}');
  final comments = List.generate(10, (i) => 'Comment number ${i + 1}');

  bool commentsExpanded = false;

  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      /// MAIN CONTENT
      Expanded(
        flex: 3,
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  /// Video
                  GestureDetector(
                    onTap: () {
                      controller.player.playOrPause();
                    },
                    child: ClipRRect(
                      borderRadius: const BorderRadius.all(Radius.circular(12)),
                      child: Video(
                        controller: controller,
                        height: screenHeight * 0.4,
                        fit: BoxFit.fill,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  /// Controls
                  Row(
                    children: [
                      PopupMenuButton<double>(
                        onSelected: (speed) =>
                            controller.player.setRate(speed),
                        itemBuilder: (context) => [
                          for (var speed in [0.5, 1.0, 1.5, 2.0])
                            PopupMenuItem(
                              value: speed,
                              child: Text('${speed}x'),
                            )
                        ],
                        icon: const Icon(Icons.speed),
                        tooltip: "Playback speed",
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton<Cquality>(
                        onSelected: (q) {
                          // Trigger video reload here
                        },
                        itemBuilder: (context) => [
                          for (var q in info.getAvailableVideoFormats?.call(VideoCodecType.avc1) ?? [])
                            PopupMenuItem(
                              value: q,
                              child: Text(q.label),
                            )
                        ],
                        icon: const Icon(Icons.high_quality),
                        tooltip: "Video Quality",
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  /// Title
                  Text(info.videoInfo?.title ?? 'Unknown Title',
                      style: theme.textTheme.headlineSmall),
                  const SizedBox(height: 8),

                  /// Description
                  ReadMoreText(
                    '\n${info.videoInfo?.description ?? ''}\n',
                    trimMode: TrimMode.Line,
                    trimLines: 2,
                    preDataText: 'Description',
                    preDataTextStyle: theme.textTheme.bodyLarge,
                    moreStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            /// Collapsible Comments
            ExpansionTile(
              title: const Text(
                "Comments",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              children: [
                SizedBox(
                  height: 300,
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: comments.length,
                    itemBuilder: (context, index) => ListTile(
                      leading: const CircleAvatar(),
                      title: Text("User ${index + 1}"),
                      subtitle: Text(comments[index]),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),

      /// RELATED VIDEOS
      Expanded(
        flex: 1,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Related Videos",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  itemCount: relatedVideos.length,
                  itemBuilder: (context, index) => ListTile(
                    leading: const Icon(Icons.video_library),
                    title: Text(relatedVideos[index]),
                    onTap: () {
                      // Load related video
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}


Widget _mobileVideoPlayerLayout(VideoController controller, WatchInfo info) {
  return ListView();
}

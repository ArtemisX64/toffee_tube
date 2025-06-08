import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:readmore/readmore.dart';
import 'package:toffee_gravy/toffee_gravy.dart';
import 'package:url_launcher/url_launcher_string.dart';

class VideoApp extends StatefulWidget {
  final bool isDesktop;
  final String videoId;
  final YoutubeClient _client;
  final YoutubeApi _api;
  final VideoQuality defaultVideoQuality;
  final AudioQuality defaultAudioQuality;

  VideoApp({
    required this.isDesktop,
    required this.videoId,
    required YoutubeClient client,
    YoutubeApi? api,
    required this.defaultVideoQuality,
    required this.defaultAudioQuality,
    super.key,
  }) : _client = client,
       _api = api ?? AndroidVRApi();

  @override
  State<VideoApp> createState() => _VideoAppState();
}

class _VideoAppState extends State<VideoApp> {
  late final Player player;
  late final WatchInfo watchInfo;
  late final VideoController controller;
  late final Channel channel;
  late final List<String> videoUrlList;

  late final VideoQuality videoQuality;
  late final VideoCodecType videoCodec;
  late final AudioCodecType audioCodec;
  late final AudioQuality audioQuality;

  bool init = false;

  // static const double aspectRatio = 16 / 9;

  @override
  void initState() {
    super.initState();
    watchInfo = WatchInfo(client: widget._client);
    channel = Channel();
    player = Player(
      configuration: const PlayerConfiguration(title: "Toffee Tube"),
    );
    controller = VideoController(player);
  }

  Future<Null> initializePlayerAndStreams() async {
    if (!init) {
      await watchInfo.initStream(widget.videoId, api: widget._api);
      await channel.init(id: watchInfo.channelId, client: widget._client);

      final List<VideoQuality> videoQualities = [];
      final List<AudioQuality> audioQualities = [];

      for (final i in VideoCodecType.values.reversed) {
        videoQualities.addAll(watchInfo.getAvailableVideoFormats(i) ?? []);
        if (videoQualities.isNotEmpty) {
          videoCodec = i;
          break;
        }
      }

      for (final i in AudioCodecType.values.reversed) {
        audioQualities.addAll(watchInfo.getAvailableAudioFormats(i) ?? []);
        if (audioQualities.isNotEmpty) {
          audioCodec = i;
          break;
        }
      }

      if (videoQualities.isEmpty || audioQualities.isEmpty) {
        return null;
      }

      videoQuality =
          videoQualities.contains(widget.defaultVideoQuality)
              ? widget.defaultVideoQuality
              : videoQualities.last;

      audioQuality =
          audioQualities.contains(widget.defaultAudioQuality)
              ? widget.defaultAudioQuality
              : audioQualities.last;

      videoUrlList =
          videoQualities
              .map((q) => watchInfo.getVideoUrl(videoCodec, q)!)
              .toList()
              .reversed
              .toList();
    }

    final audioUrl = watchInfo.getAudioUrl(audioCodec, audioQuality)!;
    final index = getPosition(videoQuality) ?? 0;

    await player.open(Media(videoUrlList[index]));
    await player.setAudioTrack(AudioTrack.uri(audioUrl));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: initializePlayerAndStreams(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          init = true;
          return Scaffold(
            backgroundColor: Colors.black,
            appBar:
                widget.isDesktop ? AppBar(title: const Text("Watch")) : null,
            body:
                widget.isDesktop
                    ? _desktopVideoPlayerLayout()
                    : _mobileVideoPlayerLayout(),
          );
        }
      },
    );
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  Future<void> playVideoAtQuality(VideoQuality q) async {
    final index = getPosition(q) ?? 0;
    final position = player.state.position;
    await player.stop();
    await player.open(Media(videoUrlList[index]));
    await player.setAudioTrack(
      AudioTrack.uri(watchInfo.getAudioUrl(audioCodec, audioQuality)!),
    );
    await player.seek(position);
  }

  Widget _mobileVideoPlayerLayout() {
    final theme = Theme.of(context);
    final relatedVideos = watchInfo.getRecommendedVideos();

    return Column(
      children: [
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Video(controller: controller, fit: BoxFit.cover),
        ),
        Expanded(
          child: Container(
            color: Colors.black,
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                Text(
                  watchInfo.title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${watchInfo.views} views • 1 day ago",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
                ),
                
                Container(padding: EdgeInsets.all(2),height: 52, child:
                ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _iconWithText(Icons.thumb_up, "1.2K", () {}),
                    _iconWithText(Icons.share, "Share", () {}),
                    _iconWithText(Icons.download, "Download", () {}),
                    _iconWithText(Icons.save, "Save", () {}),
                  ],
                ),),
              
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(),
                  title: Text(
                    channel.title,
                    style: const TextStyle(color: Colors.white),
                  ),
                  subtitle: Text(
                    "${channel.subscribers} subscribers",
                    style: const TextStyle(color: Colors.grey),
                  ),
                  trailing: ElevatedButton(
                    onPressed: () {},
                    child: const Text("Subscribe"),
                  ),
                ),
                const Divider(color: Colors.grey),
                ReadMoreText(
                  watchInfo.description ?? "Description goes here...",
                  trimLines: 3,
                  colorClickableText: Colors.blue,
                  trimMode: TrimMode.Line,
                  trimCollapsedText: ' Show more',
                  trimExpandedText: ' Show less',
                  style: const TextStyle(color: Colors.white),
                  annotations: [
                    Annotation(
                      regExp: RegExp(r'#([a-zA-Z0-9_]+)'),
                      spanBuilder:
                          ({required String text, TextStyle? textStyle}) =>
                              TextSpan(
                                text: text,
                                style: textStyle?.copyWith(color: Colors.blue),
                              ),
                    ),
                    Annotation(
                      regExp: RegExp(
                        r'(?:(?:https?):\/\/)'
                        r'(?:[\w-]+\.)+[a-zA-Z]{2,}'
                        r'(?:\/[^\s]*)?',
                        caseSensitive: false,
                      ),
                      spanBuilder:
                          ({required String text, TextStyle? textStyle}) =>
                              TextSpan(
                                text: text,
                                style: textStyle?.copyWith(color: Colors.blue),
                                recognizer:
                                    TapGestureRecognizer()
                                      ..onTap = () {
                                        launchUrlString(text);
                                      },
                              ),
                    ),
                  ],
                ),
                const Divider(color: Colors.grey),
                const Text(
                  "Related Videos",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...relatedVideos.map(
                  (video) => ListTile(
                    contentPadding: const EdgeInsets.symmetric(vertical: 8),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: SizedBox(
                        width: 60,
                        height: 60,
                        child: Image.network(
                          video.thumbnail.getThumbnailGeneric(
                                ThumbnailQuality.medium,
                              ) ??
                              '',
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) =>
                                  Container(color: Colors.grey.shade300),
                        ),
                      ),
                    ),
                    title: Text(
                      video.title,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          video.channel.name,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        Text(
                          '${video.shortViewCount} views • ${video.published} ago',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    onTap: () {
                      player.pause();
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder:
                              (_) => VideoApp(
                                isDesktop: widget.isDesktop,
                                videoId: video.videoId,
                                client: widget._client,
                                defaultVideoQuality: widget.defaultVideoQuality,
                                defaultAudioQuality: widget.defaultAudioQuality,
                              ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _desktopVideoPlayerLayout() {
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrow = screenWidth < 1000; // or adjust threshold as needed
    final theme = Theme.of(context);
    final comments = List.generate(10, (i) => 'Comment number ${i + 1}');

    // This is the main video content with description and comments
    final videoContent = Expanded(
      flex: 3,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GestureDetector(
            onTap: () => controller.player.playOrPause(),
            child: ClipRRect(
              borderRadius: const BorderRadius.all(Radius.circular(12)),
              child: Video(
                controller: controller,
                height: screenWidth * (isNarrow ? 1.0 : 0.7) * 9 / 16,
                width: screenWidth * (isNarrow ? 1.0 : 0.7),
                fit: BoxFit.fill,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  PopupMenuButton<double>(
                    onSelected: (speed) => controller.player.setRate(speed),
                    itemBuilder:
                        (context) => [
                          for (var speed in [0.25, 0.5, 1.0, 1.5, 2.0, 4.0])
                            PopupMenuItem(
                              value: speed,
                              child: Text('${speed}x'),
                            ),
                        ],
                    icon: const Icon(Icons.speed),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<VideoQuality>(
                    onSelected: playVideoAtQuality,
                    itemBuilder:
                        (context) => [
                          for (var q
                              in watchInfo.getAvailableVideoFormats(
                                    VideoCodecType.vp9,
                                  ) ??
                                  [])
                            PopupMenuItem(
                              value: q,
                              child: Text(getVideoQualityText(q)),
                            ),
                        ],
                    icon: const Icon(Icons.high_quality),
                  ),
                ],
              ),
              Row(
                children: [
                  _iconWithText(Icons.thumb_up, "1.2K", () {}),
                  _iconWithText(Icons.thumb_down, "Dislike", () {}),
                  _iconWithText(Icons.share, "Share", () {}),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(watchInfo.title, style: theme.textTheme.headlineSmall),
          Text(
            '${watchInfo.views ?? 0} Views',
            style: theme.textTheme.bodyLarge,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: CircleAvatar(
              backgroundImage: NetworkImage(
                channel.avatar.getThumbnailXL() ??
                    channel.avatar.getThumbnailGeneric(
                      ThumbnailQuality.medium,
                    ) ??
                    '',
              ),
            ),
            title: Text(watchInfo.author),
            subtitle: Text(channel.subscribers),
            trailing: ElevatedButton(
              onPressed: () {},
              child: const Text("Subscribe"),
            ),
          ),
          const SizedBox(height: 8),
          ReadMoreText(
            '\n${watchInfo.description ?? ''}\n',
            trimLines: 2,
            trimMode: TrimMode.Line,
            moreStyle: const TextStyle(fontWeight: FontWeight.bold),
            annotations: [
              Annotation(
                regExp: RegExp(r'#([a-zA-Z0-9_]+)'),
                spanBuilder:
                    ({required String text, TextStyle? textStyle}) => TextSpan(
                      text: text,
                      style: textStyle?.copyWith(color: Colors.blue),
                    ),
              ),
              Annotation(
                regExp: RegExp(
                  r'(?:(?:https?):\/\/)' // protocol required: http or https
                  r'(?:[\w-]+\.)+[a-zA-Z]{2,}' // domain name (e.g., www.google.com)
                  r'(?:\/[^\s]*)?', // optional path/query/fragment
                  caseSensitive: false,
                ),

                spanBuilder:
                    ({required String text, TextStyle? textStyle}) => TextSpan(
                      text: text,
                      style: textStyle?.copyWith(color: Colors.blue),
                      recognizer:
                          TapGestureRecognizer()
                            ..onTap = () {
                              launchUrlString(text);
                            },
                    ),
              ),
            ],
          ),
          _buildCommentSection(comments),

          // Show related videos at bottom for narrow screen
          if (isNarrow) ...[
            const SizedBox(height: 16),
            _buildRelatedVideosList(),
          ],
        ],
      ),
    );

    // Layout logic
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        videoContent,
        if (!isNarrow)
          Expanded(
            flex: 1,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
              child: _buildRelatedVideosList(),
            ),
          ),
      ],
    );
  }

  Widget _buildRelatedVideosList() {
    final relatedVideos = watchInfo.getRecommendedVideos();
    return ListView(
      children: [
        const Text(
          "Related Videos",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 12),
        for (var video in relatedVideos)
          ListTile(
            contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                video.thumbnail.getThumbnailGeneric(ThumbnailQuality.medium) ??
                    '',
                width: 100,
                height: 56,
                fit: BoxFit.cover,
              ),
            ),
            title: Text(
              video.title,
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  video.channel.name,
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  "${video.shortViewCount} • ${video.published}",
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
            onTap: () async {
              await player.pause();
              if (context.mounted) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder:
                        (_) => VideoApp(
                          isDesktop: widget.isDesktop,
                          videoId: video.videoId,
                          client: widget._client,
                          defaultVideoQuality: widget.defaultVideoQuality,
                          defaultAudioQuality: widget.defaultAudioQuality,
                        ),
                  ),
                );
              }
            },
          ),
      ],
    );
  }

  Widget _buildCommentSection(List<String> comments) {
    return ExpansionTile(
      title: const Text(
        "Comments",
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      children: [
        SizedBox(
          height: 300,
          child: ListView.builder(
            itemCount: comments.length,
            itemBuilder:
                (context, index) => ListTile(
                  leading: const CircleAvatar(),
                  title: Text("User ${index + 1}"),
                  subtitle: Text(comments[index]),
                ),
          ),
        ),
      ],
    );
  }

  Widget _iconWithText(IconData icon, String label, onPressed) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 2),
      child: ElevatedButton.icon(
        icon: Icon(icon),
        label: Text(label),
        onPressed: onPressed,
      ),
    );
  }

  int? getPosition(VideoQuality? q) {
    return switch (q) {
      VideoQuality.sd144 => 0,
      VideoQuality.sd240 => 1,
      VideoQuality.sd360 => 2,
      VideoQuality.sd480 => 3,
      VideoQuality.hd720 => 4,
      VideoQuality.hd1080 => 5,
      VideoQuality.hd1440 => 6,
      VideoQuality.hd2160 => 7,
      _ => null,
    };
  }

  String getVideoQualityText(VideoQuality q) {
    return switch (q) {
      VideoQuality.sd144 => "144p",
      VideoQuality.sd240 => "240p",
      VideoQuality.sd360 => "360p",
      VideoQuality.sd480 => "480p",
      VideoQuality.hd720 => "720p",
      VideoQuality.hd1080 => "1080p",
      VideoQuality.hd1440 => "1440p",
      VideoQuality.hd2160 => "4K",
      VideoQuality.empty => "null",
    };
  }
}

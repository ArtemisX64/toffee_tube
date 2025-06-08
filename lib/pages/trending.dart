import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toffee_gravy/toffee_gravy.dart';
import 'package:toffee_tube/pages/video_player.dart';
import 'package:url_launcher/url_launcher_string.dart';

class TrendingPage extends StatefulWidget {
  final YoutubeClient client;
  const TrendingPage({super.key, required this.client});

  @override
  State<TrendingPage> createState() => _TrendingPageState();
}

class _TrendingPageState extends State<TrendingPage> {
  late Trending _trending;
  bool loading = true;
  bool isDesktop = false;

  @override
  void initState() {
    super.initState();
    detectPlatform();
    loadTrending();
  }

  void detectPlatform() {
    isDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;
  }

  Future<void> loadTrending() async {
    _trending = Trending(client: widget.client);
    await _trending.init();
    if (mounted) setState(() => loading = false);
  }

  void _showVideoOptions(Info videoInfo) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _buildVideoOptions(context, videoInfo),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Trending'), centerTitle: true),
      body:
          loading
              ? const Center(child: CircularProgressIndicator())
              : isDesktop
              ? ListView(
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 6,
                ),
                children: [
                  Text(
                    'Trending Videos',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(fontSize: 24),
                  ),
                  ..._trending.videos
                      .take(2)
                      .map(
                        (video) => _buildVideoCard(
                          video,
                          theme,
                          thumbnailIndex: 1,
                          isDesktop: true,
                        ),
                      ),
                  const Divider(),
                  Row(
                    spacing: 10.0,
                    children: [
                      Icon(Icons.trending_up),

                      Text(
                        'Trending Shorts',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 24,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.4,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _trending.shorts.length,
                      itemBuilder: (context, index) {
                        final shortVideo = _trending.shorts[index];
                        return _buildShortCard(shortVideo, theme);
                      },
                    ),
                  ),
                  const Divider(),
                  ..._trending.videos
                      .skip(2)
                      .map(
                        (video) => _buildVideoCard(
                          video,
                          theme,
                          thumbnailIndex: 1,
                          isDesktop: true,
                        ),
                      ),
                ],
              )
              : ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12),
                itemCount: _trending.videos.length,
                itemBuilder: (context, index) {
                  final video = _trending.videos[index];
                  return _buildVideoCard(
                    video,
                    theme,
                    thumbnailIndex: 0,
                    isDesktop: false,
                  );
                },
              ),
    );
  }

  Widget _buildVideoCard(
    Info videoInfo,
    ThemeData theme, {
    required int thumbnailIndex,
    required bool isDesktop,
  }) {
    final String thumbnail =
        videoInfo.thumbnail.getThumbnailGeneric(ThumbnailQuality.medium) ??
        'https://via.placeholder.com/180';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isDesktop ? 8 : 12),
      ),
      elevation: 2,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder:
                  (_) => VideoApp(
                    isDesktop: isDesktop,
                    videoId: videoInfo.videoId,
                    client: widget.client,
                    defaultVideoQuality: VideoQuality.sd360,
                    defaultAudioQuality: AudioQuality.medium,
                  ),
            ),
          );
        },
        borderRadius: BorderRadius.circular(isDesktop ? 8 : 12),
        child:
            isDesktop
                ? _buildDesktopVideoLayout(videoInfo, thumbnail, theme)
                : _buildMobileVideoLayout(videoInfo, thumbnail, theme),
      ),
    );
  }

  Widget _buildDesktopVideoLayout(
    Info videoInfo,
    String thumbnail,
    ThemeData theme,
  ) {
    return Container(
      padding: const EdgeInsets.all(8),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 180,
              height: 120,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Image.network(
                      thumbnail,
                      fit: BoxFit.cover,
                      errorBuilder:
                          (_, __, ___) =>
                              Container(color: Colors.grey.shade300),
                    ),
                  ),
                  Positioned(
                    bottom: 10,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withAlpha(160),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        videoInfo.length,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  videoInfo.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  '${videoInfo.channel.name} • ${videoInfo.shortViewCount} • ${videoInfo.published}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 13),
                ),
                const SizedBox(height: 12),
                Text(
                  videoInfo.descriptionSnippet ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(fontSize: 11),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More options',
            onPressed: () => _showVideoOptions(videoInfo),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileVideoLayout(
    Info videoInfo,
    String thumbnail,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: SizedBox(
            height: 220,
            width: double.infinity,
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.network(
                    thumbnail,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) => Container(color: Colors.grey.shade300),
                  ),
                ),
                Positioned(
                  bottom: 6,
                  right: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(160),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      videoInfo.length,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: NetworkImage(videoInfo.channel.avatar),
                radius: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      videoInfo.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${videoInfo.channel.name} • ${videoInfo.shortViewCount} • ${videoInfo.published}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert),
                tooltip: 'More options',
                onPressed: () => _showVideoOptions(videoInfo),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVideoOptions(BuildContext context, Info videoInfo) {
    final url = "https://www.youtube.com/watch?v=${videoInfo.videoId}";
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.copy),
            title: const Text('Copy to Clipboard'),
            onTap: () {
              Clipboard.setData(ClipboardData(text: url)).then((_) {
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Link copied successfully")),
                  );
                }
              });
            },
          ),
          ListTile(
            leading: const Icon(Icons.open_in_new),
            title: const Text('Open in browser'),
            onTap: () async {
              if (!await launchUrlString(url)) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Error opening link")),
                  );
                }
              }
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildShortCard(ShortInfo shortInfo, ThemeData theme) {
    final thumbnail = shortInfo.thumbnail.getThumbnailGeneric(
      ThumbnailQuality.shorts,
    );
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.125,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 6.0),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              //TODO: Add shorts player
              MaterialPageRoute(
                builder:
                    (_) => VideoApp(
                      isDesktop: isDesktop,
                      videoId: shortInfo.videoId,
                      client: widget.client,
                      defaultVideoQuality: VideoQuality.sd360,
                      defaultAudioQuality: AudioQuality.medium,
                    ),
              ),
            );
          },
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.network(
                    thumbnail ?? '',
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) => Container(color: Colors.grey.shade300),
                  ),
                ),
                Positioned(
                  bottom: 6,
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.1,
                    padding: EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(20),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      shortInfo.title,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                      style: const TextStyle(color: Colors.white, fontSize: 12),
                      softWrap: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

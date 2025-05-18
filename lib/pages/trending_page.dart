import 'dart:io' show Platform;
import 'package:flutter/material.dart';
import 'package:toffee_gravy/models/trending.dart';

class TrendingPage extends StatefulWidget {
  const TrendingPage({super.key});

  @override
  State<TrendingPage> createState() => _TrendingPageState();
}

class _TrendingPageState extends State<TrendingPage> {
  final extractor = TrendingExtractor();
  bool loading = true;
  bool isDesktop = false;

  @override
  void initState() {
    super.initState();
    detectPlatform();
    loadTrending();
  }

  void detectPlatform() {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      isDesktop = true;
    } else {
      isDesktop = false;
    }
  }

  Future<void> loadTrending() async {
    await extractor.init();
    setState(() => loading = false);
  }

  void _showVideoOptions(Trending video) {
    showModalBottomSheet(
      context: context,
      builder: (_) => _buildVideoOptions(context, video),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Trending'),
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : isDesktop
              ? ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: extractor.trendingList.length,
                  itemBuilder: (context, index) {
                    final video = extractor.trendingList[index];
                    return _buildVideoCard(
                      video,
                      theme,
                      thumbnailIndex: 2,
                      isDesktop: true,
                    );
                  },
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  itemCount: extractor.trendingList.length,
                  itemBuilder: (context, index) {
                    final video = extractor.trendingList[index];
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
    Trending video,
    ThemeData theme, {
    required int thumbnailIndex,
    required bool isDesktop,
  }) {
    final thumbnail = (video.thumbnails.length > thumbnailIndex)
        ? video.thumbnails[thumbnailIndex]
        : video.thumbnails.last;

    if (isDesktop) {
      // Desktop style: ListTile-like card with trailing overflow menu button
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 2,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(8),
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    width: 160,
                    height: 90,
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: Image.network(
                            thumbnail.url,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) =>
                                Container(color: Colors.grey.shade300),
                          ),
                        ),
                        Positioned(
                          bottom: 6,
                          right: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withAlpha(160),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              video.length,
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 12),
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
                        video.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(fontSize: 16),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${video.channel.name} • ${video.viewCount} • ${video.published}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(fontSize: 13),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.more_vert),
                  tooltip: 'More options',
                  onPressed: () => _showVideoOptions(video),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      // Mobile style: stacked card with large thumbnail & small overflow button on right
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: InkWell(
          onTap: () {},
          borderRadius: BorderRadius.circular(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                child: SizedBox(
                  height: 220,
                  width: double.infinity,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: Image.network(
                          thumbnail.url,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Container(color: Colors.grey.shade300),
                        ),
                      ),
                      Positioned(
                        bottom: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black.withAlpha(160),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            video.length,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(video.channel.avatar),
                      radius: 18,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            video.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium
                                ?.copyWith(fontSize: 14),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${video.channel.name} • ${video.viewCount} • ${video.published}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodySmall
                                ?.copyWith(fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.more_vert),
                      tooltip: 'More options',
                      onPressed: () => _showVideoOptions(video),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildVideoOptions(BuildContext context, Trending video) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Share'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.open_in_new),
            title: const Text('Open in browser'),
            onTap: () {
              Navigator.pop(context);
              // Implement URL launch with video.videoId here if desired
            },
          ),
        ],
      ),
    );
  }
}

import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:news_lab/config/routes/route_args.dart';
import 'package:news_lab/config/routes/routes.dart';
import 'package:news_lab/core/domain/entities/article_entity.dart';
import 'package:news_lab/core/utils/date_formatter.dart';
import 'package:news_lab/features/analytics/domain/entities/daily_views_entity.dart';
import 'package:news_lab/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:news_lab/features/auth/presentation/bloc/auth_event.dart';
import 'package:news_lab/features/bias_report/domain/entities/bias_report_entity.dart';
import 'package:news_lab/features/bias_report/presentation/widgets/bias_spectrum_widget.dart';
import 'package:news_lab/features/journalist_profile/domain/repository/journalist_profile_repository.dart';
import 'package:news_lab/features/journalist_profile/presentation/bloc/journalist_profile_bloc.dart';
import 'package:news_lab/features/journalist_profile/presentation/bloc/journalist_profile_event.dart';
import 'package:news_lab/features/journalist_profile/presentation/bloc/journalist_profile_state.dart';
import 'package:news_lab/features/journalist_profile/presentation/bloc/profile_stats_bloc.dart';
import 'package:news_lab/features/journalist_profile/presentation/bloc/profile_stats_event.dart';
import 'package:news_lab/features/journalist_profile/presentation/bloc/profile_stats_state.dart';
import 'package:news_lab/injection_container.dart';
import 'package:news_lab/shared/widgets/empty_state_widget.dart';

class JournalistProfilePage extends StatelessWidget {
  final JournalistProfileArgs args;
  final bool isTab;

  const JournalistProfilePage(
      {super.key, required this.args, this.isTab = false});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProfileStatsBloc>(
      create: (_) =>
          sl<ProfileStatsBloc>()..add(LoadProfileStats(args.authorId)),
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
          appBar: AppBar(
            title:
                const Text('Profile', style: TextStyle(color: Colors.black)),
            automaticallyImplyLeading: !isTab,
            leading: isTab
                ? null
                : GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Colors.black),
                  ),
            actions: [
              if (args.isOwner)
                IconButton(
                  tooltip: 'Sign out',
                  icon: const Icon(Icons.logout, color: Colors.black54),
                  onPressed: () {
                    context.read<AuthBloc>().add(const SignOutRequested());
                    Navigator.pushNamedAndRemoveUntil(
                      context,
                      AppRoutes.login,
                      (_) => false,
                    );
                  },
                ),
            ],
            bottom: const TabBar(
              labelColor: Colors.black,
              unselectedLabelColor: Colors.black45,
              indicatorColor: Colors.black,
              tabs: [
                Tab(text: 'My Articles'),
                Tab(text: 'Analytics'),
              ],
            ),
          ),
          body: BlocListener<JournalistProfileBloc, JournalistProfileState>(
            listener: (context, state) {
              if (state is ArticleActionError) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Colors.red.shade700,
                    content: Text(state.message),
                  ),
                );
              }
            },
            child: TabBarView(
              children: [
                _MyArticlesTab(args: args),
                _AnalyticsTab(args: args),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── My Articles tab ───────────────────────────────────────────────────────────

class _MyArticlesTab extends StatefulWidget {
  final JournalistProfileArgs args;
  const _MyArticlesTab({required this.args});

  @override
  State<_MyArticlesTab> createState() => _MyArticlesTabState();
}

class _MyArticlesTabState extends State<_MyArticlesTab> {
  final _listKey = GlobalKey<AnimatedListState>();
  List<ArticleEntity> _items = [];
  bool _initialized = false;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<JournalistProfileBloc, JournalistProfileState>(
      listener: (context, state) {
        final articles = _articlesFrom(state);
        if (articles == null) return;

        if (!_initialized) {
          setState(() {
            _items = articles.toList();
            _initialized = true;
          });
          return;
        }

        // Animate removals
        for (int i = _items.length - 1; i >= 0; i--) {
          final item = _items[i];
          if (!articles.any((a) => a.remoteId == item.remoteId)) {
            final removed = item;
            final removedIndex = i;
            _listKey.currentState?.removeItem(
              removedIndex,
              (ctx, animation) => _buildAnimatedRow(removed, animation, null, null),
              duration: const Duration(milliseconds: 300),
            );
            setState(() => _items.removeAt(removedIndex));
          }
        }

        // Sync updates (title/description changes)
        for (int i = 0; i < articles.length; i++) {
          if (i < _items.length &&
              _items[i].remoteId == articles[i].remoteId) {
            if (_items[i].title != articles[i].title ||
                _items[i].description != articles[i].description) {
              setState(() => _items[i] = articles[i]);
            }
          }
        }
      },
      builder: (context, state) {
        if (state is JournalistProfileLoading && !_initialized) {
          return const Center(child: CupertinoActivityIndicator());
        }
        if (state is JournalistProfileError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                state.message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
            ),
          );
        }

        if (!_initialized) {
          return const Center(child: CupertinoActivityIndicator());
        }

        if (_items.isEmpty) {
          return const EmptyStateWidget(
            icon: Icons.article_outlined,
            message: 'No articles published yet',
            hint: 'Articles you publish will appear here',
          );
        }

        final pendingDeleteId = state is JournalistProfileLoaded
            ? state.pendingDeleteId
            : null;
        final pendingUpdateId = state is JournalistProfileLoaded
            ? state.pendingUpdateId
            : null;

        return AnimatedList(
          key: _listKey,
          initialItemCount: _items.length,
          itemBuilder: (context, index, animation) {
            if (index >= _items.length) return const SizedBox.shrink();
            final article = _items[index];
            return _buildAnimatedRow(
                article, animation, pendingDeleteId, pendingUpdateId);
          },
        );
      },
    );
  }

  Widget _buildAnimatedRow(
    ArticleEntity article,
    Animation<double> animation,
    String? pendingDeleteId,
    String? pendingUpdateId,
  ) {
    return SizeTransition(
      sizeFactor: CurvedAnimation(parent: animation, curve: Curves.easeInOut),
      child: FadeTransition(
        opacity: animation,
        child: _ArticleRow(
          article: article,
          isOwner: widget.args.isOwner,
          isPendingDelete: pendingDeleteId == article.remoteId,
          isPendingUpdate: pendingUpdateId == article.remoteId,
          onDelete: () => context
              .read<JournalistProfileBloc>()
              .add(DeleteArticleRequested(article.remoteId!)),
          onEdit: () => _openEditSheet(article),
          onTap: () => Navigator.pushNamed(
            context,
            AppRoutes.articleDetails,
            arguments: article,
          ),
        ),
      ),
    );
  }

  List<ArticleEntity>? _articlesFrom(JournalistProfileState state) {
    if (state is JournalistProfileLoaded) return state.articles;
    if (state is ArticleActionError) return state.articles;
    if (state is ArticleUpdateSuccess) return state.articles;
    return null;
  }

  void _openEditSheet(ArticleEntity article) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetCtx) => BlocProvider.value(
        value: context.read<JournalistProfileBloc>(),
        child: _EditArticleSheet(article: article),
      ),
    );
  }
}

// ── Analytics tab ─────────────────────────────────────────────────────────────

class _AnalyticsTab extends StatelessWidget {
  final JournalistProfileArgs args;
  const _AnalyticsTab({required this.args});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProfileStatsBloc, ProfileStatsState>(
      builder: (context, state) {
        if (state is ProfileStatsLoading || state is ProfileStatsInitial) {
          return const Center(child: CupertinoActivityIndicator());
        }
        if (state is ProfileStatsError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(state.message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.black54)),
            ),
          );
        }
        if (state is ProfileStatsLoaded) {
          return _AnalyticsContent(state: state);
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _AnalyticsContent extends StatelessWidget {
  final ProfileStatsLoaded state;
  const _AnalyticsContent({required this.state});

  @override
  Widget build(BuildContext context) {
    final stats = state.stats;
    final views = state.weeklyViews;

    // Credibility: totalUpvotes / totalVotes * 100
    final credibility = stats.totalVotes > 0
        ? (stats.totalUpvotes / stats.totalVotes * 100).round()
        : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Stats grid
          _StatsGrid(
            articleCount: stats.articleCount,
            totalViews: stats.totalViews,
            totalUpvotes: stats.totalUpvotes,
          ),
          const SizedBox(height: 24),

          // Credibility score
          _SectionCard(
            title: 'Community Credibility',
            child: Row(
              children: [
                Text(
                  credibility != null ? '$credibility' : 'N/A',
                  style: TextStyle(
                    fontSize: 52,
                    fontWeight: FontWeight.w900,
                    color: credibility != null
                        ? _credibilityColor(credibility)
                        : Colors.black26,
                  ),
                ),
                if (credibility != null) ...[
                  const SizedBox(width: 6),
                  const Padding(
                    padding: EdgeInsets.only(top: 18),
                    child: Text('/100',
                        style:
                            TextStyle(fontSize: 18, color: Colors.black38)),
                  ),
                ],
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${stats.totalUpvotes} accurate',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black54)),
                    Text('${stats.totalVotes} total votes',
                        style: const TextStyle(
                            fontSize: 12, color: Colors.black38)),
                  ],
                )
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Bias profile
          _SectionCard(
            title: 'Average Bias Profile',
            child: stats.averagePoliticalLean != null
                ? BiasSpectrumWidget(
                    report: BiasReportEntity(
                      politicalLean: stats.averagePoliticalLean!,
                      emotionalLanguageScore: 0,
                      framingNotes: const [],
                    ),
                  )
                : const Text(
                    'No bias reports yet. Trigger analysis from an article.',
                    style: TextStyle(fontSize: 13, color: Colors.black38),
                  ),
          ),
          const SizedBox(height: 16),

          // 7-day views
          _SectionCard(
            title: '7-Day Views',
            child: _WeeklyBarChart(dailyViews: views),
          ),
        ],
      ),
    );
  }

  Color _credibilityColor(int score) {
    if (score >= 70) return Colors.green.shade700;
    if (score >= 40) return Colors.orange.shade700;
    return Colors.red.shade700;
  }
}

// Stats grid: Articles / Views / Upvotes

class _StatsGrid extends StatelessWidget {
  final int articleCount;
  final int totalViews;
  final int totalUpvotes;

  const _StatsGrid({
    required this.articleCount,
    required this.totalViews,
    required this.totalUpvotes,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _StatCell(label: 'Articles', value: '$articleCount')),
        const SizedBox(width: 8),
        Expanded(
            child: _StatCell(label: 'Views', value: _compact(totalViews))),
        const SizedBox(width: 8),
        Expanded(
            child: _StatCell(
                label: 'Upvotes', value: _compact(totalUpvotes))),
      ],
    );
  }

  String _compact(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _StatCell extends StatelessWidget {
  final String label;
  final String value;
  const _StatCell({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.w900)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(fontSize: 12, color: Colors.black54)),
        ],
      ),
    );
  }
}

// Section card wrapper

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.black12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.black54)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

// 7-day bar chart

class _WeeklyBarChart extends StatelessWidget {
  final List<DailyViewsEntity> dailyViews;
  const _WeeklyBarChart({required this.dailyViews});

  @override
  Widget build(BuildContext context) {
    // Sort ascending and take last 7 days
    final sorted = [...dailyViews]..sort((a, b) => a.date.compareTo(b.date));
    final days = sorted.take(7).toList();

    if (days.isEmpty) {
      return const SizedBox(
        height: 80,
        child: Center(
          child: Text('No view data yet',
              style: TextStyle(fontSize: 13, color: Colors.black38)),
        ),
      );
    }

    return SizedBox(
      height: 100,
      child: CustomPaint(
        painter: _BarChartPainter(days),
        size: Size.infinite,
      ),
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final List<DailyViewsEntity> days;

  _BarChartPainter(this.days);

  @override
  void paint(Canvas canvas, Size size) {
    if (days.isEmpty) return;

    final maxCount = days.map((d) => d.count).reduce(math.max);
    final barAreaHeight = size.height - 18; // 18px for day labels
    final barWidth = (size.width / days.length) * 0.6;
    final gap = (size.width / days.length) * 0.4;
    final halfGap = gap / 2;

    final barPaint = Paint()
      ..color = Colors.black87
      ..style = PaintingStyle.fill;

    final bgPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.06)
      ..style = PaintingStyle.fill;

    final textStyle = const TextStyle(color: Colors.black38, fontSize: 10);

    for (int i = 0; i < days.length; i++) {
      final x = i * (barWidth + gap) + halfGap;
      final center = x + barWidth / 2;

      // Background track
      final bgRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, 0, barWidth, barAreaHeight),
        const Radius.circular(3),
      );
      canvas.drawRRect(bgRect, bgPaint);

      // Filled bar
      final fraction = maxCount > 0 ? days[i].count / maxCount : 0.0;
      final barH = (fraction * barAreaHeight).clamp(2.0, barAreaHeight);
      final barRect = RRect.fromRectAndRadius(
        Rect.fromLTWH(x, barAreaHeight - barH, barWidth, barH),
        const Radius.circular(3),
      );
      canvas.drawRRect(barRect, barPaint);

      // Day label
      final dayLabel = _dayAbbr(days[i].date);
      final tp = TextPainter(
        text: TextSpan(text: dayLabel, style: textStyle),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(
          canvas, Offset(center - tp.width / 2, barAreaHeight + 4));
    }
  }

  String _dayAbbr(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      const abbrs = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return abbrs[dt.weekday - 1];
    } catch (_) {
      return '';
    }
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) =>
      oldDelegate.days != days;
}



// ── Article row ───────────────────────────────────────────────────────────────

class _ArticleRow extends StatelessWidget {
  final ArticleEntity article;
  final bool isOwner;
  final bool isPendingDelete;
  final bool isPendingUpdate;
  final VoidCallback onDelete;
  final VoidCallback onEdit;
  final VoidCallback onTap;

  const _ArticleRow({
    required this.article,
    required this.isOwner,
    required this.isPendingDelete,
    required this.isPendingUpdate,
    required this.onDelete,
    required this.onEdit,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isPending = isPendingDelete || isPendingUpdate;
    return Opacity(
      opacity: isPending ? 0.45 : 1.0,
      child: GestureDetector(
        onTap: isPending ? null : onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          height: MediaQuery.of(context).size.width / 2.4,
          child: Row(
            children: [
              _Thumbnail(url: article.imageUrl),
              const SizedBox(width: 12),
              Expanded(child: _ArticleInfo(article: article)),
              if (isOwner)
                _OwnerActions(
                  isPending: isPending,
                  onEdit: onEdit,
                  onDelete: onDelete,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Thumbnail extends StatelessWidget {
  final String? url;
  const _Thumbnail({required this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: CachedNetworkImage(
        imageUrl: url ?? '',
        width: MediaQuery.of(context).size.width / 3.2,
        height: double.maxFinite,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          color: Colors.black12,
          child: const CupertinoActivityIndicator(),
        ),
        errorWidget: (_, __, ___) => Container(
          color: Colors.black12,
          child: const Icon(Icons.broken_image_outlined),
        ),
      ),
    );
  }
}

class _ArticleInfo extends StatelessWidget {
  final ArticleEntity article;
  const _ArticleInfo({required this.article});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            article.title ?? '',
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: Colors.black87),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: Text(
              article.description ?? '',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ),
          if (article.publishedAt != null)
            Row(
              children: [
                const Icon(Icons.access_time, size: 12, color: Colors.black45),
                const SizedBox(width: 4),
                Text(
                  formatDateISO(article.publishedAt!),
                  style:
                      const TextStyle(fontSize: 11, color: Colors.black45),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _OwnerActions extends StatelessWidget {
  final bool isPending;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _OwnerActions({
    required this.isPending,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    if (isPending) {
      return const Padding(
        padding: EdgeInsets.symmetric(horizontal: 8),
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: onEdit,
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.edit_outlined, size: 20, color: Colors.black54),
          ),
        ),
        GestureDetector(
          onTap: onDelete,
          child: const Padding(
            padding: EdgeInsets.all(6),
            child: Icon(Icons.delete_outline, size: 20, color: Colors.red),
          ),
        ),
      ],
    );
  }
}

// ── Inline edit bottom sheet ──────────────────────────────────────────────────

class _EditArticleSheet extends StatefulWidget {
  final ArticleEntity article;
  const _EditArticleSheet({required this.article});

  @override
  State<_EditArticleSheet> createState() => _EditArticleSheetState();
}

class _EditArticleSheetState extends State<_EditArticleSheet> {
  late final _titleController =
      TextEditingController(text: widget.article.title);
  late final _descController =
      TextEditingController(text: widget.article.description);

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<JournalistProfileBloc, JournalistProfileState>(
      listener: (ctx, state) {
        if (state is ArticleUpdateSuccess || state is JournalistProfileLoaded) {
          Navigator.pop(ctx);
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.viewInsetsOf(context).bottom + 24,
        ),
        child:
            BlocBuilder<JournalistProfileBloc, JournalistProfileState>(
          builder: (context, state) {
            final isLoading = state is JournalistProfileLoaded &&
                state.pendingUpdateId == widget.article.remoteId;
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Text('Edit Article',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w800)),
                    const Spacer(),
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: const Icon(Icons.close, color: Colors.black54),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  enabled: !isLoading,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _descController,
                  enabled: !isLoading,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: isLoading ? null : _save,
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('Save Changes',
                            style: TextStyle(fontSize: 16)),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _save() {
    final title = _titleController.text.trim();
    final description = _descController.text.trim();
    if (title.isEmpty) return;

    context.read<JournalistProfileBloc>().add(
          UpdateArticleRequested(
            UpdateArticleParams(
              articleId: widget.article.remoteId!,
              title: title,
              description: description,
              content: widget.article.content ?? '',
              localImagePath: null,
              category: widget.article.category,
              existingThumbnailUrl: widget.article.imageUrl ?? '',
            ),
          ),
        );
  }
}


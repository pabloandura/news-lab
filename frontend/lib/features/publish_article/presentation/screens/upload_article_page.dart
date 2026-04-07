import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:news_lab/features/article_category/domain/entities/article_category_entity.dart';
import 'package:news_lab/features/article_category/presentation/cubit/article_category_cubit.dart';
import 'package:news_lab/features/article_category/presentation/cubit/article_category_state.dart';
import 'package:news_lab/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:news_lab/features/auth/presentation/bloc/auth_state.dart';
import 'package:news_lab/features/daily_news/presentation/bloc/article/remote/remote_article_bloc.dart';
import 'package:news_lab/features/daily_news/presentation/bloc/article/remote/remote_article_event.dart';
import 'package:news_lab/features/publish_article/presentation/bloc/upload_article_bloc.dart';
import 'package:news_lab/features/publish_article/presentation/bloc/upload_article_event.dart';
import 'package:news_lab/features/publish_article/presentation/bloc/upload_article_state.dart';

const int _kTitleMaxLength = 120;
const int _kDescriptionMaxLength = 280;

class UploadArticlePage extends StatefulWidget {
  final bool isTab;
  final VoidCallback? onPublishSuccess;

  const UploadArticlePage({
    super.key,
    this.isTab = false,
    this.onPublishSuccess,
  });

  @override
  State<UploadArticlePage> createState() => _UploadArticlePageState();
}

class _UploadArticlePageState extends State<UploadArticlePage> {
  final _pageController = PageController();
  final _step1FormKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();
  File? _thumbnailFile;
  ArticleCategoryEntity? _selectedCategory;
  int _currentStep = 0;
  bool _showSuccess = false;
  String _publishedTitle = '';
  Timer? _successTimer;

  @override
  void initState() {
    super.initState();
    _titleController.addListener(() => setState(() {}));
    _descriptionController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _pageController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    _successTimer?.cancel();
    super.dispose();
  }

  bool get _step1Valid =>
      _titleController.text.trim().isNotEmpty &&
      _titleController.text.length <= _kTitleMaxLength &&
      _descriptionController.text.trim().isNotEmpty &&
      _descriptionController.text.length <= _kDescriptionMaxLength;

  @override
  Widget build(BuildContext context) {
    if (_showSuccess) {
      return _SuccessView(
        title: _publishedTitle,
        onGoToFeed: _navigateToFeed,
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Publish Article',
            style: TextStyle(color: Colors.black)),
        automaticallyImplyLeading: !widget.isTab,
        leading: widget.isTab
            ? null
            : GestureDetector(
                onTap: () => Navigator.pop(context),
                child: const Icon(Icons.close, color: Colors.black),
              ),
      ),
      body: BlocConsumer<UploadArticleBloc, UploadArticleState>(
        listener: (context, state) {
          if (state is UploadArticleSuccess) {
            context.read<RemoteArticlesBloc>().add(const GetArticles());
            setState(() {
              _publishedTitle = _titleController.text.trim();
              _showSuccess = true;
            });
            _successTimer = Timer(const Duration(seconds: 2), _navigateToFeed);
          }
          if (state is UploadArticleError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.red.shade700,
                content: Text(state.message),
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is UploadArticleLoading;
          return Column(
            children: [
              _StepIndicator(currentStep: _currentStep),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    _Step1Form(
                      formKey: _step1FormKey,
                      titleController: _titleController,
                      descriptionController: _descriptionController,
                      thumbnailFile: _thumbnailFile,
                      selectedCategory: _selectedCategory,
                      isLoading: isLoading,
                      onPickImage: _pickImage,
                      onCategorySelected: (cat) =>
                          setState(() => _selectedCategory = cat),
                      onNext: _step1Valid ? _goToStep2 : null,
                    ),
                    _Step2Form(
                      contentController: _contentController,
                      isLoading: isLoading,
                      onBack: _goToStep1,
                      onPublish: isLoading ? null : _onPublish,
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _goToStep2() {
    if (_thumbnailFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Please select a thumbnail image.'),
        ),
      );
      return;
    }
    setState(() => _currentStep = 1);
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _goToStep1() {
    setState(() => _currentStep = 0);
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _navigateToFeed() {
    _successTimer?.cancel();
    widget.onPublishSuccess?.call();
    // Reset form for next publish
    setState(() {
      _showSuccess = false;
      _currentStep = 0;
      _titleController.clear();
      _descriptionController.clear();
      _contentController.clear();
      _thumbnailFile = null;
      _selectedCategory = null;
    });
    _pageController.jumpToPage(0);
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _thumbnailFile = File(picked.path));
    }
  }

  void _onPublish() {
    if (_contentController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Content cannot be empty.'),
        ),
      );
      return;
    }

    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) {
      Navigator.pushReplacementNamed(context, '/Login');
      return;
    }

    final displayName = authState.user.displayName?.trim().isNotEmpty == true
        ? authState.user.displayName!.trim()
        : authState.user.email.split('@').first;

    context.read<UploadArticleBloc>().add(UploadArticleRequested(
          authorId: authState.user.uid,
          author: displayName,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          content: _contentController.text.trim(),
          localImagePath: _thumbnailFile!.path,
          category: _selectedCategory?.slug,
        ));
  }
}

// ── Step indicator dots ───────────────────────────────────────────────────────

class _StepIndicator extends StatelessWidget {
  final int currentStep;
  const _StepIndicator({required this.currentStep});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _StepDot(active: currentStep == 0),
          const SizedBox(width: 8),
          _StepDot(active: currentStep == 1),
        ],
      ),
    );
  }
}

class _StepDot extends StatelessWidget {
  final bool active;
  const _StepDot({required this.active});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: active ? 20 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? Colors.black : Colors.black26,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}

// ── Step 1 form ───────────────────────────────────────────────────────────────

class _Step1Form extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final File? thumbnailFile;
  final ArticleCategoryEntity? selectedCategory;
  final bool isLoading;
  final VoidCallback onPickImage;
  final void Function(ArticleCategoryEntity?) onCategorySelected;
  final VoidCallback? onNext;

  const _Step1Form({
    required this.formKey,
    required this.titleController,
    required this.descriptionController,
    required this.thumbnailFile,
    required this.selectedCategory,
    required this.isLoading,
    required this.onPickImage,
    required this.onCategorySelected,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    final titleLen = titleController.text.length;
    final descLen = descriptionController.text.length;
    final titleOverLimit = titleLen > _kTitleMaxLength;
    final descOverLimit = descLen > _kDescriptionMaxLength;

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 8),
              // Thumbnail picker
              GestureDetector(
                onTap: isLoading ? null : onPickImage,
                child: Container(
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: thumbnailFile != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.file(thumbnailFile!, fit: BoxFit.cover),
                        )
                      : const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_photo_alternate_outlined,
                                size: 40, color: Colors.black45),
                            SizedBox(height: 8),
                            Text('Tap to add thumbnail *',
                                style: TextStyle(color: Colors.black45)),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
              // Title with counter
              TextFormField(
                controller: titleController,
                enabled: !isLoading,
                maxLength: null,
                decoration: InputDecoration(
                  labelText: 'Headline',
                  hintText: 'Enter article headline',
                  border: const OutlineInputBorder(),
                  errorText: titleOverLimit ? 'Exceeds 120 characters' : null,
                  suffixText: '$titleLen/$_kTitleMaxLength',
                  suffixStyle: TextStyle(
                    fontSize: 11,
                    color: titleOverLimit ? Colors.red : Colors.black38,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Description with counter
              TextFormField(
                controller: descriptionController,
                enabled: !isLoading,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Description',
                  hintText: 'Short summary of your article',
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                  errorText: descOverLimit ? 'Exceeds 280 characters' : null,
                  suffixText: '$descLen/$_kDescriptionMaxLength',
                  suffixStyle: TextStyle(
                    fontSize: 11,
                    color: descOverLimit ? Colors.red : Colors.black38,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _CategorySelector(
                selectedCategory: selectedCategory,
                disabled: isLoading,
                onCategorySelected: onCategorySelected,
              ),
              const SizedBox(height: 28),
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: onNext,
                  child: const Text('Next →', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Step 2 form ───────────────────────────────────────────────────────────────

class _Step2Form extends StatelessWidget {
  final TextEditingController contentController;
  final bool isLoading;
  final VoidCallback onBack;
  final VoidCallback? onPublish;

  const _Step2Form({
    required this.contentController,
    required this.isLoading,
    required this.onBack,
    required this.onPublish,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 8),
            TextFormField(
              controller: contentController,
              enabled: !isLoading,
              maxLines: 12,
              decoration: const InputDecoration(
                labelText: 'Article Content',
                hintText: 'Write your full article here...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            // AI analysis info callout
            Card(
              elevation: 0,
              color: Colors.blue.shade50,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
                side: BorderSide(color: Colors.blue.shade200),
              ),
              child: const Padding(
                padding: EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline,
                        color: Colors.blueAccent, size: 20),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'After publishing, AI will automatically analyze your article '
                        'for bias and fact-check accuracy. Badges will appear on your '
                        'article once analysis is complete.',
                        style: TextStyle(fontSize: 12, height: 1.5),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                OutlinedButton(
                  onPressed: isLoading ? null : onBack,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.black,
                    minimumSize: const Size(80, 50),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('← Back'),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.black,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: onPublish,
                      child: isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('Publish',
                              style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

// ── Category selector ─────────────────────────────────────────────────────────

class _CategorySelector extends StatelessWidget {
  final ArticleCategoryEntity? selectedCategory;
  final bool disabled;
  final void Function(ArticleCategoryEntity?) onCategorySelected;

  const _CategorySelector({
    required this.selectedCategory,
    required this.disabled,
    required this.onCategorySelected,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ArticleCategoryCubit, ArticleCategoryState>(
      builder: (context, state) {
        final categories =
            state is ArticleCategoryLoaded ? state.categories : <ArticleCategoryEntity>[];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Category (optional)',
                style: TextStyle(fontSize: 13, color: Colors.black54)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: categories.map((cat) {
                final isSelected = selectedCategory?.slug == cat.slug;
                return FilterChip(
                  label: Text(cat.name),
                  selected: isSelected,
                  onSelected: disabled
                      ? null
                      : (_) => onCategorySelected(isSelected ? null : cat),
                  selectedColor: Colors.black,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

// ── Success screen ────────────────────────────────────────────────────────────

class _SuccessView extends StatelessWidget {
  final String title;
  final VoidCallback onGoToFeed;

  const _SuccessView({required this.title, required this.onGoToFeed});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 80,
                  color: Colors.green,
                ),
                const SizedBox(height: 24),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Your article is now live',
                  style: TextStyle(fontSize: 15, color: Colors.black54),
                ),
                const SizedBox(height: 6),
                const Text(
                  'AI analysis will appear shortly',
                  style: TextStyle(fontSize: 13, color: Colors.black38),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: onGoToFeed,
                    child: const Text('Go to Feed',
                        style: TextStyle(fontSize: 16)),
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


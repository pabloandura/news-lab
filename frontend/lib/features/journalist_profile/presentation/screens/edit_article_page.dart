import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:news_lab/core/domain/entities/article_entity.dart';
import 'package:news_lab/features/article_category/domain/entities/article_category_entity.dart';
import 'package:news_lab/features/article_category/presentation/cubit/article_category_cubit.dart';
import 'package:news_lab/features/article_category/presentation/cubit/article_category_state.dart';
import 'package:news_lab/features/journalist_profile/domain/usecases/journalist_profile_params.dart';
import 'package:news_lab/features/journalist_profile/presentation/bloc/journalist_profile_bloc.dart';
import 'package:news_lab/features/journalist_profile/presentation/bloc/journalist_profile_event.dart';
import 'package:news_lab/features/journalist_profile/presentation/bloc/journalist_profile_state.dart';

class EditArticlePage extends StatefulWidget {
  final ArticleEntity article;

  const EditArticlePage({super.key, required this.article});

  @override
  State<EditArticlePage> createState() => _EditArticlePageState();
}

class _EditArticlePageState extends State<EditArticlePage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _contentController;
  File? _newThumbnailFile;
  ArticleCategoryEntity? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.article.title);
    _descriptionController =
        TextEditingController(text: widget.article.description);
    _contentController = TextEditingController(text: widget.article.content);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            const Text('Edit Article', style: TextStyle(color: Colors.black)),
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: const Icon(Icons.close, color: Colors.black),
        ),
      ),
      body: BlocConsumer<JournalistProfileBloc, JournalistProfileState>(
        listener: (context, state) {
          if (state is ArticleUpdateSuccess) {
            Navigator.pop(context);
          }
          if (state is ArticleActionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: Colors.red.shade700,
                content: Text(state.message),
              ),
            );
          }
        },
        builder: (context, state) {
          final isLoading = state is JournalistProfileLoaded &&
              state.pendingUpdateId == widget.article.remoteId;

          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildThumbnailPicker(isLoading),
                    const SizedBox(height: 24),
                    _buildField(
                      controller: _titleController,
                      label: 'Title',
                      hint: 'Enter article title',
                      enabled: !isLoading,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Title is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      controller: _descriptionController,
                      label: 'Description',
                      hint: 'Short summary of your article',
                      enabled: !isLoading,
                      maxLines: 2,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Description is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildField(
                      controller: _contentController,
                      label: 'Content',
                      hint: 'Write your article here...',
                      enabled: !isLoading,
                      maxLines: 8,
                      validator: (v) => (v == null || v.trim().isEmpty)
                          ? 'Content is required'
                          : null,
                    ),
                    const SizedBox(height: 16),
                    _buildCategorySelector(isLoading),
                    const SizedBox(height: 32),
                    SizedBox(
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: isLoading ? null : _onSave,
                        child: isLoading
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Text('Save',
                                style: TextStyle(fontSize: 16)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildThumbnailPicker(bool disabled) {
    return GestureDetector(
      onTap: disabled ? null : _pickImage,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.black12),
        ),
        child: _newThumbnailFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_newThumbnailFile!, fit: BoxFit.cover),
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: widget.article.imageUrl ?? '',
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) =>
                          Container(color: Colors.black12),
                    ),
                    Container(
                      color: Colors.black.withValues(alpha: 0.35),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.edit, color: Colors.white70, size: 28),
                          SizedBox(height: 6),
                          Text('Tap to change thumbnail',
                              style: TextStyle(
                                  color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCategorySelector(bool disabled) {
    final currentSlug = widget.article.category;
    return BlocBuilder<ArticleCategoryCubit, ArticleCategoryState>(
      builder: (context, state) {
        final categories =
            state is ArticleCategoryLoaded ? state.categories : <ArticleCategoryEntity>[];

        if (_selectedCategory == null && currentSlug != null) {
          try {
            _selectedCategory =
                categories.firstWhere((c) => c.slug == currentSlug);
          } catch (_) {}
        }

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
                final isSelected = _selectedCategory?.slug == cat.slug;
                return FilterChip(
                  label: Text(cat.name),
                  selected: isSelected,
                  onSelected: disabled
                      ? null
                      : (_) => setState(() {
                            _selectedCategory = isSelected ? null : cat;
                          }),
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

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool enabled,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        alignLabelWithHint: maxLines > 1,
      ),
    );
  }

  Future<void> _pickImage() async {
    final picked = await ImagePicker()
        .pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _newThumbnailFile = File(picked.path));
    }
  }

  void _onSave() {
    if (!_formKey.currentState!.validate()) return;

    context.read<JournalistProfileBloc>().add(
          UpdateArticleRequested(
            UpdateArticleParams(
              articleId: widget.article.remoteId!,
              title: _titleController.text.trim(),
              description: _descriptionController.text.trim(),
              content: _contentController.text.trim(),
              category: _selectedCategory?.slug,
              localImagePath: _newThumbnailFile?.path,
              existingThumbnailUrl: widget.article.imageUrl ?? '',
            ),
          ),
        );
  }
}

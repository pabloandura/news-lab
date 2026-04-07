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

class UploadArticlePage extends StatefulWidget {
  final bool isTab;
  const UploadArticlePage({super.key, this.isTab = false});

  @override
  State<UploadArticlePage> createState() => _UploadArticlePageState();
}

class _UploadArticlePageState extends State<UploadArticlePage> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contentController = TextEditingController();
  File? _thumbnailFile;
  ArticleCategoryEntity? _selectedCategory;

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
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                backgroundColor: Colors.black,
                content: Text('Article published successfully!'),
              ),
            );
            context.read<RemoteArticlesBloc>().add(const GetArticles());
            Navigator.pop(context);
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
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Title is required' : null,
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
                    validator: (v) =>
                        (v == null || v.trim().isEmpty) ? 'Content is required' : null,
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
                      onPressed: isLoading ? null : _onPublish,
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
                ],
              ),
            ),
          ));
        },
      ),
    );
  }

  Widget _buildCategorySelector(bool disabled) {
    return BlocBuilder<ArticleCategoryCubit, ArticleCategoryState>(
      builder: (context, state) {
        final categories = state is ArticleCategoryLoaded ? state.categories : <ArticleCategoryEntity>[];
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
        child: _thumbnailFile != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_thumbnailFile!, fit: BoxFit.cover),
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
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) {
      setState(() => _thumbnailFile = File(picked.path));
    }
  }

  void _onPublish() {
    if (_thumbnailFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          backgroundColor: Colors.red,
          content: Text('Please select a thumbnail image.'),
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) return;

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

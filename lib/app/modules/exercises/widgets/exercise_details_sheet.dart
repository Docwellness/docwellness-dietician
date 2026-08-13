import 'package:docwellnesdoc/app/modules/exercises/controllers/exercises_controller.dart';
import 'package:docwellnesdoc/app/modules/exercises/models/exercise_model.dart';
import 'package:docwellnesdoc/app/modules/exercises/utils/exercise_style_helpers.dart';
import 'package:docwellnesdoc/app/utils/common_widgets/custom_text.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:youtube_player_flutter/youtube_player_flutter.dart';

/// Details view for a catalog exercise - opened by tapping a tile in
/// exercises_view.dart. Mirrors recipe_details.dart's role for recipes,
/// scoped down to a bottom sheet since Exercise has far fewer fields than
/// Recipe. Includes an edit affordance for videoUrl - the one field that
/// stays manual/dietician-entered even for AI-generated exercises (see
/// add_exercise_view.dart's doc comment), so it needs to be settable after
/// the fact too, not just at creation time - and a language switcher so the
/// dietician can review any translated content, mirroring
/// recipe_details_screen.dart's pattern on the patient app.
Future<void> showExerciseDetailsSheet(BuildContext context, Exercise exercise) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.78,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      expand: false,
      builder: (context, scrollController) => _ExerciseDetailsContent(
        initialExercise: exercise,
        scrollController: scrollController,
      ),
    ),
  );
}

class _ExerciseDetailsContent extends StatefulWidget {
  final Exercise initialExercise;
  final ScrollController scrollController;
  const _ExerciseDetailsContent({required this.initialExercise, required this.scrollController});

  @override
  State<_ExerciseDetailsContent> createState() => _ExerciseDetailsContentState();
}

class _ExerciseDetailsContentState extends State<_ExerciseDetailsContent> {
  static const _accent = Color(0xff851653);

  late Exercise _exercise;
  bool _isSavingVideo = false;
  String _selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();
    _exercise = widget.initialExercise;
  }

  ExerciseCategoryStyle get _categoryStyle => categoryStyleFor(_exercise.category);
  Color get _difficultyColor => difficultyColorFor(_exercise.difficultyLevel);

  // Same reference convention as add_exercise_view.dart's AI-generated
  // preview (30 min, 70kg avg adult) - purely informational here too, the
  // real per-patient figure is always computed server-side at log time.
  int get _referenceCaloriesBurned => (_exercise.met * 70 * 0.5).round();

  // Resolves display text for the currently selected language, falling
  // back to the base English fields when a translation is missing for a
  // given key (mirrors recipe_details_screen.dart's per-field fallback).
  String get _displayName {
    if (_selectedLanguage == 'English') return _exercise.name;
    final t = _exercise.translations[_selectedLanguage];
    return (t is Map && t['name'] is String && (t['name'] as String).isNotEmpty) ? t['name'] : _exercise.name;
  }

  String get _displayDescription {
    if (_selectedLanguage == 'English') return _exercise.description;
    final t = _exercise.translations[_selectedLanguage];
    return (t is Map && t['description'] is String) ? t['description'] : _exercise.description;
  }

  List<String> get _displayInstructions {
    if (_selectedLanguage == 'English') return _exercise.instructions;
    final t = _exercise.translations[_selectedLanguage];
    if (t is Map && t['instructions'] is List && (t['instructions'] as List).isNotEmpty) {
      return List<String>.from(t['instructions']);
    }
    return _exercise.instructions;
  }

  List<String> get _availableLanguages => ['English', ..._exercise.translations.keys];

  String? get _youtubeId {
    if (_exercise.videoUrl.isEmpty) return null;
    final patterns = [
      RegExp(r'youtu\.be/([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com/watch\?.*v=([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com/embed/([a-zA-Z0-9_-]{11})'),
      RegExp(r'youtube\.com/shorts/([a-zA-Z0-9_-]{11})'),
    ];
    for (final p in patterns) {
      final m = p.firstMatch(_exercise.videoUrl);
      if (m != null) return m.group(1);
    }
    return null;
  }

  Future<void> _openEditVideoDialog() async {
    final urlController = TextEditingController(text: _exercise.videoUrl);

    final newUrl = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: CustomText(
          text: _exercise.videoUrl.isEmpty ? 'Add Video' : 'Edit Video',
          fontWeight: FontWeight.w700,
          fontSize: 16,
          color: const Color(0xff530630),
        ),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            labelText: 'Video URL',
            hintText: 'Paste a demo/tutorial link (e.g. YouTube)',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(context, urlController.text.trim()),
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.w700, color: _accent)),
          ),
        ],
      ),
    );

    if (newUrl == null || newUrl == _exercise.videoUrl) return;

    setState(() => _isSavingVideo = true);
    final controller = Get.isRegistered<ExercisesController>() ? Get.find<ExercisesController>() : null;
    final updated = controller != null
        ? await controller.updateExercise(_exercise.id, {'videoUrl': newUrl})
        : null;
    if (!mounted) return;
    setState(() => _isSavingVideo = false);

    if (updated != null) {
      setState(() => _exercise = updated);
    } else {
      Get.snackbar('Failed', 'Could not save the video link. Please try again.', backgroundColor: Colors.white);
    }
  }

  Widget _sectionTitle(String text, {IconData? icon}) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 10),
    child: Row(
      children: [
        if (icon != null) ...[
          Icon(icon, size: 16, color: _categoryStyle.color),
          const SizedBox(width: 6),
        ],
        CustomText(text: text, fontWeight: FontWeight.w700, fontSize: 14, color: const Color(0xff1F2A37)),
      ],
    ),
  );

  Widget _chip(String text, {Color? color}) {
    final c = color ?? _accent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withValues(alpha: 0.3)),
      ),
      child: CustomText(text: text, fontWeight: FontWeight.w600, fontSize: 12, color: c),
    );
  }

  Widget _chipGroup(List<String> items) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: items.map((item) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xffFEF6FB),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xffFCE7F6)),
        ),
        child: CustomText(text: item, fontWeight: FontWeight.w500, fontSize: 12, color: _accent),
      );
    }).toList(),
  );

  @override
  Widget build(BuildContext context) {
    final style = _categoryStyle;
    final ytId = _youtubeId;
    final languages = _availableLanguages;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: ListView(
        controller: widget.scrollController,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 36),
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: const Color(0xffE5E7EB), borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 18),
          // Header: gradient icon tile + name, colored per category so the
          // catalog reads as visually distinct rather than one flat pink
          // block regardless of exercise type.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [style.color.withValues(alpha: 0.85), style.color],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(color: style.color.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 4)),
                  ],
                ),
                child: Icon(style.icon, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: CustomText(text: _displayName, fontWeight: FontWeight.w700, fontSize: 19, color: const Color(0xff1F2A37)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _chip(_exercise.category, color: style.color),
              _chip(_exercise.difficultyLevel, color: _difficultyColor),
              _chip('MET ${_exercise.met}'),
            ],
          ),
          if (languages.length > 1) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: languages.map((lang) {
                final isSelected = _selectedLanguage == lang;
                return GestureDetector(
                  onTap: () => setState(() => _selectedLanguage = lang),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isSelected ? const Color(0xff1F2A37) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isSelected ? const Color(0xff1F2A37) : const Color(0xffE5E7EB)),
                    ),
                    child: CustomText(
                      text: lang,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                      color: isSelected ? Colors.white : const Color(0xff384250),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
          Container(
            margin: const EdgeInsets.only(top: 18),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xffFEF6FB), Color(0xffFDF2FA)]),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xffFCE7F6)),
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(color: Color(0xffFCE7F6), shape: BoxShape.circle),
                  child: const Icon(Icons.local_fire_department_rounded, color: _accent, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: CustomText(
                    text: '~$_referenceCaloriesBurned kcal in 30 min (avg. adult, 70kg) - actual burn is computed per-patient at logging time',
                    fontWeight: FontWeight.w400,
                    fontSize: 12,
                    color: const Color(0xff6C737F),
                  ),
                ),
              ],
            ),
          ),
          if (_displayDescription.isNotEmpty) ...[
            _sectionTitle('Description', icon: Icons.info_outline_rounded),
            CustomText(text: _displayDescription, fontWeight: FontWeight.w400, fontSize: 13.5, color: const Color(0xff384250)),
          ],
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _sectionTitle('Demo Video', icon: Icons.play_circle_outline_rounded),
              TextButton.icon(
                onPressed: _isSavingVideo ? null : _openEditVideoDialog,
                icon: Icon(_exercise.videoUrl.isEmpty ? Icons.add_rounded : Icons.edit_outlined, size: 16, color: _accent),
                label: Text(
                  _exercise.videoUrl.isEmpty ? 'Add Video' : 'Edit',
                  style: const TextStyle(color: _accent, fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ),
            ],
          ),
          if (_isSavingVideo)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(child: CircularProgressIndicator(color: _accent, strokeWidth: 2)),
            )
          else if (ytId != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: YoutubePlayer(
                  controller: YoutubePlayerController(
                    initialVideoId: ytId,
                    flags: const YoutubePlayerFlags(autoPlay: false, mute: false),
                  ),
                ),
              ),
            )
          else if (_exercise.videoUrl.isNotEmpty)
            CustomText(text: _exercise.videoUrl, fontWeight: FontWeight.w400, fontSize: 13, color: _accent)
          else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xffF9FAFB),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xffE5E7EB)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.videocam_off_outlined, size: 16, color: Color(0xff9DA4AE)),
                  const SizedBox(width: 8),
                  CustomText(text: 'No video attached yet', fontWeight: FontWeight.w400, fontSize: 13, color: const Color(0xff6C737F)),
                ],
              ),
            ),
          if (_displayInstructions.isNotEmpty) ...[
            _sectionTitle('Instructions', icon: Icons.checklist_rounded),
            ..._displayInstructions.asMap().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      margin: const EdgeInsets.only(top: 1),
                      decoration: BoxDecoration(color: style.color, shape: BoxShape.circle),
                      child: Center(
                        child: Text(
                          '${entry.key + 1}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: CustomText(text: entry.value, fontWeight: FontWeight.w400, fontSize: 13.5, color: const Color(0xff384250)),
                    ),
                  ],
                ),
              ),
            ),
          ],
          if (_exercise.targetMuscleGroups.isNotEmpty) ...[
            _sectionTitle('Target Muscle Groups', icon: Icons.accessibility_new_rounded),
            _chipGroup(_exercise.targetMuscleGroups),
          ],
          if (_exercise.equipment.isNotEmpty) ...[
            _sectionTitle('Equipment', icon: Icons.sports_gymnastics_outlined),
            _chipGroup(_exercise.equipment),
          ],
        ],
      ),
    );
  }
}

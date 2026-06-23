import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_routes.dart';
import '../../../core/constants/app_strings.dart';
import '../../../core/utils/image_picker_helper.dart';
import '../../../data/models/plant_id_response_model.dart';
import '../../../domain/entities/plant.dart';
import '../../providers/add_plant_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/plant_provider.dart';
import '../../widgets/error_snackbar.dart';
import '../../widgets/loading_overlay.dart';

class AddPlantScreen extends ConsumerStatefulWidget {
  const AddPlantScreen({super.key});

  @override
  ConsumerState<AddPlantScreen> createState() => _AddPlantScreenState();
}

class _AddPlantScreenState extends ConsumerState<AddPlantScreen> {
  // Valores editáveis pelo usuário (preenchidos pela IA automaticamente)
  String? _name;
  String? _location;
  int _waterDays = 3;
  int _fertilizeDays = 30;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    ref.listen<AddPlantState>(addPlantProvider, (prev, next) {
      final suggestion = next.activeSuggestion;
      if (suggestion != null && prev?.activeSuggestion == null) {
        setState(() => _name = suggestion.commonName ?? suggestion.name);
      }
      final info = next.careInfo;
      if (info != null && prev?.careInfo == null) {
        setState(() {
          _location ??= info.suggestedLocation;
          _waterDays = info.waterFrequencyDays;
          _fertilizeDays = info.fertilizeFrequencyDays;
        });
      }
    });

    final addState = ref.watch(addPlantProvider);
    final identified =
        addState.activeSuggestion != null &&
        !addState.isIdentifying &&
        addState.identificationError == null;

    return LoadingOverlay(
      isLoading: _saving,
      child: Scaffold(
        appBar: AppBar(title: const Text(AppStrings.addPlant)),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _PhotoSection(image: addState.image, onPickImage: _pickImage),
              const SizedBox(height: 16),

              // Loading / erro / card
              if (addState.isIdentifying)
                _LoadingCard(label: 'Identificando planta com IA...'),
              if (!addState.isIdentifying &&
                  addState.identificationError != null)
                _ErrorCard(
                  message: addState.identificationError!,
                  onRetry: () => ref.read(addPlantProvider.notifier).identify(),
                ),
              if (identified) ...[
                _PlantAlbumCard(
                  name: _name ?? '',
                  scientificName: addState.activeSuggestion!.name,
                  description: addState.careInfo?.description,
                  location: _location,
                  waterDays: _waterDays,
                  fertilizeDays: _fertilizeDays,
                  isLoadingTips: addState.isLoadingTips,
                  tipsError: addState.tipsError,
                  hasMultipleSuggestions:
                      (addState.identification?.suggestions.length ?? 0) > 1,
                  onViewSuggestions: () => _openSuggestions(addState),
                  onEditName: _editName,
                  onEditLocation: _editLocation,
                  onEditWater: _editWater,
                  onEditFertilize: _editFertilize,
                  onRetryTips: () =>
                      ref.read(addPlantProvider.notifier).retryTips(),
                ),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: _saving || _name == null || _name!.isEmpty
                      ? null
                      : _save,
                  icon: const Icon(Icons.eco_outlined),
                  label: const Text('Salvar no meu jardim'),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(double.infinity, 52),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final file = await pickPlantImage(context);
    if (file == null) return;
    setState(() {
      _name = null;
      _location = null;
      _waterDays = 3;
      _fertilizeDays = 30;
    });
    ref.read(addPlantProvider.notifier).setImage(file);
    await ref.read(addPlantProvider.notifier).identify();
  }

  Future<void> _openSuggestions(AddPlantState state) async {
    if ((state.identification?.suggestions.length ?? 0) <= 1) return;
    final result = await context.push<PlantIdSuggestion>(
      AppRoutes.identifyPlant,
    );
    if (result != null && mounted) {
      setState(() => _name = result.commonName ?? result.name);
      ref.read(addPlantProvider.notifier).selectSuggestion(result);
    }
  }

  Future<void> _editName() async {
    final result = await _showTextDialog(
      title: 'Nome da planta',
      initial: _name ?? '',
      hint: 'Ex: Samambaia',
    );
    if (result != null) setState(() => _name = result);
  }

  Future<void> _editLocation() async {
    final result = await _showTextDialog(
      title: 'Local ideal',
      initial: _location ?? '',
      hint: 'Ex: Ambiente com luz indireta',
    );
    if (result != null) setState(() => _location = result);
  }

  Future<void> _editWater() async {
    final result = await _showFrequencyDialog(
      title: 'Frequência de rega',
      icon: Icons.water_drop_outlined,
      initial: _waterDays,
    );
    if (result != null) setState(() => _waterDays = result);
  }

  Future<void> _editFertilize() async {
    final result = await _showFrequencyDialog(
      title: 'Frequência de adubação',
      icon: Icons.eco_outlined,
      initial: _fertilizeDays,
    );
    if (result != null) setState(() => _fertilizeDays = result);
  }

  Future<String?> _showTextDialog({
    required String title,
    required String initial,
    required String hint,
  }) async {
    final controller = TextEditingController(text: initial);
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(hintText: hint),
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  Future<int?> _showFrequencyDialog({
    required String title,
    required IconData icon,
    required int initial,
  }) async {
    int value = initial;
    return showDialog<int>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(title),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline),
                iconSize: 32,
                color: AppColors.primary,
                onPressed: value > 1 ? () => setLocal(() => value--) : null,
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$value',
                    style: const TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  Text(
                    value == 1 ? 'dia' : 'dias',
                    style: const TextStyle(color: AppColors.textSecondary),
                  ),
                ],
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.add_circle_outline),
                iconSize: 32,
                color: AppColors.primary,
                onPressed: value < 365 ? () => setLocal(() => value++) : null,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, value),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (_name == null || _name!.isEmpty) return;
    setState(() => _saving = true);

    try {
      final user = await ref.read(authNotifierProvider.future);
      if (user == null) throw Exception('Usuário não autenticado');

      final addState = ref.read(addPlantProvider);
      final suggestion = addState.activeSuggestion;

      final plant = Plant(
        id: '',
        userId: user.id,
        name: _name!,
        scientificName: suggestion?.name,
        commonName: suggestion?.commonName,
        location: _location?.isEmpty == true ? null : _location,
        waterFrequencyDays: _waterDays,
        fertilizeFrequencyDays: _fertilizeDays,
        createdAt: DateTime.now(),
        description: addState.careInfo?.description,
        careTips: addState.careInfo?.tips,
      );

      await ref
          .read(plantListProvider.notifier)
          .addPlant(plant, imageFile: addState.image);

      if (mounted) {
        showSuccessSnackbar(context, 'Planta salva no jardim!');
        context.go(AppRoutes.home);
      }
    } catch (e) {
      if (mounted) showErrorSnackbar(context, e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

// ─── Seção da foto ─────────────────────────────────────────────────────────

class _PhotoSection extends StatelessWidget {
  final File? image;
  final VoidCallback onPickImage;

  const _PhotoSection({required this.image, required this.onPickImage});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: image == null ? onPickImage : null,
      child: Container(
        height: 240,
        decoration: BoxDecoration(
          color: AppColors.accent.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.4),
            width: 1.5,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: image != null
            ? Stack(
                fit: StackFit.expand,
                children: [
                  Image.file(image!, fit: BoxFit.cover),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Material(
                      color: Colors.black54,
                      borderRadius: BorderRadius.circular(20),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(20),
                        onTap: onPickImage,
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.camera_alt,
                                size: 14,
                                color: Colors.white,
                              ),
                              SizedBox(width: 4),
                              Text(
                                'Trocar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              )
            : const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.camera_alt_outlined,
                    size: 64,
                    color: AppColors.primary,
                  ),
                  SizedBox(height: 12),
                  Text(
                    'Fotografe sua planta',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'A IA identifica e preenche tudo automaticamente',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

// ─── Loading card ──────────────────────────────────────────────────────────

class _LoadingCard extends StatelessWidget {
  final String label;
  const _LoadingCard({required this.label});

  @override
  Widget build(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        child: Row(
          children: [
            const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 14),
            Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

// ─── Error card ────────────────────────────────────────────────────────────

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.error.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
            ),
            TextButton(
              onPressed: onRetry,
              child: const Text(
                'Tentar novamente',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Album card ────────────────────────────────────────────────────────────

class _PlantAlbumCard extends StatelessWidget {
  final String name;
  final String? scientificName;
  final String? description;
  final String? location;
  final int waterDays;
  final int fertilizeDays;
  final bool isLoadingTips;
  final String? tipsError;
  final bool hasMultipleSuggestions;
  final VoidCallback? onViewSuggestions;
  final VoidCallback onEditName;
  final VoidCallback onEditLocation;
  final VoidCallback onEditWater;
  final VoidCallback onEditFertilize;
  final VoidCallback onRetryTips;

  const _PlantAlbumCard({
    required this.name,
    required this.scientificName,
    required this.description,
    required this.location,
    required this.waterDays,
    required this.fertilizeDays,
    required this.isLoadingTips,
    required this.tipsError,
    required this.hasMultipleSuggestions,
    required this.onViewSuggestions,
    required this.onEditName,
    required this.onEditLocation,
    required this.onEditWater,
    required this.onEditFertilize,
    required this.onRetryTips,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Badge "IA identificou"
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 13,
                        color: AppColors.primary,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Identificado pela IA',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (hasMultipleSuggestions) ...[
                  const Spacer(),
                  GestureDetector(
                    onTap: onViewSuggestions,
                    child: const Text(
                      'Outras sugestões →',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.primary,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // Nome + nome científico
            _EditableRow(
              onTap: onEditName,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name.isEmpty ? '—' : name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (scientificName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      scientificName!,
                      style: const TextStyle(
                        fontSize: 13,
                        fontStyle: FontStyle.italic,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Curiosidade / descrição
            if (description != null && description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🌿', style: TextStyle(fontSize: 18)),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.auto_awesome,
                                size: 13,
                                color: AppColors.primary,
                              ),
                              SizedBox(width: 5),
                              Text(
                                'Curiosidade gerada pelo Gemini',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            description!,
                            style: const TextStyle(
                              fontSize: 13,
                              height: 1.55,
                              fontStyle: FontStyle.italic,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 20),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Linhas de cuidado
            if (isLoadingTips)
              _LoadingCard(label: 'A IA está preparando as informações...')
            else if (tipsError != null)
              _TipsErrorBanner(message: tipsError!, onRetry: onRetryTips)
            else ...[
              _CareInfoRow(
                icon: '📍',
                label: 'Local ideal',
                value: location?.isEmpty == true || location == null
                    ? 'Toque para adicionar'
                    : location!,
                valueColor: location == null || location!.isEmpty
                    ? AppColors.textSecondary
                    : AppColors.textPrimary,
                onTap: onEditLocation,
              ),
              const SizedBox(height: 12),
              _CareInfoRow(
                icon: '💧',
                label: 'Regar',
                value: 'A cada $waterDays ${waterDays == 1 ? 'dia' : 'dias'}',
                onTap: onEditWater,
              ),
              const SizedBox(height: 12),
              _CareInfoRow(
                icon: '🌱',
                label: 'Adubar',
                value:
                    'A cada $fertilizeDays ${fertilizeDays == 1 ? 'dia' : 'dias'}',
                onTap: onEditFertilize,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Banner de erro Gemini com retry ──────────────────────────────────────

class _TipsErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _TipsErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.wifi_off_outlined,
            color: AppColors.warning,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message.contains('429') || message.contains('Limite')
                  ? 'Limite da API atingido. Aguarde alguns segundos e tente novamente.'
                  : message,
              style: const TextStyle(
                fontSize: 12,
                color: AppColors.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 32),
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
            child: const Text(
              'Tentar\nnovamente',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Linha de info editável ────────────────────────────────────────────────

class _CareInfoRow extends StatelessWidget {
  final String icon;
  final String label;
  final String value;
  final Color? valueColor;
  final VoidCallback onTap;

  const _CareInfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
        child: Row(
          children: [
            Text(icon, style: const TextStyle(fontSize: 20)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: valueColor ?? AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.edit_outlined,
              size: 16,
              color: AppColors.textSecondary,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Container editável (nome) ─────────────────────────────────────────────

class _EditableRow extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const _EditableRow({required this.child, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: child),
            const SizedBox(width: 8),
            const Padding(
              padding: EdgeInsets.only(top: 4),
              child: Icon(
                Icons.edit_outlined,
                size: 16,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

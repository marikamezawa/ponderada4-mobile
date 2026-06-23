import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/datasources/gemini_datasource.dart';
import '../../data/datasources/plant_id_api_datasource.dart';
import '../../data/models/plant_care_info.dart';
import '../../data/models/plant_id_response_model.dart';
import '../../core/errors/app_exception.dart';

class AddPlantState {
  final File? image;
  final PlantIdResponseModel? identification;
  final PlantIdSuggestion? selectedSuggestion;
  final bool isIdentifying;
  final String? identificationError;
  final PlantCareInfo? careInfo;
  final bool isLoadingTips;
  final String? tipsError;

  const AddPlantState({
    this.image,
    this.identification,
    this.selectedSuggestion,
    this.isIdentifying = false,
    this.identificationError,
    this.careInfo,
    this.isLoadingTips = false,
    this.tipsError,
  });

  PlantIdSuggestion? get activeSuggestion =>
      selectedSuggestion ?? identification?.bestMatch;

  AddPlantState copyWith({
    File? image,
    PlantIdResponseModel? identification,
    PlantIdSuggestion? selectedSuggestion,
    bool? isIdentifying,
    String? identificationError,
    PlantCareInfo? careInfo,
    bool? isLoadingTips,
    String? tipsError,
    bool clearTipsError = false,
    bool clearCareInfo = false,
  }) => AddPlantState(
    image: image ?? this.image,
    identification: identification ?? this.identification,
    selectedSuggestion: selectedSuggestion ?? this.selectedSuggestion,
    isIdentifying: isIdentifying ?? this.isIdentifying,
    identificationError: identificationError,
    careInfo: clearCareInfo ? null : (careInfo ?? this.careInfo),
    isLoadingTips: isLoadingTips ?? this.isLoadingTips,
    tipsError: clearTipsError ? null : (tipsError ?? this.tipsError),
  );
}

class AddPlantNotifier extends AutoDisposeNotifier<AddPlantState> {
  @override
  AddPlantState build() => const AddPlantState();

  void setImage(File image) {
    state = AddPlantState(image: image);
  }

  Future<void> identify() async {
    if (state.image == null) return;

    state = state.copyWith(isIdentifying: true);
    PlantIdResponseModel? result;
    try {
      result = await PlantIdApiDatasource().identifyPlant(state.image!);
      state = state.copyWith(identification: result, isIdentifying: false);
    } catch (e) {
      state = state.copyWith(
        isIdentifying: false,
        identificationError: e.toString().replaceFirst('Exception: ', ''),
      );
      return;
    }

    final best = result.bestMatch;
    if (best == null) return;
    await _fetchTips(scientificName: best.name, commonName: best.commonName);
  }

  Future<void> retryTips() async {
    final best = state.activeSuggestion;
    if (best == null) return;
    await _fetchTips(scientificName: best.name, commonName: best.commonName);
  }

  void selectSuggestion(PlantIdSuggestion suggestion) {
    state = state.copyWith(
      selectedSuggestion: suggestion,
      clearCareInfo: true,
      clearTipsError: true,
    );
    _fetchTips(
      scientificName: suggestion.name,
      commonName: suggestion.commonName,
    );
  }

  Future<void> _fetchTips({
    required String scientificName,
    String? commonName,
  }) async {
    state = state.copyWith(
      isLoadingTips: true,
      clearTipsError: true,
      clearCareInfo: true,
    );
    try {
      final info = await GeminiDatasource().getCareTips(
        scientificName: scientificName,
        commonName: commonName,
      );
      state = state.copyWith(careInfo: info, isLoadingTips: false);
    } catch (e) {
      state = state.copyWith(
        isLoadingTips: false,
        tipsError: e is AppException
            ? e.message
            : e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}

final addPlantProvider =
    AutoDisposeNotifierProvider<AddPlantNotifier, AddPlantState>(
      () => AddPlantNotifier(),
    );

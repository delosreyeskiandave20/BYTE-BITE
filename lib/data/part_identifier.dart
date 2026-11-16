import 'dart:convert';

import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/foundation.dart';

import 'parts_catalog.dart';

/// What the AI thinks a photographed part is.
@immutable
class PartIdentification {
  const PartIdentification({
    required this.isMotorcyclePart,
    required this.partName,
    required this.categoryId,
    required this.confidence,
    required this.description,
    required this.searchTerm,
  });

  factory PartIdentification.fromJson(Map<String, dynamic> json) {
    final category = json['categoryId'] as String? ?? 'other';
    return PartIdentification(
      isMotorcyclePart: json['isMotorcyclePart'] as bool? ?? false,
      partName: (json['partName'] as String? ?? '').trim(),
      categoryId: categoryNames.containsKey(category) ? category : 'other',
      confidence: json['confidence'] as String? ?? 'low',
      description: (json['description'] as String? ?? '').trim(),
      searchTerm: (json['searchTerm'] as String? ?? '').trim(),
    );
  }

  final bool isMotorcyclePart;
  final String partName;

  /// One of the keys of [categoryNames].
  final String categoryId;

  /// `high`, `medium`, or `low`.
  final String confidence;
  final String description;

  /// Short keyword to look the part up in the parts library and shops.
  final String searchTerm;

  String get categoryName => categoryNames[categoryId] ?? 'Other';
}

/// Thrown with a message that is safe to show to shoppers.
class PartIdentificationException implements Exception {
  const PartIdentificationException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Identifies the part in a photo. Injectable so tests can avoid the network.
typedef PartIdentifier =
    Future<PartIdentification> Function(Uint8List bytes, String mimeType);

/// Gemini model used for recognition. Override without code changes:
/// `flutter run --dart-define=GEMINI_MODEL=gemini-...`
const _geminiModel = String.fromEnvironment(
  'GEMINI_MODEL',
  defaultValue: 'gemini-3.5-flash-lite',
);

const _instructions =
    'You are a motorcycle parts expert for MotoScan, a motorcycle parts '
    'marketplace. Look at the photo and identify the single main motorcycle '
    'part or accessory shown. Use common English names a shop would use '
    '(for example "Brake caliper", "Air filter", "Side mirror"). If the photo '
    'does not show a motorcycle part, set isMotorcyclePart to false. Never '
    'guess a brand or model number you cannot see. Keep description to one '
    'or two short sentences about what the part does.';

/// Calls Gemini through Firebase AI Logic (Gemini Developer API, free tier).
/// Firebase holds the API key server-side, and App Check protects it.
class GeminiPartIdentifier {
  GeminiPartIdentifier()
    : _model = FirebaseAI.googleAI().generativeModel(
        model: _geminiModel,
        systemInstruction: Content.system(_instructions),
        generationConfig: GenerationConfig(
          responseMimeType: 'application/json',
          responseSchema: Schema.object(
            properties: {
              'isMotorcyclePart': Schema.boolean(),
              'partName': Schema.string(
                description: 'Common name of the part, e.g. "Brake caliper".',
              ),
              'categoryId': Schema.enumString(
                enumValues: categoryNames.keys.toList(),
              ),
              'confidence': Schema.enumString(
                enumValues: ['high', 'medium', 'low'],
              ),
              'description': Schema.string(),
              'searchTerm': Schema.string(
                description:
                    'One or two keywords for searching a parts catalog, '
                    'e.g. "Brake" or "Air filter".',
              ),
            },
            propertyOrdering: [
              'isMotorcyclePart',
              'partName',
              'categoryId',
              'confidence',
              'description',
              'searchTerm',
            ],
          ),
        ),
      );

  final GenerativeModel _model;

  Future<PartIdentification> call(Uint8List bytes, String mimeType) async {
    final GenerateContentResponse response;
    try {
      response = await _model
          .generateContent([
            Content.multi([
              const TextPart('Identify the motorcycle part in this photo.'),
              InlineDataPart(mimeType, bytes),
            ]),
          ])
          .timeout(const Duration(seconds: 45));
    } on QuotaExceeded {
      throw const PartIdentificationException(
        'The free AI limit was reached for now. Please try again later.',
      );
    } on FirebaseAIException catch (error) {
      debugPrint('Gemini request failed: $error');
      final details = error.toString();
      if (kDebugMode &&
          (details.contains('SERVICE_DISABLED') ||
              details.contains('has not been used'))) {
        throw const PartIdentificationException(
          'Firebase AI Logic is not enabled for this Firebase project. '
          'Open Firebase console > AI Logic > Get started, choose the '
          'Gemini Developer API, then try again.',
        );
      }
      if (kDebugMode && details.contains('not found')) {
        throw PartIdentificationException(
          'Gemini model "$_geminiModel" was not found. Run with '
          '--dart-define=GEMINI_MODEL=<a valid model name>.',
        );
      }
      throw const PartIdentificationException(
        'The AI service is unavailable right now. Please try again.',
      );
    } catch (error) {
      debugPrint('Gemini request failed: $error');
      throw const PartIdentificationException(
        'Could not reach the AI service. Check your connection and try again.',
      );
    }

    final text = response.text;
    if (text == null || text.trim().isEmpty) {
      throw const PartIdentificationException(
        'The AI could not read this photo. Try a clearer shot.',
      );
    }
    try {
      return PartIdentification.fromJson(
        jsonDecode(text) as Map<String, dynamic>,
      );
    } catch (error) {
      debugPrint('Unexpected Gemini response: $text');
      throw const PartIdentificationException(
        'The AI gave an unexpected answer. Please try again.',
      );
    }
  }
}

import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/journal_entry.dart';
import '../models/ai_insights.dart';

/// Service for generating AI insights using Google's Gemini API
class GeminiService {
  static GeminiService? _instance;
  GenerativeModel? _model;
  bool _initialized = false;
  String? _initializationError;

  GeminiService._();

  static GeminiService get instance {
    _instance ??= GeminiService._();
    return _instance!;
  }

  /// Initialize the Gemini model with API key
  Future<void> initialize() async {
    if (_initialized) return;

    try {
      // Try to load .env file, but don't fail if it doesn't exist
      // dotenv may already be loaded from main.dart, so check first
      final apiKey = dotenv.env['GEMINI_API_KEY'];

      if (apiKey == null || apiKey.isEmpty) {
        print('⚠️ Gemini API key not configured');
        _initializationError =
            'Gemini API key not found. Add GEMINI_API_KEY to your .env file.';
        return;
      }

      if (apiKey == 'your_gemini_api_key_here') {
        print('⚠️ Gemini API key is placeholder');
        _initializationError =
            'Please replace the placeholder API key with your actual Gemini API key in .env file.';
        return;
      }

      _model = GenerativeModel(
        model: 'gemini-3-flash-preview',
        apiKey: apiKey,
        generationConfig: GenerationConfig(
          temperature: 0.7,
          maxOutputTokens: 4096,
          responseMimeType: 'application/json',
        ),
      );

      _initialized = true;
      _initializationError = null;
      print('✅ Gemini service initialized');
    } catch (e) {
      print('❌ Failed to initialize Gemini service: $e');
      _initializationError = 'Failed to initialize AI service: $e';
    }
  }

  /// Check if service is ready
  bool get isAvailable => _initialized && _model != null;

  /// Get the initialization error message (if any)
  String? get errorMessage => _initializationError;

  /// Generate insights from journal entries
  Future<AIInsights?> generateInsights(List<JournalEntry> entries) async {
    if (!isAvailable) {
      print('⚠️ Gemini service not available');
      return null;
    }

    if (entries.length < kMinEntriesForInsights) {
      print(
          '⚠️ Not enough entries for insights (need $kMinEntriesForInsights)');
      return null;
    }

    try {
      final prompt = _buildPrompt(entries);
      final content = [Content.text(prompt)];
      final response = await _model!.generateContent(content);

      if (response.text == null) {
        print('❌ Empty response from Gemini');
        return null;
      }

      return _parseResponse(response.text!, entries.length);
    } catch (e) {
      print('❌ Error generating insights: $e');
      return null;
    }
  }

  /// Build the prompt for Gemini
  String _buildPrompt(List<JournalEntry> entries) {
    final entriesJson = entries
        .map((e) => {
              'timestamp': e.timestamp.toIso8601String(),
              'event_type': e.eventType.value,
              'trigger': e.triggerType ?? 'unspecified',
              'intensity': e.intensityLevel,
              'emotional_state': e.emotionalState ?? 'not recorded',
              'location': e.location ?? 'not recorded',
              'companions': e.companions ?? 'not recorded',
              'activity': e.activity ?? 'not recorded',
              'notes': e.notes ?? '',
              'was_resisted': e.wasResisted,
            })
        .toList();

    return '''
You are analyzing smoking cessation journal entries for a user trying to quit smoking.
Analyze the following entries and provide actionable insights to help them succeed.

Journal Entries:
${jsonEncode(entriesJson)}

Analyze these entries and provide insights in the following JSON format exactly:
{
  "summary": "A brief 2-3 sentence personalized summary of their patterns",
  "top_triggers": [
    {"trigger": "trigger name", "count": number, "percentage": decimal 0-1}
  ],
  "time_patterns": [
    {"time_of_day": "morning|afternoon|evening|night", "count": number, "percentage": decimal 0-1, "insight": "brief insight about this time pattern"}
  ],
  "emotional_patterns": [
    {"emotion": "emotion name", "count": number, "percentage": decimal 0-1, "coping_strategy": "suggested coping strategy"}
  ],
  "recommendations": [
    "Specific, actionable recommendation 1",
    "Specific, actionable recommendation 2",
    "Specific, actionable recommendation 3"
  ]
}

Rules:
1. Only include triggers/patterns that actually appear in the data
2. Percentages should sum to roughly 1.0 within each category
3. Keep recommendations specific, compassionate, and actionable
4. Focus on patterns that can help the user prevent future relapses
5. If data is limited, still provide helpful insights based on what's available
6. Be encouraging while being honest about challenges

Return ONLY the JSON object, no additional text or markdown.
''';
  }

  /// Parse Gemini response into AIInsights
  AIInsights? _parseResponse(String responseText, int entriesAnalyzed) {
    try {
      // Clean up response - remove markdown code blocks if present
      var cleanedResponse = responseText.trim();
      if (cleanedResponse.startsWith('```json')) {
        cleanedResponse = cleanedResponse.substring(7);
      }
      if (cleanedResponse.startsWith('```')) {
        cleanedResponse = cleanedResponse.substring(3);
      }
      if (cleanedResponse.endsWith('```')) {
        cleanedResponse =
            cleanedResponse.substring(0, cleanedResponse.length - 3);
      }
      cleanedResponse = cleanedResponse.trim();

      final json = jsonDecode(cleanedResponse) as Map<String, dynamic>;

      final topTriggers = (json['top_triggers'] as List<dynamic>?)
              ?.map((e) => TriggerPattern.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [];

      final timePatterns = (json['time_patterns'] as List<dynamic>?)
              ?.map((e) => TimePattern.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [];

      final emotionalPatterns = (json['emotional_patterns'] as List<dynamic>?)
              ?.map((e) => EmotionalPattern.fromMap(e as Map<String, dynamic>))
              .toList() ??
          [];

      final recommendations = (json['recommendations'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [];

      return AIInsights(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        generatedAt: DateTime.now(),
        journalEntriesAnalyzed: entriesAnalyzed,
        topTriggers: topTriggers,
        timePatterns: timePatterns,
        emotionalPatterns: emotionalPatterns,
        recommendations: recommendations,
        summary: json['summary'] as String?,
      );
    } catch (e) {
      print('❌ Error parsing Gemini response: $e');
      print('Raw response: $responseText');
      return null;
    }
  }
}

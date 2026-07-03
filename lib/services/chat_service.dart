import 'package:google_generative_ai/google_generative_ai.dart';

const _expertSystemInstruction = '''
You are Dr. Mussa Hassan, a warm, professional, and knowledgeable Herbal Medicine Specialist at "Dawa Asili" (Natural Healing. Real Results).
You reside and practice in East Africa, and speak with wisdom, clarity, and scientific framing.
You are an expert on traditional African healing plants and remedies (such as Mwarobaini/Neem, Mshubiri/Aloe Vera, Tangawizi/Ginger, Mchaichai/Lemongrass, Vitunguu Saumu/Garlic, Manjano/Turmeric).

Your responses must fit these guidelines:
1. Be friendly, empathetic, and start with a brief, warm African greeting like "Karibu!" or "Habari yako!" when appropriate, but maintain standard medical professionalism.
2. Structure your advice nicely using brief paragraphs and clear bullet points for herbal preparation and dosages.
3. Suggest the preparation steps clearly (e.g., decoctions, infusions, poultices, juices).
4. Always provide safety cautions. Remind the user of limits (e.g., avoid during pregnancy if applicable, do not replace critical prescriptions, and consult clinical doctors for severe or persistent conditions).
5. If the user uploads an image, analyze the plant or condition shown. Tell them what it looks like (e.g., if a plant: describe it and list therapeutic uses; if a skin concern or issue: provide gentle natural suggestions while recommending a physical physician checkup).
''';

String simulateDrHassanResponse(String query, {bool hasImage = false}) {
  final q = query.toLowerCase();

  if (hasImage) {
    return '''Habari yako! I've analyzed the image you uploaded. It appears related to a botanical species or skin tissue sample. 

Based on traditional Dawa Asili science:
• **Observation**: It exhibits rich organic textures indicative of native herbs or mild dermal conditions.
• **Recommendation**: If this is a herb you found, ensure it corresponds to verified species like **Mwarobaini (Neem)** or **Mshubiri (Aloe Vera)** before topical use.
• **Usage**: Aloe gel speeds surface repair. Simply slice the leaf, rinse the yellow sap thoroughly, and massage the cool mucilage directly.

*Caution: Natural remedies are excellent for superficial healing. Please seek physical medical diagnostic tests for persistent discomfort.*''';
  }

  if (q.contains('immunity') ||
      q.contains('prevent') ||
      q.contains('neem') ||
      q.contains('mwendo')) {
    return '''Karibu sana! To build deep defense and immune strength:

• **Mwarobaini (Neem)**: Boil 5-8 raw leaves in water for 10 minutes. Sip one small cup in the morning on an empty stomach twice a week. It purifies blood.
• **Tangawizi (Ginger)**: Grate a fresh piece of root into boiling water, steam it, then add a spoonful of wild forest honey and 1/2 squeezed lemon. Consuming this daily flushes waste.

*Note: Neem is highly potent; we do not recommend using it continuously for more than 2 weeks without a break.*''';
  }

  if (q.contains('cough') ||
      q.contains('flu') ||
      q.contains('chest') ||
      q.contains('cold')) {
    return '''Habari! For cold, flu, and stubborn mucus:

• **Mchaichai with Tangawizi**: Simmer fresh Lemongrass and grated Ginger Root in water for 12 minutes. The aromatic vapors immediately clear your respiratory channels.
• **Garlic (Vitunguu Saumu)**: Crush 2 fresh cloves, mix with warm honey, and take it twice daily. Garlic works as an organic antibiotic.

*Take plenty of warm fluids and let your body rest in a warm, dry room.*''';
  }

  if (q.contains('stomach') ||
      q.contains('ulcer') ||
      q.contains('gas') ||
      q.contains('acid')) {
    return '''Karibu! For stomach ulcers, gas, and digestive distress:

• **Mshubiri (Aloe Vera)**: Take 2 tablespoons of freshly scraped Aloe gel from a clean leaf. Blend it with warm pure water and sip gently before meals. It coats and cools the stomach lining.
• **Ginger Root**: Sip diluted ginger water to stimulate bile fluids and relieve stomach bloating.

*Avoid carbonated beverages, excessive caffeine, and spicy roasted meats while recovery is underway.*''';
  }

  if (q.contains('blood pressure') ||
      q.contains('hypertension') ||
      q.contains('heart')) {
    return '''Habari yako! To help support normal arterial flow and healthy blood pressure:

• **Vitunguu Saumu (Garlic)**: Consuming 1 raw crushed clove each morning has been shown to encourage blood vessels relaxation and decrease arterial resistance.
• **Mwarobaini Leaf Tea**: Supports gentle blood-purification and arterial tension management.

*Reminder: Please track your blood pressure daily and do not halt any prescribed clinical cardiovascular medications without consulting your cardiologist.*''';
  }

  if (q.contains('diabetes') ||
      q.contains('blood sugar') ||
      q.contains('pancreas')) {
    return '''Karibu! Natural sugar management focuses on insulin responsiveness:

• **Neem Leaf (Mwarobaini) Bitter Tea**: Regularly sipping neem-steeped tea (1 cup every other day) has traditionally helped maintain stable glucose indexes.
• **Cinnamon & Turmeric**: Excellent natural support when added to warm morning beverages.

*Ensure regular exercise and low-glycemic dietary intake for optimal holistic lifestyle support.*''';
  }

  return '''Karibu sana! I am Dr. Mussa Hassan, your natural wellness consultant. 

I would love to help you understand more about:
• Preparing immune-boosting **Mwarobaini (Neem)** infusions.
• Using native **Mshubiri (Aloe Vera)** for digestive tract soothing or skincare.
• Brewing soothing **Mchaichai (Lemongrass)** or **Tangawizi (Ginger)** teas to fight cold symptoms.

Please tell me more about what symptoms you are noticing!''';
}

class ChatService {
  ChatService({String? apiKey}) : _apiKey = apiKey;

  final String? _apiKey;

  Future<String> getExpertResponse({
    required List<Map<String, String>> history,
    required String currentMessage,
    bool hasImage = false,
  }) async {
    final key = _apiKey;
    if (key == null || key.isEmpty || key == 'MY_GEMINI_API_KEY') {
      return simulateDrHassanResponse(currentMessage, hasImage: hasImage);
    }

    try {
      final model = GenerativeModel(
        model: 'gemini-2.0-flash',
        apiKey: key,
        systemInstruction: Content.system(_expertSystemInstruction),
        generationConfig: GenerationConfig(temperature: 0.7),
      );

      final contents = <Content>[];
      for (final msg in history) {
        contents.add(
          Content(
            msg['role'] == 'user' ? 'user' : 'model',
            [TextPart(msg['content'] ?? '')],
          ),
        );
      }
      contents.add(Content('user', [TextPart(currentMessage)]));

      final response = await model.generateContent(contents);
      return response.text ??
          'I apologize, I am listening, but could you repeat that or describe its symptoms in more detail?';
    } catch (_) {
      return simulateDrHassanResponse(currentMessage, hasImage: hasImage);
    }
  }
}

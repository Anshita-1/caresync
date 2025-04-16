import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ChatGPTService {
  static const String _baseUrl = "https://api.openai.com/v1/chat/completions";

  /// Sends [message] (e.g. symptoms) to OpenAI, with a system prompt
  /// telling it to behave like a medical assistant.
  static Future<String?> sendMessage(String message) async {
    final apiKey = dotenv.env["OPENAI_API_KEY"];
    if (apiKey == null) {
      throw Exception("OPENAI_API_KEY not set in .env");
    }

    final url = Uri.parse(_baseUrl);
    final payload = {
      "model": "gpt-3.5-turbo",
      "temperature": 0.7,
      "messages": [
        {
          "role": "system",
          "content": "You are a helpful medical assistant. "
              "When given symptoms, suggest possible conditions and basic home-care tips."
        },
        {
          "role": "user",
          "content": message
        }
      ]
    };

    try {
      final res = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(payload),
      );

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        return (data["choices"] as List)[0]["message"]["content"].trim();
      } else {
        debugPrint("ChatGPT API error (${res.statusCode}): ${res.body}");
        return "Sorry, I couldn't get a response right now.";
      }
    } catch (e) {
      debugPrint("ChatGPTService exception: $e");
      return "Error: network or server issue.";
    }
  }
}

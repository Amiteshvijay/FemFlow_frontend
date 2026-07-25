enum FemAIConversationState {
  idle,
  listening,
  transcribing,
  thinking,
  speaking,
  error,
  ended,
}

extension FemAIConversationStateX on FemAIConversationState {
  String getStatusMessage(String languageCode) {
    final isHindi = languageCode.startsWith('hi');

    switch (this) {
      case FemAIConversationState.idle:
        return isHindi ? "बोलने के लिए माइक दबाएं" : "Tap to speak";
      case FemAIConversationState.listening:
        return isHindi ? "सुन रहा हूँ... अपना सवाल बोलिए" : "Listening... Speak naturally";
      case FemAIConversationState.transcribing:
        return isHindi ? "आपके सवाल को समझा जा रहा है..." : "Understanding your question...";
      case FemAIConversationState.thinking:
        return isHindi ? "FemAI सोच रही है..." : "FemAI is thinking...";
      case FemAIConversationState.speaking:
        return isHindi ? "FemAI जवाब दे रही है..." : "FemAI is speaking...";
      case FemAIConversationState.error:
        return isHindi ? "कुछ समस्या हुई। पुनः प्रयास करें।" : "Something went wrong. Tap to try again.";
      case FemAIConversationState.ended:
        return isHindi ? "बातचीत समाप्त हो गई" : "Conversation ended";
    }
  }

  bool get isActive =>
      this != FemAIConversationState.idle &&
      this != FemAIConversationState.ended &&
      this != FemAIConversationState.error;
}

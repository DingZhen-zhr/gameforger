import '../../../features/workspace/domain/game_spec.dart';
import '../game_design_document.dart';
import '../playability/genre_validator.dart';

/// Abstract template for a game genre.
/// Each template provides genre-specific prompts, code skeletons, and
/// validation rules for the two-pass generation pipeline.
abstract class GameTemplate {
  String get genreName;
  String get genreNameCN;

  /// System prompt for Pass 1 (design document generation).
  String buildDesignPrompt(GameSpec spec);

  /// HTML5 code skeleton for Pass 2 (code generation).
  /// Injected as the structural pattern the AI should follow.
  String get codeSkeleton;

  /// Elements that MUST be present in the generated code for this genre.
  List<String> get requiredCodeElements;

  /// Default physics params for this genre.
  Map<String, double> get defaultPhysics;

  /// Additional constraints for code generation (appended to prompt).
  List<String> getCodeGenConstraints(GameDesignDocument doc);

  /// Genre-specific playability validator for design + code phases.
  /// Each template returns its own validator so new genres are self-contained.
  GenrePlayabilityValidator get playabilityValidator;

  /// Suggested max tokens for code generation.
  int get suggestedMaxTokens => 8192;
}

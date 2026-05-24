import '../game_design_document.dart';
import '../playability_validator.dart';

/// Per-genre playability validator interface.
///
/// Each game genre implements its own validation logic for both design-document
/// and generated-code phases. The [PlayabilityValidator] dispatcher calls these
/// after running universal checks (game loop, controls, canvas, etc.).
///
/// To add a new genre:
/// 1. Implement this interface with genre-specific checks
/// 2. Override [GameTemplate.playabilityValidator] to return an instance
/// 3. The dispatcher picks it up automatically — no other changes needed
abstract class GenrePlayabilityValidator {
  /// Machine-readable genre name (e.g. "Platformer", "Shooter").
  String get genreName;

  /// Validates a [GameDesignDocument] for genre-specific playability issues.
  /// Called during Pass 1 (design generation).
  PlayabilityResult validateDesign(GameDesignDocument doc);

  /// Validates generated HTML/JS for genre-specific playability issues.
  /// Called during Pass 2 (code generation).
  PlayabilityResult validateCode(String html);
}

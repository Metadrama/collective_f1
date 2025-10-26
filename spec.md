# Collective Product Specification

## Document Purpose
This specification captures the current intent, behavior, and technical shape of the Collective journaling application. It translates feature ideas into concrete requirements so designers, engineers, testers, and stakeholders share the same mental model.

## Product Summary
Collective is a minimalist journaling companion that preserves the calm of pen-and-paper while layering in helpful automation. Users focus on one entry at a time, swipe to save, and let background intelligence organize, surface, and interpret their writing. The app is built with Flutter and ships to iOS, Android, macOS, Windows, Linux, and web targets. Core services sit on Firebase (Auth, Firestore, Storage) with local-first persistence and Deepseek AI-powered summarization and analytics.

## Goals
- **Lower the activation energy** for daily journaling by presenting a single low-friction input surface.
- **Keep the experience grounded** in a paper-like flow while adding quiet digital conveniences (search, tags, media attachments).
- **Deliver contextual insights** through AI that feel personal and actionable, not generic self-help.
- **Handle data responsibly** with offline-first resilience, background sync, and user-controlled content management.

## Non-Goals
- Real-time collaborative editing.
- Public sharing or social feeds.
- Long-form publishing tooling (formatting, layout, exporting books).
- Therapist or clinician dashboards.

## Target Personas
- **Reflective Achiever**: tracks personal growth, habits, and goals; leans on insights to identify patterns.
- **Emotional Processer**: uses writing to make sense of feelings; wants to revisit moods and related experiences.
- **Memory Keeper**: records day-to-day highlights with photos or short videos; values quick retrieval of favorites.

## Key User Journeys
1. **Capture a new entry**
   - Open app → focus lands in editor → type text, optionally set mood, attach tags or media → swipe upward to save → entry animates into timeline.
2. **Review past writing**
   - Scroll chronological stack grouped by date → long-press to multi-select for delete → tap star to favorite → tap entry to view full content with attachments.
3. **Generate insight**
   - From entry → tap insight icon → app fetches related entries → Deepseek streams a contextual summary paragraph.
4. **Explore analytics**
   - Open Analytics hub → see progress indicator → once ready, browse topic clusters with emoji, description, timeline, and linked entries.
5. **Search and filter**
   - Toggle search → type free text → fuzzy match across entry text and tags → results update live. Calendar modal allows jumping to specific dates.
6. **Offline capture**
   - Write entry with or without media while offline → Sembast stores locally with `isSynced=false` → when connectivity returns, background sync pushes to Firestore/Storage and updates status pill.

## Functional Requirements
### Authentication
- User signs in via Firebase Auth (email/password and social providers handled in authentication screen; outside this spec).
- Authentication state gates entry loading, analytics, and AI calls.

### Entry Management
- Create entry containing: free-form text, optional mood, manual tags, optional image or 5-second GIF, word count.
- Swipe-to-save gesture triggers validation (non-empty text or attachment) and persists entry locally then remotely.
- Entries display in reverse chronological order, grouped by formatted day labels.
- Edit existing entry from detail surface; persist updates in Firestore and local cache.
- Delete entries individually or via multi-select; confirm before permanent removal.
- Toggle favorite flag; favorites list accessible from toolbar.

### Media Capture
- Support image selection from gallery.
- Long-press capture button to record 5-second video clip converted to GIF via ffmpeg kit.
- Store media in Firebase Storage when online; persist local file path for offline use.

### Tagging & Mood
- Manual tag input component enforces lowercase `#tag` format; avoid duplicates.
- Suggested tags fetched from Deepseek `suggestTags` endpoint; user may accept or ignore.
- Mood picker (emoji or label) persists alongside entry.

### Search & Organization
- Fuzzy search across entry text and tags with incremental updates.
- Date grouping and sticky headers for scroll list.
- Calendar modal surfaces days containing entries and scrolls list when date tapped.
- Favorites screen shows starred entries with same interactions as main list.

### Insights (Deepseek)
- `fetchRelatedEntriesFromDeepseek` chooses 3-5 relevant entries per main entry.
- `generateBriefInsight` or streaming variant produces a concise paragraph summarizing context.
- Legacy endpoints `analyzeEntryContext` and `generateOverallInsights` remain for backward compatibility but are marked deprecated.
- AI failures fall back to heuristic summaries to ensure UX continuity.

#### Media awareness
- When entries include an image or GIF, the app uses Google Cloud Vision to derive concise media descriptions (labels and short OCR text), cached per entry.
- These descriptions are appended to the AI prompt so Deepseek can incorporate visual context into insights.

### Analytics Hub
- Trigger analysis request on screen load; show progress states.
- Filter out trivial entries (<10 characters, mainly numbers/URLs).
- Deepseek identifies 3-7 topic clusters; fallback keyword clustering if AI fails.
- Cache topic data per user per session using SharedPreferences (6-hour expiry) plus in-memory cache map.
- Topic detail view displays emoji, description, confidence, timeline, and linked entries with quick navigation.
- Pull-to-refresh forces re-analysis and cache invalidation.

### Offline & Sync Layer
- Persist entries locally with Sembast DB: schema caches text, metadata, sync flags, local media path.
- Monitor connectivity via `connectivity_plus`; update status pill (offline/syncing/synced/error).
- When online, push unsynced entries to Firestore/Storage, replace `localId` with Firestore doc ID, update local store, and set `isSynced=true`.
- Handle conflicts by preferring latest timestamp and updating local copy with server data.

### Notifications & Feedback
- Growth ripple animation plays on save to reinforce success.
- Progress indicator bar at bottom shows swipe distance relative to threshold.
- Indeterminate progress bar appears while syncing.
- Errors surface via `debugPrint` today; future enhancement to add unobtrusive toast/banner messaging.

## Non-Functional Requirements
- **Availability**: core journaling usable offline with eventual consistency when connectivity restored.
- **Performance**: initial load under 3 seconds on mid-tier mobile hardware; list scrolling at 60fps with lazy animations.
- **Security**: API keys resolved at runtime via `ApiKeyService`; never hard-code secrets in repo. Firebase rules restrict access per authenticated user.
- **Privacy**: entries remain private to the author; no transmissions beyond Firebase and Deepseek endpoints. Provide clear consent for AI processing (future settings toggle).
- **Accessibility**: text scalable with system font settings; color choices meet WCAG AA for text on backgrounds.

## System Architecture Overview
```
Flutter UI (Screens, Widgets)
  └─ Controllers (e.g., JournalController)
      ├─ Local Persistence (Sembast DB)
      ├─ Sync Services (Firestore, Storage)
      ├─ Media Utilities (Camera, Image Picker, FFmpeg)
      └─ AI Services (Deepseek via http)

Background Services
  ├─ AnalyticsService (topic clustering)
  └─ DeepseekService (insights, related entries, tags)

Shared Utilities
  ├─ Date formatting, animations, mood mapping
  └─ API key management, system UI helpers
```

## Data Model Highlights
### Entry
- `localId` (string)
- `firestoreId` (string?)
- `text` (string)
- `timestamp` (formatted string)
- `rawDateTime` (DateTime)
- `mood` (string?)
- `tags` (List<String>)
- `wordCount` (int)
- `imageUrl` (string?)
- `localImagePath` (string?)
- `isFavorite` (bool)
- `isSynced` (bool)
- `animController` (runtime only)

### TopicCluster (derived)
- `id`, `name`, `description`
- `emoji`
- `entries` (List<Entry>)
- `confidence` (double 0..1)
- `firstEntryDate`, `lastEntryDate`

## External Integrations
- **Firebase Auth**: user identity and session management.
- **Cloud Firestore**: primary source of truth for entries.
- **Firebase Storage**: image and GIF assets per user bucket.
- **Deepseek API**: hosted at `https://api.deepseek.com/v1/chat/completions`; used for insights, related entries, tag suggestions, and analytics topic extraction.
- **SharedPreferences**: lightweight cache for analytics results.
- **FFmpeg Kit**: local video-to-GIF conversion.
 - **Google Cloud Vision**: `images:annotate` for label + OCR signals to enrich AI prompts (optional; enabled when API key is configured).

## Error Handling & Fallbacks
- If Deepseek calls fail, services return heuristic results or empty arrays while logging `debugPrint` message.
- If Firestore sync fails, mark `SyncStatus.error` and fall back to local DB for reads.
- If media upload fails online, keep local path for retry and show sync badge once success.
- Streaming insight fallback requests non-streaming paragraph to avoid broken UX.

## Telemetry & Logging
- Current implementation uses `debugPrint` for diagnostic traces. Future telemetry tasks:
  - Add structured logging with log levels.
  - Emit anonymized analytics events (screen views, feature adoption) respecting privacy settings.

## Testing Strategy
- **Unit Tests**: models, utilities, and AI formatter helpers.
- **Widget Tests**: journal list, entry input, analytics cards.
- **Integration Tests**: offline/online sync flows, media capture pipeline, Deepseek API contract tests (mocked/stubbed).
- **Manual QA**: verify swipe-to-save, search accuracy, topic clustering UX, attachment playback, platform-specific edges.

## Release Criteria
- No critical or high-severity defects open.
- Automated test suite passes on all target platforms.
- Manual regression on latest iOS and Android versions.
- API keys managed securely with document updates in `api_key_service.dart`.
- App Store / Play submission assets prepared (icon, screenshots handled elsewhere).

## Future Enhancements
- AI coaching timeline with prompt suggestions tailored to detected themes.
- Export entries (PDF, Markdown, JSON) with privacy controls.
- Calendar heatmap visualization for streak tracking.
- Mood trendline charts and custom tag metrics in analytics.
- Configurable AI usage toggle and data retention policy UI.

## Open Questions
- Should users control per-entry AI analysis (opt-out toggle)?
- How to communicate AI usage and privacy within onboarding?
- Do we need multi-device conflict resolution beyond latest-write-wins?
- Should manual tagging and AI-suggested tags be visually distinguishable?

// ◆───────────────────────────────────────────────────────────────────◆
// │  Milestones — Developer Notes                                     │
// │  Because your life isn't one moment — it's all of them.           │
// ◆───────────────────────────────────────────────────────────────────◆
//
// MARK: - Project Setup (from Xcode project creation — APR 01 2026)
//
//  Product Name:               Milestones
//  Team:                       Michael Fluharty
//  Organization Identifier:    com.inkwell
//  Bundle Identifier:          com.inkwell.Milestones
//  Testing System:             Swift Testing with XCTest UI Tests
//  Storage:                    SwiftData
//  Host in CloudKit:           Yes
//  Source Control:              Git (local + GitHub)
//  Platforms:                  Universal (iPhone, iPad, Mac)
//  Minimum Targets:            iOS 17 / iPadOS 17 / macOS 14 Sonoma
//  Floor Rationale:            SwiftData, WeatherKit historical weather, ShazamKit, JournalingSuggestions
//
// MARK: - GitHub Repository
//
//  Owner:          fluhartyml
//  Repo:           Milestones
//  Visibility:     Public
//  URL:            https://github.com/fluhartyml/Milestones.git
//  Description:    "Milestones; Because your life isn't one moment — it's all of them."
//  Wiki:           https://github.com/fluhartyml/Milestones/wiki (created, Home page initialized)
//  License:        GPL v3 — Share and share alike with attribution required
//
// MARK: - Frameworks Required
//
//  WeatherKit         — Current + historical weather (back to 1970s), auto-tagged on every entry
//  ShazamKit          — Song identification (v1.1)
//  MusicKit           — Playback of Shazam-identified songs (v1.1)
//  HealthKit          — Steps, heart rate, activity, workout type (v1.1)
//  CoreLocation       — Geotag + timestamp every entry
//  CoreMotion         — Accelerometer, gyroscope for vestibular sense (v1.1)
//  SwiftData          — Local persistence, CloudKit sync
//  CloudKit           — iCloud sync (enabled at project creation)
//  PhotosUI           — PHPickerViewController for camera roll access
//  EventKit           — iCal integration for holidays + contact birthdays (v1.4)
//  QuickLook          — PDF inline previews (v1.2)
//  JournalingSuggestions — Apple's journaling suggestions API (v1.4)
//
// MARK: - App Services Required (developer.apple.com, not Xcode)
//
//  MusicKit           — App Services portal
//  WeatherKit         — App Services portal
//  ShazamKit          — App Services portal
//
// MARK: - Versioned Roadmap
//
//  v1.0 — The Journal (MVP)
//      Ship a working sensory journal with weather and the index.
//
//      1.0.1   Every entry stamped YYYY MMM DD HHMM Title/Description — no exceptions
//      1.0.2   Timestamp is the arbiter of truth — primary sort, search, navigation
//      1.0.3   User writes title/description, chooses date — past, present, or future
//      1.0.4   Sight — attach photo from camera or photo album
//      1.0.5   Smell — text field, optional photo
//      1.0.6   Taste — text field, optional food photo
//      1.0.7   Touch — text field describing texture/sensation
//      1.0.8   WeatherKit — auto-tag current conditions on every new entry
//      1.0.9   WeatherKit — pull historical weather for past-date entries
//      1.0.10  CoreLocation — geotag and timestamp every entry
//      1.0.11  Front of journal — chronological timeline of all entries
//      1.0.12  The Index — user's life timeline of significant dates
//      1.0.13  Index — add/edit/remove dates anytime, no lockdown
//      1.0.14  Index — app suggests a few dates to get started (birthday, today)
//      1.0.15  Index — tap entry → see historical weather for that date/location
//      1.0.16  Index — tap "Write about this" → journal entry pre-filled with weather and date
//      1.0.17  Index is a live growing document, not onboarding
//      1.0.18  Promote any journal entry to a milestone in the index
//      1.0.19  Navigation — front (timeline), back (index)
//
//  v1.1 — Sound & Senses
//      Add ShazamKit, hearing, and HealthKit integration.
//
//      1.1.1   Hearing — ShazamKit song identification, auto-creates entry
//      1.1.2   Hearing — ambient sound level (dB) logged
//      1.1.3   Songs — Shazam-identified, playable from entry
//      1.1.4   Touch — auto-log temperature from WeatherKit
//      1.1.5   Vestibular — auto-log movement/steps/activity from HealthKit
//      1.1.6   Proprioception — auto-log workout type, heart rate, body state from HealthKit
//      1.1.7   HealthKit — steps, heart rate, activity (Apple Watch)
//      1.1.8   HealthKit as an entry source
//      1.1.9   HealthKit data as content type in entries
//
//  v1.2 — Share Sheet & Content
//      The app lives beyond itself — capture from anywhere.
//
//      1.2.1   Share sheet extension — receive from Safari (images, highlighted text, URLs, titles)
//      1.2.2   Share sheet — receive from Photos with EXIF date/location
//      1.2.3   Share sheet — receive from any app sharing images or text
//      1.2.4   Share sheet — auto-capture image, text, URL, page title, date (EXIF or today)
//      1.2.5   Share sheet — prompt for title/description and real date if historical
//      1.2.6   Photos — attach from camera roll, EXIF date extracted
//      1.2.7   News clippings/articles via share sheet
//      1.2.8   Obituaries, announcements, documents via share sheet
//      1.2.9   PDF files with inline previews
//
//  v1.3 — The Time Machine
//      Navigate your life visually.
//
//      1.3.1   Time machine — navigate to any date in the user's life
//      1.3.2   Time machine — guided by the date field on journal entries
//      1.3.3   Historical weather pulled for any date navigated to
//      1.3.4   Index milestones appear as bookmarks on the timeline
//      1.3.5   Icon/glyph/emoji picker for milestone markers
//      1.3.6   UI — dial/slider/tuner to spin through time
//      1.3.7   Navigation — time machine as third navigation path
//
//  v1.4 — Life Integration
//      Calendar, anniversaries, auto-entries, and logging.
//
//      1.4.1   iCal integration — import holidays and contact birthdays as suggested milestones
//      1.4.2   Auto-log weather on indexed milestone anniversary dates each year
//      1.4.3   Auto-generated journal entries (anniversaries, weather logs) with user approval
//      1.4.4   Taste — calorie/food logging, weight logging
//      1.4.5   Vestibular — GPS route logger
//      1.4.6   JournalKit integration (Apple's journaling suggestions API)
//      1.4.7   Video support in entries
//
// MARK: - Data Model (SwiftData + CloudKit)
//
//  MilestoneEntry
//      - id: UUID
//      - timestamp: Date                          // The arbiter of truth
//      - title: String
//      - body: String                             // User's journal text
//      - latitude: Double?                        // CoreLocation
//      - longitude: Double?                       // CoreLocation
//      - locationName: String?                    // Reverse geocoded
//      - weatherCondition: String?                // WeatherKit sky condition
//      - weatherTemperature: Double?              // WeatherKit temp
//      - weatherHumidity: Double?                 // WeatherKit humidity
//      - weatherWindSpeed: Double?                // WeatherKit wind
//      - weatherUVIndex: Int?                     // WeatherKit UV
//      - sightPhotos: [Data]?                     // Photo attachments
//      - hearingSongTitle: String?                // ShazamKit (v1.1)
//      - hearingSongArtist: String?               // ShazamKit (v1.1)
//      - hearingAmbientDB: Double?                // Ambient level (v1.1)
//      - touchDescription: String?                // User text
//      - smellDescription: String?                // User text
//      - smellPhoto: Data?                        // Optional photo
//      - tasteDescription: String?                // User text
//      - tastePhoto: Data?                        // Food photo
//      - vestibularSteps: Int?                    // HealthKit (v1.1)
//      - proprioceptionHeartRate: Double?         // HealthKit (v1.1)
//      - proprioceptionActivity: String?          // HealthKit (v1.1)
//      - isMilestone: Bool                        // Promoted to index
//      - milestoneIcon: String?                   // Emoji/glyph (v1.3)
//      - sourceURL: String?                       // Share sheet origin (v1.2)
//      - sourceClipping: String?                  // Highlighted text (v1.2)
//      - pdfData: Data?                           // PDF attachment (v1.2)
//      - createdAt: Date                          // When entry was created (vs timestamp which is the event date)
//
// MARK: - File Naming Convention
//
//  Every entry displayed and filed as:
//      YYYY MMM DD HHMM Title or Description
//
//  Examples:
//      2026 APR 01 1735 Artemis II Launch
//      1993 MAY 22 1000 High School Graduation
//      1975 JUN 15 0000 Born — Surfside Beach TX
//      2026 MAR 27 0900 CryoTunes Goes Live
//
// MARK: - Design Notes
//
//  The seven senses are not gimmicks — they are prompts for memory.
//  Smell and taste are the strongest memory triggers in the brain.
//  The app asks you to remember them.
//
//  The index is the back of the journal. Not onboarding. Not a wizard.
//  A living document the user builds over their lifetime.
//
//  The time machine is not a date picker. It is a life navigator.
//  Milestones are bookmarks. Weather is auto-filled. The user writes.
//
//  Engineered with Claude by Anthropic.
//
// ◆───────────────────────────────────────────────────────────────────◆

import Foundation

// This file is for developer reference only.
// No executable code — roadmap, data model, and project notes live here.

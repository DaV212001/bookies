Your task is to implement the Community / Social Reading UI described below in the existing Flutter codebase.

CRITICAL INSTRUCTION

Do NOT create a new design system.

The application already has an established visual language implemented throughout the codebase. Before writing any UI code, inspect the existing application thoroughly and identify how it currently handles:

Colors and themes
Typography
Spacing
Cards
Buttons
Icons
App bars
Navigation
Tabs
Bottom sheets
Dialogs
Lists
Avatars
User information
Input fields
Chat/message UI
Like buttons
Empty states
Loading/skeleton states
Image/book-cover presentation
Screen transitions
State management
Responsive layouts

The existing codebase is the source of truth for the design language.

Reuse existing widgets/components wherever possible.

If the existing application already has a component that is visually appropriate for something, extend or reuse it rather than creating another visually similar component.

Do not introduce new colors, typography systems, spacing scales, radii, shadows, or component styles unless the feature genuinely requires something that does not already exist.

The new Community UI should look like it has always been part of this application.

FIRST: INSPECT THE CODEBASE

Before implementing anything, inspect the relevant parts of the project.

Determine:

Architecture
Current project structure
Feature/module organization
Existing architectural patterns
Existing state-management approach
Existing dependency injection approach
Existing routing/navigation approach
Existing components

Search for existing implementations of:

Book cards
Book headers
Tabs
Lists
Cards
User avatars
Profiles
Likes
Comments
Chat/messages
Text fields
Bottom sheets
Dialogs
Empty states
Loading states
Error states
Existing models/services

Look for existing:

Book models
Chapter models
Highlight models
User models
Community models
Authentication
API clients
Repositories
Realtime services
Messaging services
Existing reader integration

The EPUB reader is already implemented.

Inspect how it represents:

Books
Chapters
Highlights
Locations/positions
Highlight IDs
Book IDs
Chapter IDs

Do not create a second incompatible representation of these concepts.

FEATURE OVERVIEW

A book can have a Community.

Community members can create discussions associated with five different targets:

Whole book
Chapter
Highlight
Topic
Subtopic

The Community also contains Community Quotes.

The main Community page has four tabs:

Global Discussion
Chapter Discussion
Highlights
Community Quotes
COMMUNITY DETAIL SCREEN

Implement the Community Detail screen for a book.

Use the existing application's book/community header patterns.

Do not invent a new header.

The screen should contain:

Existing book/community information
Four tabs
Global Discussion
Chapter Discussion
Highlights
Community Quotes

The default tab is Global Discussion.

Use the application's existing tab implementation if one exists.

GLOBAL DISCUSSION

The Global Discussion tab contains:

General Discussion

A prominent entry/card for the discussion about the entire book.

It should communicate relevant information such as:

Discussion title
Participant count
Message count
Recent activity

Use whatever metadata patterns already exist in the application.

Tapping it opens the whole-book discussion chat.

Topics

Below the General Discussion, show the topics that exist for the book.

Example:

Character Development
Pacing
Themes
Writing Style
World Building

Topics are actual discussion destinations.

A topic can also contain subtopics.

Do not treat topics as decorative categories.

Tapping a topic should navigate to the appropriate topic view/discussion.

TOPICS AND SUBTOPICS

A topic can contain zero or more subtopics.

Example:

Character Development
    ├── Elizabeth
    ├── Darcy
    └── Jane

A topic itself can have a discussion.

Each subtopic can have its own discussion.

The hierarchy should therefore support:

Book
  → Topic
      → Discussion

Book
  → Topic
      → Subtopic
          → Discussion

Do not flatten this structure.

Create a topic/subtopic screen using existing list/card patterns from the application.

It should show:

Topic title
Topic description/context if available
Topic discussion entry
Subtopics
Relevant discussion metadata
DISCUSSION CHAT

Implement a reusable discussion chat screen.

The same chat implementation should support:

Whole-book discussion
Topic discussion
Subtopic discussion
Chapter discussion
Highlight discussion

The conceptual interaction model is similar to a Telegram topic-based group, but do not copy Telegram's visual design.

Use the application's existing chat/message components if they already exist.

The chat should support the existing application's conventions for:

Messages
User avatars
Timestamps
Message composer
Scrolling
Replies
Mentions
Message states
Realtime updates
Loading older messages

Do not build five separate chat implementations.

Create a reusable discussion/chat screen whose context changes depending on its discussion target.

DISCUSSION CONTEXT

Every discussion must clearly communicate what it is about.

Examples:

Whole book
Pride and Prejudice
General Discussion
Topic
Pride and Prejudice
Character Development
Subtopic
Pride and Prejudice
Character Development
Elizabeth
Chapter
Pride and Prejudice
Chapter 7
Highlight
Pride and Prejudice
Chapter 8
[highlighted passage]

Use the application's existing header/navigation patterns to communicate this context.

Do not create five unrelated header designs.

CHAPTER DISCUSSION TAB

Implement the Chapter Discussion tab.

Display chapters that currently have discussions.

For example:

Chapter 1
24 participants · 38 messages

Chapter 3
12 participants · 17 messages

Chapter 7
41 participants · 103 messages

Use existing chapter/list components where appropriate.

Only chapters with discussions need to be displayed.

Tapping a chapter opens the reusable discussion chat with that chapter as its target.

HIGHLIGHTS TAB

Implement the Highlights tab.

Display highlights that have associated discussions.

Each item should show appropriate information such as:

Highlighted passage
Chapter/location
Highlight creator
Discussion activity
Like count
Current user's like state

Use the application's existing highlight styling.

The highlighted text should remain visually prominent.

Each highlight should support:

Like
Unlike
Opening its discussion

Do not build a separate social-post system for highlights if an existing reusable content-card pattern can be adapted.

HIGHLIGHT DISCUSSION

When a highlight discussion is opened, display the highlighted passage as contextual information.

The user must immediately understand:

This discussion is about this specific passage.

Then display the normal reusable discussion chat.

Do not create a completely separate chat implementation for highlights.

COMMUNITY QUOTES

Implement the Community Quotes tab.

Community quotes are notable passages from the book that have been selected by the community.

There are two states:

Creator Picked

The community creator directly selected the quote.

Community Nominated

A community member nominated the quote and it reached the required voting threshold.

Each quote must clearly communicate which state it has.

For example:

CREATOR PICKED

or:

COMMUNITY NOMINATED

Use the application's existing badge/pill/metadata components if available.

Do not invent a new badge style unless necessary.

Each quote should support:

Quote text
Chapter/location
Like count
Like/unlike
Selection type
CREATE DISCUSSION

Implement the UI for creating a discussion.

The user should be able to select the discussion target:

Whole Book
Chapter
Highlight
Topic
Subtopic

The creation flow should dynamically show the relevant fields.

For example:

Whole Book

Title
Description/context
Initial message

Chapter

Chapter
Title
Description/context
Initial message

Highlight

Highlight
Title/context
Initial message

Topic

Topic
Title/context
Initial message

Subtopic

Parent topic
Subtopic
Title/context
Initial message

Use existing form components and validation patterns from the application.

Do not create a new form system.

CREATE TOPIC

Implement topic creation using the existing application's form patterns.

Fields should include whatever is appropriate for the existing backend/model, such as:

Topic name
Description

Example:

Topic
Character Development

Description
How the characters evolve throughout the story.
CREATE SUBTOPIC

Implement subtopic creation.

The parent topic must be clearly represented.

Example:

Topic
Character Development

Subtopic
Elizabeth

Description
How Elizabeth changes throughout the novel.

The user should never be confused about which topic the subtopic belongs to.

NOMINATE COMMUNITY QUOTE

Implement the UI for nominating a Community Quote.

The user should be able to select/reference a passage from the book.

Show:

Selected passage
Chapter/location
Nomination information
Voting state where appropriate

Use the existing reader/highlight selection mechanisms if they already provide the necessary data.

Do not create a duplicate quote/highlight selection system without first inspecting the existing reader implementation.

LIKES

Highlights and Community Quotes are likeable.

Implement:

Unliked state
Liked state
Like count
Like/unlike interaction

Use the application's existing like/favorite interaction if one already exists.

Do not create a second liking mechanism.

Follow the existing backend/API conventions for persistence.

EMPTY STATES

Implement appropriate empty states for:

No topics
No chapter discussions
No highlight discussions
No community quotes
Empty discussion

First search the codebase for existing empty-state components.

Reuse them.

Only create a new empty-state component if no suitable existing component exists.

LOADING STATES

Implement loading states for:

Community
Topics
Chapters
Highlights
Quotes
Discussions
Chat messages

Reuse the application's existing loading/skeleton components.

DATA AND ARCHITECTURE

Do not hardcode community data into widgets.

Follow the application's existing architecture.

Before creating new models/services/repositories, determine whether equivalent abstractions already exist.

Discussion targets should conceptually support:

BOOK
CHAPTER
HIGHLIGHT
TOPIC
SUBTOPIC

A discussion should be associated with a specific target.

Do not create five unrelated discussion systems.

Prefer a reusable discussion abstraction compatible with the existing backend.

BACKEND

Inspect the existing backend/API implementation before assuming endpoints or schemas.

If APIs/models already exist, use them.

If backend functionality is missing, do not silently invent an incompatible API.

Clearly isolate any temporary mock data if it is necessary for UI development.

Do not replace real backend integration with mock data merely because it is easier.

NAVIGATION

Implement navigation along this structure:

Community
│
├── Global Discussion
│   ├── General Discussion
│   ├── Topic
│   │   └── Discussion
│   └── Topic
│       ├── Subtopic
│       │   └── Discussion
│       └── Discussion
│
├── Chapter Discussion
│   └── Chapter
│       └── Discussion
│
├── Highlights
│   └── Highlight
│       └── Discussion
│
└── Community Quotes

Use the existing routing/navigation system.

Do not introduce a second navigation architecture.

Back navigation should preserve context naturally.

For example:

Community
 → Chapter Discussions
   → Chapter 7 Discussion
     → Back
   → returns to Chapter Discussions
REUSABILITY

The implementation should have reusable components for concepts that repeat.

For example:

Discussion list item/card
Topic item
Chapter discussion item
Highlight discussion item
Community quote card
Like button
Discussion context header
Discussion chat
Message composer

However, do not over-engineer.

Follow the existing project's component organization and naming conventions.

PERFORMANCE

Do not load every discussion's messages when opening the Community Detail page.

The community page should load discussion metadata/list information.

Messages should be loaded when the user opens the specific discussion.

Use lazy lists for potentially large collections.

Avoid unnecessary rebuilds and network requests.

Follow the application's existing performance patterns.

IMPLEMENTATION PROCESS

Follow this order.

Phase 1 — Inspect

Before writing code, inspect:

Existing project architecture
Existing design system
Existing reusable widgets
Existing navigation
Existing state management
Existing API/repository layer
Existing community functionality
Existing reader/highlight implementation
Stitch exports

Do not start implementing after only looking at a few files.

Phase 2 — Map Existing Components

Create an internal mapping such as:

Community header → existing X component
Tabs → existing Y component
Content cards → existing Z component
Like button → existing A component
Chat → existing B component
Forms → existing C component

Then implement the new feature by composing these existing components.

Phase 3 — Implement

Build the Community screens and navigation.

Keep the implementation consistent with the existing architecture.

Phase 4 — Integrate

Connect the screens to the existing models/services/backend where available.

Ensure reader highlights and chapters remain linked to their existing IDs/data.

Phase 5 — Verify

Run the project's existing:

Flutter analyzer
Tests
Build checks

Fix any issues introduced by the implementation.

Also verify:

Navigation
Back navigation
Loading states
Empty states
Like/unlike
Long text
Long discussions
Keyboard behavior
Chat scrolling
Authentication
Permissions
Existing reader functionality
NON-NEGOTIABLE CONSTRAINTS

Do not:

Redesign the existing application.
Create a new visual language.
Replace the existing theme.
Introduce a new state-management library.
Introduce a new routing system.
Create duplicate versions of existing components.
Rebuild the EPUB reader.
Create a second highlight system.
Hardcode community content.
Create five unrelated chat implementations.
Invent backend contracts without inspecting the existing backend.
Make the new screens visually different from the rest of the application.
Modify unrelated existing features unnecessarily.

Do:

Inspect before implementing.
Reuse existing components.
Follow existing architecture.
Follow existing naming conventions.
Follow existing state-management patterns.
Follow existing navigation patterns.
Use Stitch as a reference for the intended feature layout and UX.
Make the new Community experience feel native to the existing application.
Keep the implementation production-quality.
DEFINITION OF DONE

The implementation is complete when the existing Flutter application contains a functional Community experience where a user can:

Open a book's Community.
See the existing book/community header.
Switch between Global Discussion, Chapter Discussion, Highlights, and Community Quotes.
Open the whole-book discussion.
Browse topics.
Open topic discussions.
Browse subtopics.
Open subtopic discussions.
Browse chapters with discussions.
Open chapter discussions.
Browse highlights with discussions.
Like/unlike highlights.
Open highlight discussions.
Browse Community Quotes.
Distinguish Creator Picked and Community Nominated quotes.
Like/unlike Community Quotes.
Create discussions for the supported target types.
Create topics and subtopics.
Nominate Community Quotes.
Navigate naturally between all of these screens.
See appropriate loading and empty states.

Most importantly:

When the feature is finished, a user should not be able to tell that the Community screens were added later. They should look and behave like they were part of the original application from the beginning.
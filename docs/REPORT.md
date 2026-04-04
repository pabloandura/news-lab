# Project Report — News Lab

## 1. Introduction

I came into this project with prior experience in full-stack development but not with Flutter, Firebase, or the BLoC pattern specifically. 
My familiarity was in clean architecture principles and state management in general, so the learning curve was around the ecosystem and tooling rather than the underlying ideas. The assignment is well scoped — a realistic feature you'd build in any news or publishing product — which made it easier to stay motivated and treat it as production work rather than a coding exercise.

---

## 2. Learning Journey

*See [`docs/LEARNING_JOURNEY.md`](LEARNING_JOURNEY.md) for a detailed, running log of checkpoints.*

The short version: I worked through Flutter and BLoC fundamentals first, then Firebase integration, then clean architecture layering. 

Wrote an acceptance criteria doc (`ACCEPTANCE_CRITERIA.md`) at the repo root served as the basic idea — I used it to sequence work and avoid building ahead of what was actually needed.

---

## 3. Challenges Faced

**Learning new technologies:** Flutter, Firebase, and BLoC were all new to me, so there was a learning curve in understanding how they work and how to use them effectively together. I leaned heavily on official documentation, and the guidelines for this project listed in the `starter-project` from `DiegoloM3`.

---

## 4. Reflection

The clean architecture constraint — no Firebase imports in `domain/`, no business logic in `build()` methods — adds upfront friction but pays off quickly when you need to swap or extend a data source. The Firestore + Storage split into two separate data sources (`ArticleFirestoreDataSource`, `ArticleStorageDataSource`) made the upload flow easy to reason about and test independently.

---

## 5. Proof of the Project

*Screenshots and screen recordings to be added here as the project progresses.*

---

## 6. Overdelivery ideas

### New Features Beyond Core Acceptance Criteria

#### Multiple news sources

#### Comunity notes

#### Fact checking and bias detection. 

#### Sensemaker
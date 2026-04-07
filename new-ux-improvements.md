# New UX Improvements to Port into Flutter

Differences found comparing `news-lab_new-ux/` (React) against `frontend/` (Flutter).
Only NEW features and UX/UI improvements are listed — shared core functionality is excluded.

---

## Authentication / Sign In

| # | Name | Description |
|---|------|-------------|
| 1 | Dual-mode auth toggle | Sign In and Create Account modes on the same screen with a visual toggle, instead of sign-in only. |
| 3 | Forgot password link | A "Forgot password?" action link in sign-in mode. |
| 4 | Terms & Privacy links | Links to Terms of Service and Privacy Policy shown below the sign-in form. |

## Home Feed

| # | Name | Description |
|---|------|-------------|
| 5 | Real-time search | Expandable search bar in the header that filters articles by title in real-time. |
| 6 | Breaking news ticker | A prominent ticker banner displayed below the category bar. |
| 7 | Featured article spotlight | The first matching article is rendered as a larger hero card with image overlay and gradient. |
| 8 | Sticky blurred header | Header stays pinned on scroll with a backdrop-blur frosted-glass effect. |

## Article Detail

| # | Name | Description |
|---|------|-------------|
| 9 | Share button | A share action button in the article header alongside bookmark. |
| 10 | Bias spectrum visualization | A horizontal gradient bar with a positioned marker showing the exact lean (left/center/right) instead of just a text label. |
| 11 | Bias confidence percentage | Displays a numeric confidence score next to the bias analysis result. |
| 12 | Collapsible analysis panels | AI Fact-Check, Bias Analysis, and Similar Articles are expandable/collapsible accordion sections with chevron icons. |
| 13 | Credible/Disputed vote styling | Community vote buttons change background color dramatically (green for credible, red for disputed) with feedback text on selection. |
| 14 | Hero image with gradient overlay | Article detail opens with a full-width hero image that has a bottom gradient for text readability. |

## Explore

| # | Name | Description |
|---|------|-------------|
| 15 | Trending articles list | A numbered ranking list of trending articles below the category grid. |
| 16 | Bias breakdown stats | Three horizontal progress bars showing the Left / Center / Right distribution across the news landscape. |
| 17 | Explore search | A search input that filters trending articles by title within the explore screen. |
| 18 | Color-coded category buttons | Categories use warm tones for Politics/Business and cool tones for Tech/Science for quick visual scanning. |

## Publish

| # | Name | Description |
|---|------|-------------|
| 19 | Two-step publish flow | Article creation split into Step 1 (metadata) and Step 2 (body), reducing form overwhelm. |
| 20 | Step indicator dots | Animated dot indicator showing current step progress (1 of 2). |
| 21 | Character counters | Live character count with max limits on headline (120) and description (280) fields. |
| 22 | AI analysis info callout | An informational box explaining that bias and fact-check badges will appear automatically after publishing. |
| 23 | Success screen with auto-redirect | A confirmation screen with a check icon and two info boxes, auto-redirecting to feed after 2 seconds. |

## Profile

| # | Name | Description |
|---|------|-------------|
| 24 | Stats overview grid | A 3-column grid showing Articles count, Total Views, and Upvotes at the top of the profile. |
| 25 | Analytics tab | A second tab alongside "My Articles" showing credibility score, bias profile badge, and a 7-day views bar chart. |
| 26 | Average credibility score | Large numeric display of the user's average credibility rating (out of 100). |
| 27 | 7-day views bar chart | Simple bar graph visualizing article views over the last 7 days. |
| 28 | Inline edit modal | Article title and description editing via an overlay modal instead of navigating to a separate edit screen. |

## Navigation & Layout

| # | Name | Description |
|---|------|-------------|
| 29 | Bottom navigation bar | Fixed bottom nav with Feed, Explore, Publish, and Profile tabs replacing the current tab/FAB approach. |
| 30 | Elevated publish button | The Publish tab in the bottom nav is visually elevated and larger as a primary call-to-action. |
| 31 | Mobile viewport shell | The entire app is wrapped in a max-width container with shadow, simulating a phone frame on larger screens. |

## Article Cards

| # | Name | Description |
|---|------|-------------|
| 32 | Featured card variant | A large card format with full-width hero image, gradient overlay, and category pill for highlighted articles. |
| 33 | Compact card variant | A smaller card format with thumbnail, title, author, and time — used in similar articles and trending lists. |
| 34 | Inline AI badges on cards | Bias and fact-check badges displayed directly on article list tiles in the feed (not only in detail view). |

## General UX Patterns

| # | Name | Description |
|---|------|-------------|
| 35 | Empty states | Screens with no content show an icon, a primary message, and a secondary hint instead of blank space. |
| 36 | Delete scale-down animation | Deleted items animate with scale-down and opacity fade before removal. |
| 37 | Input focus rings | Form inputs show a colored focus ring (primary accent) on focus for better accessibility feedback. |
| 38 | Loading spinners on actions | All async actions (sign in, publish, AI checks, edit, delete) show inline spinners on the triggering button. |

--- 

Which are the implications of implementing these improvements in the flutter app and our microservices architecture? 

Ask me questions if you need more information to provide a comprehensive answer.
# StudentOS source-to-Flutter mapping

| Supplied React/Figma area | Flutter implementation |
|---|---|
| Sign in, sign up, country code, password visibility, verification code, Google continuation | `features/auth/presentation/auth_screen.dart` |
| Local session and registered demo users | `features/auth/data/auth_controller.dart`, `auth_repository.dart` |
| Protected redirects and persistent five-tab navigation | `app/router.dart` |
| Persistent header, profile, notification and AI search actions | `features/shell/student_os_shell.dart` |
| Home dashboard | `features/home/home_screen.dart` |
| Shop, product filtering, favorites and cart | `features/shop/shop_screen.dart` |
| Career courses, roadmap and internships | `features/career/career_screen.dart` |
| Food discovery, cuisine/restaurant filters and cart actions | `features/food/food_screen.dart` |
| More/account/service menu | `features/more/more_screen.dart` |
| Budget manager, categories, transactions and expense entry | `features/budget/budget_screen.dart` |
| Task Manager filters, add, toggle, clear and delete | `features/tasks/tasks_screen.dart` |
| Student status, university email, ID upload and verified card | `features/services/student_id_screen.dart`, `features/student_verification/state/student_verification_controller.dart` |
| Tuition, Buy & Sell, Marketplace and Events | `features/services/catalog_service_screens.dart` |
| Notes, Calculator, Bookmarks and Saved Items | `features/services/productivity_screens.dart` |
| Settings, Help, Privacy, About and Logout | `features/services/settings_help_screens.dart` |
| Editable profile and notifications | `features/profile/profile_screens.dart` |
| Product/course/job/food/tuition/event/listing details | `features/details/detail_screen.dart` |
| Cross-feature search | `features/search/search_screen.dart` |

The Flutter implementation keeps Bangladesh taka values and source-specific CUET content while translating React component state into Riverpod notifiers and replacing modal-only navigation with deep-linkable routes.

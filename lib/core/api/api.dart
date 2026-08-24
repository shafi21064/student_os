import '../config/env_config.dart';

class Api {
  Api._();

  static final String baseUrl = EnvConfig.baseUrl;

  /// Authentication
  static String loginWithEmail = "$baseUrl/api/v1/auth/signin";
  static String sendSignInOtp = "$baseUrl/api/v1/auth/send-signin-otp";
  static String verifySignInOtp = "$baseUrl/api/v1/auth/signin/otp";
  static String signupWithEmail = "$baseUrl/api/v1/auth/signup";
  static String sendSignUpOtp = "$baseUrl/api/v1/auth/send-signup-otp";
  static String verifySignUpOtp = "$baseUrl/api/v1/auth/signup/otp";
  static String forgetPasswordWithEmail =
      "$baseUrl/api/v1/auth/send-reset-otp-email";
  static String forgetPasswordPhone = "$baseUrl/api/v1/auth/send-reset-otp";
  static String verifyOTPWithEmail = "$baseUrl/api/v1/auth/verify-reset-otp";
  static String resetPasswordWithEmail = "$baseUrl/api/v1/auth/reset-password";
  // static String socialLogin =
  //     "$baseUrl/api/v1/auth/social-signin-via-access-token";
  static String socialLogin =
      "$baseUrl/api/v1/auth/social-signin-via-firebase-id-token";
  static String logout = "$baseUrl/api/v1/auth/signout";
  static String changePassword = "$baseUrl/api/v1/auth/change-password";
  static String profileUpdate = "$baseUrl/api/v1/auth/profile-update";
  static String userApi = "$baseUrl/api/user";

  ///Courses
  static String courses = "$baseUrl/api/v1/courses";
  static String coursesDetails = "$baseUrl/api/v1/courses/";
  static String coursesTopCategories = "$baseUrl/api/v1/course-top-categories";
  static String coursesEnroll = "$baseUrl/api/v1/course-carts";
  static String coursesApplyCoupon =
      "$baseUrl/api/v1/apply-coupon-on-course-cart/";
  static String coursesRemoveCoupon =
      "$baseUrl/api/v1/remove-coupon-from-course-cart/";
  static String submitCourseReview = "$baseUrl/api/v1/course-reviews";
  static String courseFilterData = "$baseUrl/api/v1/course-filter-data";
  static String enrollForFree = "$baseUrl/api/v1/course-free-enroll";
  static String ongoingCourse = "$baseUrl/api/v1/ongoing-courses";
  static String courseUser = "$baseUrl/api/v1/course-users";

  ///Admission
  static String submitAdmissionData = "$baseUrl/api/v1/admission/submit";

  ///Categories
  static String courseCategory = "$baseUrl/api/v1/course-categories";

  ///cart
  static String cart = "$baseUrl/api/v1/product-carts";
  static String deleteCartProduct = "$baseUrl/api/v1/product-carts/";
  static String applyCoupon = "$baseUrl/api/v1/apply-coupon-on-product-cart";
  static String removeCoupon =
      "$baseUrl/api/v1/remove-coupon-from-product-cart";

  ///order
  static String productOrder = "$baseUrl/api/v1/product-orders";
  static String courseOrder = "$baseUrl/api/v1/course-orders/";

  ///blogs
  static String blogs = "$baseUrl/api/v1/blogs";
  static String blogsCategories = "$baseUrl/api/v1/blog-categories";
  static String blogsTags = "$baseUrl/api/v1/blog-tags";
  static String blogsDetails = "$baseUrl/api/v1/blogs/";
  static String postComment = "$baseUrl/api/v1/blog-comments";

  ///store
  static String allProduct = "$baseUrl/api/v1/products";
  static String productTopCategories = "$baseUrl/api/v1/product-top-categories";
  static String productDetails = "$baseUrl/api/v1/products/";
  static String storeComment = "$baseUrl/api/v1/product-reviews";
  static String purchaseWithMembership = "$baseUrl/api/v1/product-subscribe/";

  ///home
  static String homeAllData = "$baseUrl/api/v1/home-page";
  static String allUpComingBatch = "$baseUrl/api/v1/course-batches";
  static String allUpComingEvent = "$baseUrl/api/v1/events-upcoming";
  static String allEvents = "$baseUrl/api/v1/events";
  static String eventsDetails = "$baseUrl/api/v1/events";
  static String eventRegistration = "$baseUrl/api/v1/event-has-users";
  static String allSuccessStories = "$baseUrl/api/v1/success-stories";
  static String allStudentFeedback = "$baseUrl/api/v1/students-feedback";

  /// bundle courses
  static String bundleCourses = "$baseUrl/api/v1/course-bundles";
  static String bundleFilterData = "$baseUrl/api/v1/course-bundle-filter-data";
  static String bundleCourseCart = "$baseUrl/api/v1/course-bundle-carts";
  static String bundleCourseOrder = "$baseUrl/api/v1/course-bundle-orders";

  ///my course
  static String myCourse = "$baseUrl/api/v1/course-users";
  static String myCourseDetails = "$baseUrl/api/v1/my-course-details?slug=";
  static String markAsComplete = "$baseUrl/api/v1/mark-as-completed/";
  static String submitClassAssignment =
      "$baseUrl/api/v1/course-lesson-item-assignment/";
  static String getQuiz = "$baseUrl/api/v1/course-lesson-item-quizes/";
  static String getResult =
      "$baseUrl/api/v1/course-lesson-item-quize-result-preview/";

  /// Wishlist
  static String wishList = "$baseUrl/api/v1/wishlist";

  /// Assignment
  static String myAssignments = "$baseUrl/api/v1/my-assignments";

  ///my store
  static String myStore = "$baseUrl/api/v1/product-users?user_name=";

  ///Payment options
  static String paymentOptions = "$baseUrl/api/v1/payment-options";

  /// MemberShip
  static String activeMemberShip = "$baseUrl/api/v1/user-active-membership";
  static String availableMemberShip =
      "$baseUrl/api/v1/user-available-memberships";
  static String memberShipPayment = "$baseUrl/api/v1/subscribe-membership";
  static String subscribeCourse = "$baseUrl/api/v1/course-subscribe/";

  ///Contest
  static String contestList = "$baseUrl/api/v1/contests";
  static String contestViewDetails = "$baseUrl/api/v1/contests/";
  static String contestQuiz = "$baseUrl/api/v1/contest-quizzes";
  static String contestSubmit = "$baseUrl/api/v1/contest-quize-submit/";
  static String contestLeaderBoard = "$baseUrl/api/v1/contest-result";

  /// my learnings
  static String myLearnings = "$baseUrl/api/v1/user-dashboard";

  ///Icons
  static String profileIcon = "$baseUrl/api/v1/user-dashboard";

  ///Certificates
  static String userCertificates = "$baseUrl/api/v1/certificate";

  ///Notification
  static String allNotification = "$baseUrl/api/v1/user-notifications";
  static String seeAllNotification =
      "$baseUrl/api/v1/user-notifications/all-seen";
  static String deleteAllNotification =
      "$baseUrl/api/v1/user-notifications/all-delete";

  ///Support
  static String studentSupport = "$baseUrl/api/v1/support";
  static String supportComment = "$baseUrl/api/v1/support/comment";

  ///Terms of use
  static String termsOfUse = "$baseUrl/api/v1/terms-settings";

  ///Privacy policy
  static String privacyPolicy = "$baseUrl/api/v1/privacy-policy-settings";

  /// Forum
  static String forumTopic = "$baseUrl/api/v1/forum-topics";
  static String reactOnPost = "$baseUrl/api/v1/forum-topic-like-unlike";
  static String commentOnPost = "$baseUrl/api/v1/forum-topics-comment";

  /// Reward
  static String rewardPoint = "$baseUrl/api/v1/reward-points";
  static String purchaseWithRewardPoint =
      "$baseUrl/api/v1/purchase-with-reward-points";

  /// Personal management
  static String userBudgets =
      "$baseUrl/api/v1/personal-management/user-budgets";
  static String userExpenses =
      "$baseUrl/api/v1/personal-management/user-expenses";
  static String userTodos = "$baseUrl/api/v1/user-todo/user-todos";

  /// Share api fetch
  static String rewardShareApi = "$baseUrl/api/v1/user-sharing";

  /// send device token
  static String deviceToken =
      "$baseUrl/api/v1/profile/update-notification-token";

  /// Certificate
  static String getStudentDataForCertificate =
      "$baseUrl/api/v1/get-data-for-generate-certificate";
  static String saveCertificate = "$baseUrl/api/v1/save-certificate";

  ///Instructor
  static String getInstructors = "$baseUrl/api/v1/instructors";
}

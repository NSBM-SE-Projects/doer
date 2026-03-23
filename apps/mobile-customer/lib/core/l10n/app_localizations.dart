import 'package:flutter/material.dart';

/// AppLocalizations provides translated strings for the customer app.
/// Usage: AppLocalizations.of(context).signIn
class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('en'));
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  String _t(String key) =>
      _strings[locale.languageCode]?[key] ??
      _strings['en']![key] ??
      key;

  // ── COMMON ─────────────────────────────────
  String get save => _t('save');
  String get cancel => _t('cancel');
  String get confirm => _t('confirm');
  String get delete => _t('delete');
  String get edit => _t('edit');
  String get loading => _t('loading');
  String get retry => _t('retry');
  String get search => _t('search');
  String get close => _t('close');
  String get submit => _t('submit');
  String get next => _t('next');
  String get back => _t('back');
  String get done => _t('done');
  String get error => _t('error');
  String get success => _t('success');
  String get required => _t('required');
  String get optional => _t('optional');
  String get yes => _t('yes');
  String get no => _t('no');
  String get ok => _t('ok');
  String get viewAll => _t('viewAll');
  String get noResults => _t('noResults');

  // ── AUTH ────────────────────────────────────
  String get signIn => _t('signIn');
  String get signUp => _t('signUp');
  String get signOut => _t('signOut');
  String get login => _t('login');
  String get register => _t('register');
  String get email => _t('email');
  String get password => _t('password');
  String get fullName => _t('fullName');
  String get phoneNumber => _t('phoneNumber');
  String get forgotPassword => _t('forgotPassword');
  String get resetPassword => _t('resetPassword');
  String get alreadyHaveAccount => _t('alreadyHaveAccount');
  String get dontHaveAccount => _t('dontHaveAccount');
  String get orContinueWith => _t('orContinueWith');
  String get continueWithGoogle => _t('continueWithGoogle');
  String get loginToYourAccount => _t('loginToYourAccount');
  String get createAccount => _t('createAccount');
  String get enterEmail => _t('enterEmail');
  String get enterPassword => _t('enterPassword');
  String get confirmPassword => _t('confirmPassword');
  String get welcomeBack => _t('welcomeBack');
  String get getStarted => _t('getStarted');
  String get sendResetLink => _t('sendResetLink');
  String get checkYourEmail => _t('checkYourEmail');
  String get enterEmailForReset => _t('enterEmailForReset');
  String get passwordsDoNotMatch => _t('passwordsDoNotMatch');
  String get pleaseEnterEmail => _t('pleaseEnterEmail');
  String get pleaseEnterPassword => _t('pleaseEnterPassword');

  // ── NAVIGATION ──────────────────────────────
  String get home => _t('home');
  String get myJobs => _t('myJobs');
  String get messages => _t('messages');
  String get profile => _t('profile');
  String get notifications => _t('notifications');

  // ── HOME ────────────────────────────────────
  String get goodMorning => _t('goodMorning');
  String get goodAfternoon => _t('goodAfternoon');
  String get goodEvening => _t('goodEvening');
  String get whatServiceNeed => _t('whatServiceNeed');
  String get searchServices => _t('searchServices');
  String get categories => _t('categories');
  String get nearbyWorkers => _t('nearbyWorkers');
  String get topRated => _t('topRated');
  String get available => _t('available');
  String get noWorkersFound => _t('noWorkersFound');

  // ── CATEGORIES ──────────────────────────────
  String get plumbing => _t('plumbing');
  String get electrical => _t('electrical');
  String get cleaning => _t('cleaning');
  String get painting => _t('painting');
  String get carpentry => _t('carpentry');
  String get landscaping => _t('landscaping');
  String get appliances => _t('appliances');
  String get security => _t('security');

  // ── JOBS ────────────────────────────────────
  String get postAJob => _t('postAJob');
  String get jobTitle => _t('jobTitle');
  String get description => _t('description');
  String get category => _t('category');
  String get budget => _t('budget');
  String get location => _t('location');
  String get scheduledDate => _t('scheduledDate');
  String get urgency => _t('urgency');
  String get openJobs => _t('openJobs');
  String get activeJobs => _t('activeJobs');
  String get completedJobs => _t('completedJobs');
  String get cancelledJobs => _t('cancelledJobs');
  String get noJobsYet => _t('noJobsYet');
  String get postFirstJob => _t('postFirstJob');
  String get jobDetails => _t('jobDetails');
  String get applications => _t('applications');
  String get accept => _t('accept');
  String get reject => _t('reject');
  String get cancelJob => _t('cancelJob');
  String get jobPosted => _t('jobPosted');
  String get selectCategory => _t('selectCategory');
  String get addJobTitle => _t('addJobTitle');
  String get describeJob => _t('describeJob');
  String get setBudget => _t('setBudget');
  String get setLocation => _t('setLocation');
  String get addPhotos => _t('addPhotos');
  String get low => _t('low');
  String get normal => _t('normal');
  String get urgent => _t('urgent');
  String get emergency => _t('emergency');

  // ── JOB STATUSES ────────────────────────────
  String get statusOpen => _t('statusOpen');
  String get statusAssigned => _t('statusAssigned');
  String get statusInProgress => _t('statusInProgress');
  String get statusCompleted => _t('statusCompleted');
  String get statusCancelled => _t('statusCancelled');
  String get statusReviewing => _t('statusReviewing');

  // ── WORKERS ─────────────────────────────────
  String get workers => _t('workers');
  String get workerProfile => _t('workerProfile');
  String get rating => _t('rating');
  String get reviews => _t('reviews');
  String get jobsCompleted => _t('jobsCompleted');
  String get hireWorker => _t('hireWorker');
  String get noReviewsYet => _t('noReviewsYet');
  String get portfolio => _t('portfolio');

  // ── MESSAGING ───────────────────────────────
  String get conversations => _t('conversations');
  String get typeMessage => _t('typeMessage');
  String get send => _t('send');
  String get noConversationsYet => _t('noConversationsYet');
  String get messagePlaceholder => _t('messagePlaceholder');

  // ── PAYMENTS ────────────────────────────────
  String get payments => _t('payments');
  String get makePayment => _t('makePayment');
  String get releasePayment => _t('releasePayment');
  String get raiseDispute => _t('raiseDispute');
  String get totalSpent => _t('totalSpent');
  String get paymentStatus => _t('paymentStatus');
  String get paymentPending => _t('paymentPending');
  String get paymentHeld => _t('paymentHeld');
  String get paymentReleased => _t('paymentReleased');
  String get paymentDisputed => _t('paymentDisputed');

  // ── PROFILE / SETTINGS ──────────────────────
  String get editProfile => _t('editProfile');
  String get settings => _t('settings');
  String get language => _t('language');
  String get helpSupport => _t('helpSupport');
  String get about => _t('about');
  String get changePassword => _t('changePassword');
  String get deleteAccount => _t('deleteAccount');
  String get selectLanguage => _t('selectLanguage');
  String get accountSettings => _t('accountSettings');
  String get preferences => _t('preferences');
  String get support => _t('support');
  String get version => _t('version');
  String get name => _t('name');
  String get address => _t('address');
  String get updateProfile => _t('updateProfile');
  String get profileUpdated => _t('profileUpdated');
  String get currentPassword => _t('currentPassword');
  String get newPassword => _t('newPassword');
  String get passwordChanged => _t('passwordChanged');
  String get deleteAccountConfirm => _t('deleteAccountConfirm');
  String get locationServices => _t('locationServices');
  String get enableLocationServices => _t('enableLocationServices');

  // ── REVIEWS ─────────────────────────────────
  String get leaveReview => _t('leaveReview');
  String get writeReview => _t('writeReview');
  String get submitReview => _t('submitReview');
  String get reviewSubmitted => _t('reviewSubmitted');
  String get rateYourExperience => _t('rateYourExperience');

  // ── ERRORS ──────────────────────────────────
  String get networkError => _t('networkError');
  String get somethingWentWrong => _t('somethingWentWrong');
  String get tryAgain => _t('tryAgain');
  String get sessionExpired => _t('sessionExpired');

  // ── TRANSLATION MAPS ────────────────────────
  static const Map<String, Map<String, String>> _strings = {
    'en': {
      // Common
      'save': 'Save',
      'cancel': 'Cancel',
      'confirm': 'Confirm',
      'delete': 'Delete',
      'edit': 'Edit',
      'loading': 'Loading...',
      'retry': 'Retry',
      'search': 'Search',
      'close': 'Close',
      'submit': 'Submit',
      'next': 'Next',
      'back': 'Back',
      'done': 'Done',
      'error': 'Error',
      'success': 'Success',
      'required': 'Required',
      'optional': 'Optional',
      'yes': 'Yes',
      'no': 'No',
      'ok': 'OK',
      'viewAll': 'View All',
      'noResults': 'No results found',
      // Auth
      'signIn': 'Sign In',
      'signUp': 'Sign Up',
      'signOut': 'Sign Out',
      'login': 'Login',
      'register': 'Register',
      'email': 'Email',
      'password': 'Password',
      'fullName': 'Full Name',
      'phoneNumber': 'Phone Number',
      'forgotPassword': 'Forgot Password?',
      'resetPassword': 'Reset Password',
      'alreadyHaveAccount': 'Already have an account? Sign In',
      'dontHaveAccount': "Don't have an account? Sign Up",
      'orContinueWith': 'Or continue with',
      'continueWithGoogle': 'Continue with Google',
      'loginToYourAccount': 'Login to your account',
      'createAccount': 'Create Account',
      'enterEmail': 'Enter your email',
      'enterPassword': 'Enter your password',
      'confirmPassword': 'Confirm Password',
      'welcomeBack': 'Welcome Back!',
      'getStarted': 'Get Started',
      'sendResetLink': 'Send Reset Link',
      'checkYourEmail': 'Check your email',
      'enterEmailForReset': 'Enter your email to reset password',
      'passwordsDoNotMatch': 'Passwords do not match',
      'pleaseEnterEmail': 'Please enter your email',
      'pleaseEnterPassword': 'Please enter your password',
      // Navigation
      'home': 'Home',
      'myJobs': 'My Jobs',
      'messages': 'Messages',
      'profile': 'Profile',
      'notifications': 'Notifications',
      // Home
      'goodMorning': 'Good Morning',
      'goodAfternoon': 'Good Afternoon',
      'goodEvening': 'Good Evening',
      'whatServiceNeed': 'What service do you need?',
      'searchServices': 'Search services...',
      'categories': 'Categories',
      'nearbyWorkers': 'Nearby Workers',
      'topRated': 'Top Rated',
      'available': 'Available',
      'noWorkersFound': 'No workers found',
      // Categories
      'plumbing': 'Plumbing',
      'electrical': 'Electrical',
      'cleaning': 'Cleaning',
      'painting': 'Painting',
      'carpentry': 'Carpentry',
      'landscaping': 'Landscaping',
      'appliances': 'Appliances',
      'security': 'Security',
      // Jobs
      'postAJob': 'Post a Job',
      'jobTitle': 'Job Title',
      'description': 'Description',
      'category': 'Category',
      'budget': 'Budget',
      'location': 'Location',
      'scheduledDate': 'Scheduled Date',
      'urgency': 'Urgency',
      'openJobs': 'Open',
      'activeJobs': 'Active',
      'completedJobs': 'Completed',
      'cancelledJobs': 'Cancelled',
      'noJobsYet': 'No jobs yet',
      'postFirstJob': 'Post your first job',
      'jobDetails': 'Job Details',
      'applications': 'Applications',
      'accept': 'Accept',
      'reject': 'Reject',
      'cancelJob': 'Cancel Job',
      'jobPosted': 'Job posted successfully',
      'selectCategory': 'Select a category',
      'addJobTitle': 'Add a job title',
      'describeJob': 'Describe your job',
      'setBudget': 'Set your budget',
      'setLocation': 'Set location',
      'addPhotos': 'Add Photos',
      'low': 'Low',
      'normal': 'Normal',
      'urgent': 'Urgent',
      'emergency': 'Emergency',
      // Job statuses
      'statusOpen': 'Open',
      'statusAssigned': 'Assigned',
      'statusInProgress': 'In Progress',
      'statusCompleted': 'Completed',
      'statusCancelled': 'Cancelled',
      'statusReviewing': 'Reviewing',
      // Workers
      'workers': 'Workers',
      'workerProfile': 'Worker Profile',
      'rating': 'Rating',
      'reviews': 'Reviews',
      'jobsCompleted': 'Jobs Completed',
      'hireWorker': 'Hire Worker',
      'noReviewsYet': 'No reviews yet',
      'portfolio': 'Portfolio',
      // Messaging
      'conversations': 'Messages',
      'typeMessage': 'Type a message...',
      'send': 'Send',
      'noConversationsYet': 'No conversations yet',
      'messagePlaceholder': 'Type a message...',
      // Payments
      'payments': 'Payments',
      'makePayment': 'Make Payment',
      'releasePayment': 'Release Payment',
      'raiseDispute': 'Raise Dispute',
      'totalSpent': 'Total Spent',
      'paymentStatus': 'Payment Status',
      'paymentPending': 'Pending',
      'paymentHeld': 'Held in Escrow',
      'paymentReleased': 'Released',
      'paymentDisputed': 'Disputed',
      // Profile/Settings
      'editProfile': 'Edit Profile',
      'settings': 'Settings',
      'language': 'Language',
      'helpSupport': 'Help & Support',
      'about': 'About Doer',
      'changePassword': 'Change Password',
      'deleteAccount': 'Delete Account',
      'selectLanguage': 'Select Language',
      'accountSettings': 'Account',
      'preferences': 'Preferences',
      'support': 'Support',
      'version': 'Version',
      'name': 'Name',
      'address': 'Address',
      'updateProfile': 'Update Profile',
      'profileUpdated': 'Profile updated successfully',
      'currentPassword': 'Current Password',
      'newPassword': 'New Password',
      'passwordChanged': 'Password changed successfully',
      'deleteAccountConfirm': 'Are you sure you want to delete your account? This action cannot be undone.',
      'locationServices': 'Location Services',
      'enableLocationServices': 'Enable location services for better worker matching',
      // Reviews
      'leaveReview': 'Leave a Review',
      'writeReview': 'Write your review...',
      'submitReview': 'Submit Review',
      'reviewSubmitted': 'Review submitted successfully',
      'rateYourExperience': 'Rate your experience',
      // Errors
      'networkError': 'Network error. Please check your connection.',
      'somethingWentWrong': 'Something went wrong. Please try again.',
      'tryAgain': 'Try Again',
      'sessionExpired': 'Session expired. Please login again.',
    },
    'si': {
      // Common
      'save': 'සුරකින්න',
      'cancel': 'අවලංගු කරන්න',
      'confirm': 'තහවුරු කරන්න',
      'delete': 'මකා දමන්න',
      'edit': 'සංස්කරණය කරන්න',
      'loading': 'පූරණය වෙමින්...',
      'retry': 'නැවත උත්සාහ කරන්න',
      'search': 'සොයන්න',
      'close': 'වසන්න',
      'submit': 'ඉදිරිපත් කරන්න',
      'next': 'ඊළඟ',
      'back': 'ආපසු',
      'done': 'සම්පූර්ණයි',
      'error': 'දෝෂය',
      'success': 'සාර්ථකයි',
      'required': 'අවශ්‍යයි',
      'optional': 'අත්‍යවශ්‍ය නොවේ',
      'yes': 'ඔව්',
      'no': 'නැහැ',
      'ok': 'හරි',
      'viewAll': 'සියල්ල බලන්න',
      'noResults': 'ප්‍රතිඵල හමු නොවීය',
      // Auth
      'signIn': 'ඇතුල් වන්න',
      'signUp': 'ලියාපදිංචි වන්න',
      'signOut': 'ඉවත් වන්න',
      'login': 'පිවිසෙන්න',
      'register': 'ලියාපදිංචි වන්න',
      'email': 'විද්‍යුත් තැපෑල',
      'password': 'මුරපදය',
      'fullName': 'සම්පූර්ණ නම',
      'phoneNumber': 'දුරකථන අංකය',
      'forgotPassword': 'මුරපදය අමතකද?',
      'resetPassword': 'මුරපදය යළි සකස් කරන්න',
      'alreadyHaveAccount': 'දැනටමත් ගිණුමක් තිබේද? ඇතුල් වන්න',
      'dontHaveAccount': 'ගිණුමක් නැද්ද? ලියාපදිංචි වන්න',
      'orContinueWith': 'හෝ ඉදිරියට යන්න',
      'continueWithGoogle': 'Google සමඟ ඉදිරියට යන්න',
      'loginToYourAccount': 'ඔබගේ ගිණුමට ඇතුල් වන්න',
      'createAccount': 'ගිණුමක් සාදන්න',
      'enterEmail': 'ඔබගේ ඊමේල් ඇතුල් කරන්න',
      'enterPassword': 'ඔබගේ මුරපදය ඇතුල් කරන්න',
      'confirmPassword': 'මුරපදය තහවුරු කරන්න',
      'welcomeBack': 'නැවත සාදරයෙන් පිළිගනිමු!',
      'getStarted': 'ආරම්භ කරන්න',
      'sendResetLink': 'යළි සැකසීමේ සබැඳිය යවන්න',
      'checkYourEmail': 'ඔබගේ ඊමේල් පරීක්ෂා කරන්න',
      'enterEmailForReset': 'මුරපදය යළි සකස් කිරීමට ඔබගේ ඊමේල් ඇතුල් කරන්න',
      'passwordsDoNotMatch': 'මුරපද නොගැලපේ',
      'pleaseEnterEmail': 'ඔබගේ ඊමේල් ඇතුල් කරන්න',
      'pleaseEnterPassword': 'ඔබගේ මුරපදය ඇතුල් කරන්න',
      // Navigation
      'home': 'මුල් පිටුව',
      'myJobs': 'මගේ රැකියා',
      'messages': 'පණිවිඩ',
      'profile': 'පැතිකඩ',
      'notifications': 'දැනුම්දීම්',
      // Home
      'goodMorning': 'සුබ උදෑසනක්',
      'goodAfternoon': 'සුබ දහවලක්',
      'goodEvening': 'සුබ සන්ධ්‍යාවක්',
      'whatServiceNeed': 'ඔබට කොන් සේවාවක් අවශ්‍යද?',
      'searchServices': 'සේවා සොයන්න...',
      'categories': 'කාණ්ඩ',
      'nearbyWorkers': 'ළඟා කම්කරුවන්',
      'topRated': 'ඉහළ ශ්‍රේණිගත',
      'available': 'ලබා ගත හැකි',
      'noWorkersFound': 'කම්කරුවන් හමු නොවීය',
      // Categories
      'plumbing': 'නල කාර්මික',
      'electrical': 'විදුලි කාර්මික',
      'cleaning': 'පිරිසිදු කිරීම',
      'painting': 'තීන්ත ආලේප',
      'carpentry': 'ලී වැඩ',
      'landscaping': 'භූ දර්ශන',
      'appliances': 'ගෘහ උපකරණ',
      'security': 'ආරක්ෂාව',
      // Jobs
      'postAJob': 'රැකියාවක් පළ කරන්න',
      'jobTitle': 'රැකියා මාතෘකාව',
      'description': 'විස්තරය',
      'category': 'කාණ්ඩය',
      'budget': 'අයවැය',
      'location': 'ස්ථානය',
      'scheduledDate': 'නියමිත දිනය',
      'urgency': 'හදිසිතාව',
      'openJobs': 'විවෘත',
      'activeJobs': 'ක්‍රියාකාරී',
      'completedJobs': 'සම්පූර්ණ',
      'cancelledJobs': 'අවලංගු',
      'noJobsYet': 'තවමත් රැකියා නැත',
      'postFirstJob': 'ඔබගේ පළමු රැකියාව පළ කරන්න',
      'jobDetails': 'රැකියා විස්තර',
      'applications': 'ඉල්ලුම්පත්',
      'accept': 'පිළිගන්න',
      'reject': 'ප්‍රතික්ෂේප කරන්න',
      'cancelJob': 'රැකියාව අවලංගු කරන්න',
      'jobPosted': 'රැකියාව සාර්ථකව පළ කෙරිණ',
      'selectCategory': 'කාණ්ඩයක් තෝරන්න',
      'addJobTitle': 'රැකියා මාතෘකාවක් එකතු කරන්න',
      'describeJob': 'ඔබගේ රැකියාව විස්තර කරන්න',
      'setBudget': 'ඔබගේ අයවැය සකසන්න',
      'setLocation': 'ස්ථානය සකසන්න',
      'addPhotos': 'ඡායාරූප එකතු කරන්න',
      'low': 'අඩු',
      'normal': 'සාමාන්‍ය',
      'urgent': 'හදිසි',
      'emergency': 'හදිසි අවශ්‍යතාව',
      // Job statuses
      'statusOpen': 'විවෘත',
      'statusAssigned': 'පවරා ඇත',
      'statusInProgress': 'ප්‍රගතියෙහි',
      'statusCompleted': 'සම්පූර්ණ',
      'statusCancelled': 'අවලංගු',
      'statusReviewing': 'සමාලෝචනය',
      // Workers
      'workers': 'කම්කරුවන්',
      'workerProfile': 'කම්කරු පැතිකඩ',
      'rating': 'ශ්‍රේණිය',
      'reviews': 'සමාලෝචන',
      'jobsCompleted': 'සම්පූර්ණ කළ රැකියා',
      'hireWorker': 'කම්කරු බඳවා ගන්න',
      'noReviewsYet': 'තවමත් සමාලෝචන නැත',
      'portfolio': 'ගැළුම',
      // Messaging
      'conversations': 'පණිවිඩ',
      'typeMessage': 'පණිවිඩයක් ටයිප් කරන්න...',
      'send': 'යවන්න',
      'noConversationsYet': 'තවමත් සංවාද නැත',
      'messagePlaceholder': 'පණිවිඩයක් ටයිප් කරන්න...',
      // Payments
      'payments': 'ගෙවීම්',
      'makePayment': 'ගෙවීමක් කරන්න',
      'releasePayment': 'ගෙවීම නිදහස් කරන්න',
      'raiseDispute': 'විරෝධතාවයක් ගොනු කරන්න',
      'totalSpent': 'මුළු වියදම',
      'paymentStatus': 'ගෙවීම් තත්ත්වය',
      'paymentPending': 'රඳා පවතී',
      'paymentHeld': 'Escrow හි තබා ඇත',
      'paymentReleased': 'නිදහස් කෙරිණ',
      'paymentDisputed': 'විරෝධතා',
      // Profile/Settings
      'editProfile': 'පැතිකඩ සංස්කරණය',
      'settings': 'සැකසීම්',
      'language': 'භාෂාව',
      'helpSupport': 'උදව් සහ සහාය',
      'about': 'ඩෝවර් ගැන',
      'changePassword': 'මුරපදය වෙනස් කරන්න',
      'deleteAccount': 'ගිණුම මකන්න',
      'selectLanguage': 'භාෂාව තෝරන්න',
      'accountSettings': 'ගිණුම',
      'preferences': 'මනාපයන්',
      'support': 'සහාය',
      'version': 'අනුවාදය',
      'name': 'නම',
      'address': 'ලිපිනය',
      'updateProfile': 'පැතිකඩ යාවත්කාලීන කරන්න',
      'profileUpdated': 'පැතිකඩ සාර්ථකව යාවත්කාලීන කෙරිණ',
      'currentPassword': 'වත්මන් මුරපදය',
      'newPassword': 'නව මුරපදය',
      'passwordChanged': 'මුරපදය සාර්ථකව වෙනස් කෙරිණ',
      'deleteAccountConfirm': 'ඔබගේ ගිණුම මකා දැමීමට ඔබ ෂාස්ත්‍රීයද? මෙම ක්‍රියාව ආපසු හැරවිය නොහැක.',
      'locationServices': 'ස්ථාන සේවා',
      'enableLocationServices': 'වඩා හොඳ කම්කරු ගැළපීම සඳහා ස්ථාන සේවා සක්‍රීය කරන්න',
      // Reviews
      'leaveReview': 'සමාලෝචනයක් ලියන්න',
      'writeReview': 'ඔබගේ සමාලෝචනය ලියන්න...',
      'submitReview': 'සමාලෝචනය ඉදිරිපත් කරන්න',
      'reviewSubmitted': 'සමාලෝචනය සාර්ථකව ඉදිරිපත් කෙරිණ',
      'rateYourExperience': 'ඔබගේ අත්දැකීම ශ්‍රේණිගත කරන්න',
      // Errors
      'networkError': 'ජාල දෝෂය. ඔබගේ සම්බන්ධතාව පරීක්ෂා කරන්න.',
      'somethingWentWrong': 'යමක් වැරදී ගියේය. නැවත උත්සාහ කරන්න.',
      'tryAgain': 'නැවත උත්සාහ කරන්න',
      'sessionExpired': 'සැසිය කල් ඉකුත් විය. කරුණාකර නැවත ලොගින් වන්න.',
    },
  };
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) =>
      locale.languageCode == 'en' || locale.languageCode == 'si';

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

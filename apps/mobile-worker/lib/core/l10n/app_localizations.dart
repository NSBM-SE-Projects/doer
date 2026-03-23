import 'package:flutter/material.dart';

/// AppLocalizations provides translated strings for the worker app.
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
  String get dashboard => _t('dashboard');
  String get browse => _t('browse');
  String get myJobs => _t('myJobs');
  String get messages => _t('messages');
  String get profile => _t('profile');
  String get notifications => _t('notifications');
  String get earnings => _t('earnings');

  // ── DASHBOARD ───────────────────────────────
  String get availableJobs => _t('availableJobs');
  String get jobMatches => _t('jobMatches');
  String get noJobsAvailable => _t('noJobsAvailable');
  String get viewDetails => _t('viewDetails');
  String get applyNow => _t('applyNow');
  String get distance => _t('distance');
  String get budgetRange => _t('budgetRange');

  // ── JOBS ────────────────────────────────────
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
  String get jobDetails => _t('jobDetails');
  String get accept => _t('accept');
  String get decline => _t('decline');
  String get startJob => _t('startJob');
  String get completeJob => _t('completeJob');
  String get apply => _t('apply');
  String get applicationSent => _t('applicationSent');
  String get yourProposal => _t('yourProposal');
  String get proposedPrice => _t('proposedPrice');
  String get coverLetter => _t('coverLetter');
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

  // ── EARNINGS ────────────────────────────────
  String get totalEarned => _t('totalEarned');
  String get thisMonth => _t('thisMonth');
  String get thisWeek => _t('thisWeek');
  String get paymentHistory => _t('paymentHistory');
  String get noEarningsYet => _t('noEarningsYet');
  String get withdrawn => _t('withdrawn');
  String get pending => _t('pending');

  // ── MESSAGING ───────────────────────────────
  String get conversations => _t('conversations');
  String get typeMessage => _t('typeMessage');
  String get send => _t('send');
  String get noConversationsYet => _t('noConversationsYet');

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
  String get bio => _t('bio');
  String get updateProfile => _t('updateProfile');
  String get profileUpdated => _t('profileUpdated');
  String get currentPassword => _t('currentPassword');
  String get newPassword => _t('newPassword');
  String get passwordChanged => _t('passwordChanged');
  String get deleteAccountConfirm => _t('deleteAccountConfirm');
  String get availability => _t('availability');
  String get setAvailable => _t('setAvailable');
  String get setUnavailable => _t('setUnavailable');

  // ── VERIFICATION ────────────────────────────
  String get verification => _t('verification');
  String get nicVerification => _t('nicVerification');
  String get qualifications => _t('qualifications');
  String get backgroundCheck => _t('backgroundCheck');
  String get submitForVerification => _t('submitForVerification');
  String get pendingReview => _t('pendingReview');
  String get verified => _t('verified');
  String get rejected => _t('rejected');
  String get notSubmitted => _t('notSubmitted');
  String get uploadNic => _t('uploadNic');
  String get nicNumber => _t('nicNumber');
  String get nicFront => _t('nicFront');
  String get nicBack => _t('nicBack');
  String get uploadQualifications => _t('uploadQualifications');
  String get addDocument => _t('addDocument');
  String get badgeLevel => _t('badgeLevel');

  // ── BADGE LEVELS ────────────────────────────
  String get trainee => _t('trainee');
  String get bronze => _t('bronze');
  String get silver => _t('silver');
  String get gold => _t('gold');
  String get platinum => _t('platinum');

  // ── CATEGORIES ──────────────────────────────
  String get plumbing => _t('plumbing');
  String get electrical => _t('electrical');
  String get cleaning => _t('cleaning');
  String get painting => _t('painting');
  String get carpentry => _t('carpentry');
  String get landscaping => _t('landscaping');
  String get appliances => _t('appliances');
  String get security => _t('security');

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
      'dashboard': 'Dashboard',
      'browse': 'Browse',
      'myJobs': 'My Jobs',
      'messages': 'Messages',
      'profile': 'Profile',
      'notifications': 'Notifications',
      'earnings': 'Earnings',
      // Dashboard
      'availableJobs': 'Available Jobs',
      'jobMatches': 'Job Matches',
      'noJobsAvailable': 'No jobs available near you',
      'viewDetails': 'View Details',
      'applyNow': 'Apply Now',
      'distance': 'Distance',
      'budgetRange': 'Budget Range',
      // Jobs
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
      'jobDetails': 'Job Details',
      'accept': 'Accept',
      'decline': 'Decline',
      'startJob': 'Start Job',
      'completeJob': 'Complete Job',
      'apply': 'Apply',
      'applicationSent': 'Application sent successfully',
      'yourProposal': 'Your Proposal',
      'proposedPrice': 'Proposed Price',
      'coverLetter': 'Cover Letter',
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
      // Earnings
      'totalEarned': 'Total Earned',
      'thisMonth': 'This Month',
      'thisWeek': 'This Week',
      'paymentHistory': 'Payment History',
      'noEarningsYet': 'No earnings yet',
      'withdrawn': 'Withdrawn',
      'pending': 'Pending',
      // Messaging
      'conversations': 'Messages',
      'typeMessage': 'Type a message...',
      'send': 'Send',
      'noConversationsYet': 'No conversations yet',
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
      'bio': 'Bio',
      'updateProfile': 'Update Profile',
      'profileUpdated': 'Profile updated successfully',
      'currentPassword': 'Current Password',
      'newPassword': 'New Password',
      'passwordChanged': 'Password changed successfully',
      'deleteAccountConfirm': 'Are you sure you want to delete your account? This action cannot be undone.',
      'availability': 'Availability',
      'setAvailable': 'Set as Available',
      'setUnavailable': 'Set as Unavailable',
      // Verification
      'verification': 'Verification',
      'nicVerification': 'NIC Verification',
      'qualifications': 'Qualifications & Certificates',
      'backgroundCheck': 'Background Check',
      'submitForVerification': 'Submit for Verification',
      'pendingReview': 'Pending Review',
      'verified': 'Verified',
      'rejected': 'Rejected',
      'notSubmitted': 'Not Submitted',
      'uploadNic': 'Upload your NIC',
      'nicNumber': 'NIC Number',
      'nicFront': 'NIC Front',
      'nicBack': 'NIC Back',
      'uploadQualifications': 'Qualification Documents',
      'addDocument': 'Add Document',
      'badgeLevel': 'Badge Level',
      // Badge levels
      'trainee': 'Trainee',
      'bronze': 'Bronze',
      'silver': 'Silver',
      'gold': 'Gold',
      'platinum': 'Platinum',
      // Categories
      'plumbing': 'Plumbing',
      'electrical': 'Electrical',
      'cleaning': 'Cleaning',
      'painting': 'Painting',
      'carpentry': 'Carpentry',
      'landscaping': 'Landscaping',
      'appliances': 'Appliances',
      'security': 'Security',
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
      'dashboard': 'උපකරණ පුවරුව',
      'browse': 'රැකියා බලන්න',
      'myJobs': 'මගේ රැකියා',
      'messages': 'පණිවිඩ',
      'profile': 'පැතිකඩ',
      'notifications': 'දැනුම්දීම්',
      'earnings': 'ආදායම',
      // Dashboard
      'availableJobs': 'ලබා ගත හැකි රැකියා',
      'jobMatches': 'රැකියා ගැළපීම්',
      'noJobsAvailable': 'ඔබ ළඟ රැකියා නොමැත',
      'viewDetails': 'විස්තර බලන්න',
      'applyNow': 'දැන් ඉල්ලුම් කරන්න',
      'distance': 'දුර',
      'budgetRange': 'අයවැය පරාසය',
      // Jobs
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
      'jobDetails': 'රැකියා විස්තර',
      'accept': 'පිළිගන්න',
      'decline': 'ප්‍රතික්ෂේප කරන්න',
      'startJob': 'රැකියාව ආරම්භ කරන්න',
      'completeJob': 'රැකියාව නිම කරන්න',
      'apply': 'ඉල්ලුම් කරන්න',
      'applicationSent': 'ඉල්ලුම්පත සාර්ථකව යවන ලදී',
      'yourProposal': 'ඔබගේ යෝජනාව',
      'proposedPrice': 'යෝජිත මිල',
      'coverLetter': 'ආවරණ ලිපිය',
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
      // Earnings
      'totalEarned': 'මුළු ආදායම',
      'thisMonth': 'මෙම මාසය',
      'thisWeek': 'මෙම සතිය',
      'paymentHistory': 'ගෙවීම් ඉතිහාසය',
      'noEarningsYet': 'තවමත් ආදායමක් නැත',
      'withdrawn': 'ආපසු ගන්නා ලදී',
      'pending': 'රඳා පවතී',
      // Messaging
      'conversations': 'පණිවිඩ',
      'typeMessage': 'පණිවිඩයක් ටයිප් කරන්න...',
      'send': 'යවන්න',
      'noConversationsYet': 'තවමත් සංවාද නැත',
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
      'bio': 'ජීවනය',
      'updateProfile': 'පැතිකඩ යාවත්කාලීන කරන්න',
      'profileUpdated': 'පැතිකඩ සාර්ථකව යාවත්කාලීන කෙරිණ',
      'currentPassword': 'වත්මන් මුරපදය',
      'newPassword': 'නව මුරපදය',
      'passwordChanged': 'මුරපදය සාර්ථකව වෙනස් කෙරිණ',
      'deleteAccountConfirm': 'ඔබගේ ගිණුම මකා දැමීමට ඔබ ෂාස්ත්‍රීයද? මෙම ක්‍රියාව ආපසු හැරවිය නොහැක.',
      'availability': 'ලබා ගැනීමේ හැකියාව',
      'setAvailable': 'ලබා ගත හැකි ලෙස සකසන්න',
      'setUnavailable': 'ලබා ගත නොහැකි ලෙස සකසන්න',
      // Verification
      'verification': 'සත්‍යාපනය',
      'nicVerification': 'ජාතික හැඳුනුම්පත සත්‍යාපනය',
      'qualifications': 'සුදුසුකම් සහ සහතික',
      'backgroundCheck': 'පසුබිම් පරීක්ෂාව',
      'submitForVerification': 'සත්‍යාපනය සඳහා ඉදිරිපත් කරන්න',
      'pendingReview': 'සමාලෝචනය බලාපොරොත්තු',
      'verified': 'සත්‍යාපිත',
      'rejected': 'ප්‍රතික්ෂේප',
      'notSubmitted': 'ඉදිරිපත් කර නැත',
      'uploadNic': 'ඔබගේ ජා.හැ.ප. උඩුගත කරන්න',
      'nicNumber': 'ජා.හැ.ප. අංකය',
      'nicFront': 'ජා.හැ.ප. ඉදිරිපස',
      'nicBack': 'ජා.හැ.ප. පිටුපස',
      'uploadQualifications': 'සුදුසුකම් ලේඛන',
      'addDocument': 'ලේඛනයක් එකතු කරන්න',
      'badgeLevel': 'බැජ් මට්ටම',
      // Badge levels
      'trainee': 'පුහුණුකරු',
      'bronze': 'ලෝකඩ',
      'silver': 'රිදී',
      'gold': 'රන්',
      'platinum': 'ප්ලැටිනම්',
      // Categories
      'plumbing': 'නල කාර්මික',
      'electrical': 'විදුලි කාර්මික',
      'cleaning': 'පිරිසිදු කිරීම',
      'painting': 'තීන්ත ආලේප',
      'carpentry': 'ලී වැඩ',
      'landscaping': 'භූ දර්ශන',
      'appliances': 'ගෘහ උපකරණ',
      'security': 'ආරක්ෂාව',
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
      ['en', 'si'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

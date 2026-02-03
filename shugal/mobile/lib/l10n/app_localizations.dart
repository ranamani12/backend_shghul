import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_ar.dart';
import 'app_localizations_en.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('ar'),
    Locale('en'),
  ];

  /// Application name
  ///
  /// In en, this message translates to:
  /// **'Shugal'**
  String get appName;

  /// Splash screen tagline
  ///
  /// In en, this message translates to:
  /// **'Find Your Dream Job'**
  String get splashFindYourDreamJob;

  /// Skip button text
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get skip;

  /// Next button text
  ///
  /// In en, this message translates to:
  /// **'Next'**
  String get next;

  /// Get started button text
  ///
  /// In en, this message translates to:
  /// **'Get Started'**
  String get getStarted;

  /// First onboarding page title
  ///
  /// In en, this message translates to:
  /// **'Find Your Dream Job'**
  String get onboardingPage1Title;

  /// First onboarding page description
  ///
  /// In en, this message translates to:
  /// **'Discover thousands of job opportunities tailored to your skills and interests.'**
  String get onboardingPage1Description;

  /// Second onboarding page title
  ///
  /// In en, this message translates to:
  /// **'Connect with Companies'**
  String get onboardingPage2Title;

  /// Second onboarding page description
  ///
  /// In en, this message translates to:
  /// **'Build your professional network and connect directly with top employers.'**
  String get onboardingPage2Description;

  /// Third onboarding page title
  ///
  /// In en, this message translates to:
  /// **'Get Hired Faster'**
  String get onboardingPage3Title;

  /// Third onboarding page description
  ///
  /// In en, this message translates to:
  /// **'Create your profile, showcase your skills, and get noticed by recruiters.'**
  String get onboardingPage3Description;

  /// Home navigation label
  ///
  /// In en, this message translates to:
  /// **'Home'**
  String get home;

  /// Add navigation label
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// Profile navigation label
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get profile;

  /// Search jobs placeholder
  ///
  /// In en, this message translates to:
  /// **'Search jobs...'**
  String get searchJobs;

  /// Welcome message
  ///
  /// In en, this message translates to:
  /// **'Welcome to Shugal'**
  String get welcomeToShugal;

  /// Guest mode description
  ///
  /// In en, this message translates to:
  /// **'Browse jobs as a guest or sign in to unlock more features'**
  String get browseJobsAsGuest;

  /// Login prompt title
  ///
  /// In en, this message translates to:
  /// **'Get the Full Experience'**
  String get getTheFullExperience;

  /// Login prompt description
  ///
  /// In en, this message translates to:
  /// **'Sign in or create an account to apply for jobs, save favorites, and connect with employers.'**
  String get signInToUnlock;

  /// Login button text
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// Register button text
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// Latest jobs section title
  ///
  /// In en, this message translates to:
  /// **'Latest Jobs'**
  String get latestJobs;

  /// View details button text
  ///
  /// In en, this message translates to:
  /// **'View Details'**
  String get viewDetails;

  /// Notification login prompt
  ///
  /// In en, this message translates to:
  /// **'Please login to view notifications'**
  String get pleaseLoginToViewNotifications;

  /// Add content login prompt
  ///
  /// In en, this message translates to:
  /// **'Login required to post jobs or content'**
  String get loginRequiredToPost;

  /// Apply job login prompt
  ///
  /// In en, this message translates to:
  /// **'Login to apply for jobs'**
  String get loginRequiredToApply;

  /// Save job login prompt
  ///
  /// In en, this message translates to:
  /// **'Login to save jobs'**
  String get loginToSaveJobs;

  /// Guest mode label
  ///
  /// In en, this message translates to:
  /// **'Guest Mode'**
  String get guestMode;

  /// Guest mode description
  ///
  /// In en, this message translates to:
  /// **'You are browsing as a guest'**
  String get youAreBrowsingAsGuest;

  /// Login or register button text
  ///
  /// In en, this message translates to:
  /// **'Login or Register'**
  String get loginOrRegister;

  /// Add content section title
  ///
  /// In en, this message translates to:
  /// **'Add New Content'**
  String get addNewContent;

  /// Coming soon message
  ///
  /// In en, this message translates to:
  /// **'Login screen coming soon'**
  String get loginScreenComingSoon;

  /// Coming soon message
  ///
  /// In en, this message translates to:
  /// **'Register screen coming soon'**
  String get registerScreenComingSoon;

  /// Login required dialog title
  ///
  /// In en, this message translates to:
  /// **'Login Required'**
  String get loginRequired;

  /// Please login message with feature
  ///
  /// In en, this message translates to:
  /// **'Please login to access {feature}.'**
  String pleaseLoginToAccess(String feature);

  /// Cancel button text
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// Language dialog title
  ///
  /// In en, this message translates to:
  /// **'Choose Language'**
  String get chooseLanguage;

  /// English language option
  ///
  /// In en, this message translates to:
  /// **'English'**
  String get english;

  /// Arabic language option
  ///
  /// In en, this message translates to:
  /// **'Arabic'**
  String get arabic;

  /// Save button text
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// Language changed snackbar message
  ///
  /// In en, this message translates to:
  /// **'Language changed'**
  String get languageChanged;

  /// Welcome back greeting
  ///
  /// In en, this message translates to:
  /// **'Welcome back'**
  String get welcomeBack;

  /// Sign in subtitle
  ///
  /// In en, this message translates to:
  /// **'Sign in to Your Account'**
  String get signInToYourAccount;

  /// Email field label
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// Email field placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter Email Address'**
  String get enterEmailAddress;

  /// Password field label
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// Password field placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter Password'**
  String get enterPassword;

  /// Remember me checkbox label
  ///
  /// In en, this message translates to:
  /// **'Remember me'**
  String get rememberMe;

  /// Forgot password link
  ///
  /// In en, this message translates to:
  /// **'Forgot Password?'**
  String get forgotPassword;

  /// Don't have account text
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account?'**
  String get dontHaveAccount;

  /// Sign up link text
  ///
  /// In en, this message translates to:
  /// **'Sign Up'**
  String get signUp;

  /// Validation error message
  ///
  /// In en, this message translates to:
  /// **'Please fill in all fields'**
  String get pleaseFillAllFields;

  /// Login failed message
  ///
  /// In en, this message translates to:
  /// **'Login failed. Please try again.'**
  String get loginFailed;

  /// Company role label
  ///
  /// In en, this message translates to:
  /// **'Company'**
  String get company;

  /// Job seeker role label
  ///
  /// In en, this message translates to:
  /// **'Job Seeker'**
  String get jobSeeker;

  /// Register screen title
  ///
  /// In en, this message translates to:
  /// **'Let\'s get you started'**
  String get letsGetYouStarted;

  /// Register screen subtitle
  ///
  /// In en, this message translates to:
  /// **'Please fill in your details to create an account'**
  String get fillDetailsToCreateAccount;

  /// Phone number field label
  ///
  /// In en, this message translates to:
  /// **'Phone Number'**
  String get phoneNumber;

  /// Company name field label
  ///
  /// In en, this message translates to:
  /// **'Company Name'**
  String get companyName;

  /// Company name field placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter Company Name'**
  String get enterCompanyName;

  /// Name field label
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get name;

  /// Name field placeholder
  ///
  /// In en, this message translates to:
  /// **'Enter Your Name'**
  String get enterYourName;

  /// Date of birth field label
  ///
  /// In en, this message translates to:
  /// **'Date of Birth'**
  String get dateOfBirth;

  /// Select placeholder
  ///
  /// In en, this message translates to:
  /// **'Select'**
  String get select;

  /// Nationality field label
  ///
  /// In en, this message translates to:
  /// **'Nationality'**
  String get nationality;

  /// Choose placeholder
  ///
  /// In en, this message translates to:
  /// **'Choose'**
  String get choose;

  /// Residence country field label
  ///
  /// In en, this message translates to:
  /// **'Residents Country'**
  String get residentsCountry;

  /// Major field label
  ///
  /// In en, this message translates to:
  /// **'Major'**
  String get major;

  /// Education level field label
  ///
  /// In en, this message translates to:
  /// **'Educational Level'**
  String get educationalLevel;

  /// Experience field label
  ///
  /// In en, this message translates to:
  /// **'Years of Experience'**
  String get yearsOfExperience;

  /// Have account text
  ///
  /// In en, this message translates to:
  /// **'Have an account?'**
  String get haveAnAccount;

  /// Email validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get pleaseEnterEmail;

  /// Phone validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter your phone number'**
  String get pleaseEnterPhone;

  /// Company name validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter company name'**
  String get pleaseEnterCompanyName;

  /// Name validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter your name'**
  String get pleaseEnterName;

  /// Registration failed message
  ///
  /// In en, this message translates to:
  /// **'Registration failed. Please try again.'**
  String get registrationFailed;

  /// Loading text
  ///
  /// In en, this message translates to:
  /// **'Loading...'**
  String get loading;

  /// Search placeholder
  ///
  /// In en, this message translates to:
  /// **'Search...'**
  String get search;

  /// No items found message
  ///
  /// In en, this message translates to:
  /// **'No items found'**
  String get noItemsFound;

  /// Done button text
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get done;

  /// Selected suffix text
  ///
  /// In en, this message translates to:
  /// **'selected'**
  String get selected;

  /// Welcome guest text
  ///
  /// In en, this message translates to:
  /// **'Welcome, Guest!'**
  String get welcomeGuest;

  /// Login prompt for guest
  ///
  /// In en, this message translates to:
  /// **'Login to access all features'**
  String get loginToAccessAllFeatures;

  /// Customer service menu item
  ///
  /// In en, this message translates to:
  /// **'Customer Service Support'**
  String get customerServiceSupport;

  /// Privacy policy menu item
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy'**
  String get privacyPolicy;

  /// Login required info label
  ///
  /// In en, this message translates to:
  /// **'Login required to access:'**
  String get loginRequiredToAccessLabel;

  /// Edit profile feature
  ///
  /// In en, this message translates to:
  /// **'Edit Profile'**
  String get editProfile;

  /// Apply for jobs feature
  ///
  /// In en, this message translates to:
  /// **'Apply for Jobs'**
  String get applyForJobs;

  /// Chat feature
  ///
  /// In en, this message translates to:
  /// **'Chat with Companies'**
  String get chatWithCompanies;

  /// View application history feature
  ///
  /// In en, this message translates to:
  /// **'View Application History'**
  String get viewApplicationHistory;

  /// Post ads feature
  ///
  /// In en, this message translates to:
  /// **'Post Ads'**
  String get postAds;

  /// Profile setting menu item
  ///
  /// In en, this message translates to:
  /// **'Profile Setting'**
  String get profileSetting;

  /// Change password menu item
  ///
  /// In en, this message translates to:
  /// **'Change Password'**
  String get changePassword;

  /// History menu item
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get history;

  /// Logout menu item
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// Company profile setting menu item
  ///
  /// In en, this message translates to:
  /// **'Company Profile Setting'**
  String get companyProfileSetting;

  /// Applications received menu item
  ///
  /// In en, this message translates to:
  /// **'Applications Received'**
  String get applicationsReceived;

  /// Logout success message
  ///
  /// In en, this message translates to:
  /// **'Logged out successfully'**
  String get loggedOutSuccessfully;

  /// Logout failed message
  ///
  /// In en, this message translates to:
  /// **'Logout failed'**
  String get logoutFailed;

  /// Logout confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure to log out of\nyour account?'**
  String get areYouSureLogout;

  /// Job offer section title
  ///
  /// In en, this message translates to:
  /// **'Job Offer'**
  String get jobOffer;

  /// See all link
  ///
  /// In en, this message translates to:
  /// **'See All'**
  String get seeAll;

  /// Failed to load jobs error
  ///
  /// In en, this message translates to:
  /// **'Failed to load jobs'**
  String get failedToLoadJobs;

  /// Retry button text
  ///
  /// In en, this message translates to:
  /// **'Retry'**
  String get retry;

  /// No jobs message
  ///
  /// In en, this message translates to:
  /// **'No jobs available'**
  String get noJobsAvailable;

  /// Candidates section title
  ///
  /// In en, this message translates to:
  /// **'Candidates'**
  String get candidates;

  /// Failed to load candidates error
  ///
  /// In en, this message translates to:
  /// **'Failed to load candidates'**
  String get failedToLoadCandidates;

  /// No candidates message
  ///
  /// In en, this message translates to:
  /// **'No candidates available'**
  String get noCandidatesAvailable;

  /// Unknown company placeholder
  ///
  /// In en, this message translates to:
  /// **'Unknown Company'**
  String get unknownCompany;

  /// Salary not specified placeholder
  ///
  /// In en, this message translates to:
  /// **'Salary not specified'**
  String get salaryNotSpecified;

  /// Professional title placeholder
  ///
  /// In en, this message translates to:
  /// **'Professional'**
  String get professional;

  /// Login required title
  ///
  /// In en, this message translates to:
  /// **'Login required'**
  String get loginRequiredLabel;

  /// Login prompt for posting
  ///
  /// In en, this message translates to:
  /// **'Please login or create an account to post an ad.'**
  String get pleaseLoginOrCreateAccount;

  /// Post ad title
  ///
  /// In en, this message translates to:
  /// **'Post Ad'**
  String get postAd;

  /// Post ad coming soon message
  ///
  /// In en, this message translates to:
  /// **'Post Ad form coming soon.'**
  String get postAdFormComingSoon;

  /// Interview screen title
  ///
  /// In en, this message translates to:
  /// **'Interview'**
  String get interview;

  /// Interviews navigation label
  ///
  /// In en, this message translates to:
  /// **'Interviews'**
  String get interviews;

  /// Recruit navigation label
  ///
  /// In en, this message translates to:
  /// **'Recruit'**
  String get recruit;

  /// Please login message
  ///
  /// In en, this message translates to:
  /// **'Please login to continue'**
  String get pleaseLoginToContinue;

  /// Failed to load interviews error
  ///
  /// In en, this message translates to:
  /// **'Failed to load interviews. Please try again.'**
  String get failedToLoadInterviews;

  /// No interviews message
  ///
  /// In en, this message translates to:
  /// **'No interviews scheduled\nfor this day'**
  String get noInterviewsScheduled;

  /// Physical interview type
  ///
  /// In en, this message translates to:
  /// **'Physical Interview'**
  String get physicalInterview;

  /// Online interview type
  ///
  /// In en, this message translates to:
  /// **'Online Interview'**
  String get onlineInterview;

  /// Phone interview type
  ///
  /// In en, this message translates to:
  /// **'Phone Interview'**
  String get phoneInterview;

  /// Not scheduled time placeholder
  ///
  /// In en, this message translates to:
  /// **'Not scheduled'**
  String get notScheduled;

  /// Invalid time placeholder
  ///
  /// In en, this message translates to:
  /// **'Invalid time'**
  String get invalidTime;

  /// Notifications feature name
  ///
  /// In en, this message translates to:
  /// **'notifications'**
  String get notifications;

  /// Chat feature name
  ///
  /// In en, this message translates to:
  /// **'chat'**
  String get chat;

  /// Forgot password screen title
  ///
  /// In en, this message translates to:
  /// **'Forgot Password'**
  String get forgotPasswordTitle;

  /// Forgot password description
  ///
  /// In en, this message translates to:
  /// **'Please enter your email for verification the account.'**
  String get pleaseEnterEmailForVerification;

  /// Send OTP button text
  ///
  /// In en, this message translates to:
  /// **'Send OTP'**
  String get sendOtp;

  /// Enter OTP code title
  ///
  /// In en, this message translates to:
  /// **'Enter OTP Code'**
  String get enterOtpCode;

  /// OTP sent message
  ///
  /// In en, this message translates to:
  /// **'We have sent OTP code to your email'**
  String get weSentCodeTo;

  /// Resend code link
  ///
  /// In en, this message translates to:
  /// **'Resend Code'**
  String get resendCode;

  /// Didnt receive code text
  ///
  /// In en, this message translates to:
  /// **'Didn\'t receive a code?'**
  String get didntReceiveCode;

  /// Verify button text
  ///
  /// In en, this message translates to:
  /// **'Verify'**
  String get verify;

  /// Reset password screen title
  ///
  /// In en, this message translates to:
  /// **'Reset Password'**
  String get resetPassword;

  /// Reset password description
  ///
  /// In en, this message translates to:
  /// **'Create a new secure password for your account.'**
  String get createNewPassword;

  /// New password field label
  ///
  /// In en, this message translates to:
  /// **'New Password'**
  String get newPassword;

  /// Confirm password field label
  ///
  /// In en, this message translates to:
  /// **'Confirm Password'**
  String get confirmPassword;

  /// Password mismatch error
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get passwordsDoNotMatch;

  /// Password reset success message
  ///
  /// In en, this message translates to:
  /// **'Password reset successfully'**
  String get passwordResetSuccess;

  /// New password validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter a new password'**
  String get pleaseEnterNewPassword;

  /// OTP verification screen title
  ///
  /// In en, this message translates to:
  /// **'OTP Verification'**
  String get otpVerification;

  /// Verify email title
  ///
  /// In en, this message translates to:
  /// **'Verify Your Email'**
  String get verifyYourEmail;

  /// Verification code sent message
  ///
  /// In en, this message translates to:
  /// **'We have sent a verification code to'**
  String get verificationCodeSentTo;

  /// OTP validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter the OTP code'**
  String get pleaseEnterOtp;

  /// OTP verified success message
  ///
  /// In en, this message translates to:
  /// **'OTP verified successfully'**
  String get otpVerified;

  /// Invalid OTP error
  ///
  /// In en, this message translates to:
  /// **'Invalid OTP code'**
  String get invalidOtp;

  /// OTP resent message
  ///
  /// In en, this message translates to:
  /// **'OTP code resent'**
  String get otpResent;

  /// OTP sent to email title
  ///
  /// In en, this message translates to:
  /// **'We have sent an OTP code to your email.'**
  String get weSentOtpToEmail;

  /// OTP code sent description
  ///
  /// In en, this message translates to:
  /// **'We have just sent you a 6-digit code via your email {email}'**
  String weSentSixDigitCode(String email);

  /// OTP validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter the complete 6-digit code'**
  String get pleaseEnterCompleteCode;

  /// OTP resent success message
  ///
  /// In en, this message translates to:
  /// **'OTP code has been resent to your email'**
  String get otpResentToEmail;

  /// Verify OTP button text
  ///
  /// In en, this message translates to:
  /// **'Verify OTP'**
  String get verifyOtp;

  /// Resend OTP button text
  ///
  /// In en, this message translates to:
  /// **'Resend OTP'**
  String get resendOtp;

  /// Create new password title
  ///
  /// In en, this message translates to:
  /// **'Create New Password'**
  String get createNewPasswordTitle;

  /// New password description
  ///
  /// In en, this message translates to:
  /// **'Enter your new password. Remember this time!'**
  String get enterNewPasswordRemember;

  /// New password hint
  ///
  /// In en, this message translates to:
  /// **'Enter New Password'**
  String get enterNewPassword;

  /// Confirm password hint
  ///
  /// In en, this message translates to:
  /// **'Enter Confirm Password'**
  String get enterConfirmPassword;

  /// Password length validation error
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters'**
  String get passwordMinLength;

  /// Password reset success message
  ///
  /// In en, this message translates to:
  /// **'Password reset successfully! Please login with your new password.'**
  String get passwordResetSuccessLogin;

  /// Verify email title
  ///
  /// In en, this message translates to:
  /// **'Verify Email'**
  String get verifyEmail;

  /// Verification code sent message
  ///
  /// In en, this message translates to:
  /// **'We\'ve sent a verification code to'**
  String get weSentVerificationCodeTo;

  /// Email verified success message
  ///
  /// In en, this message translates to:
  /// **'Email verified successfully!'**
  String get emailVerifiedSuccessfully;

  /// Digital resume navigation label
  ///
  /// In en, this message translates to:
  /// **'Digital Resume'**
  String get digitalResume;

  /// Generic data load error
  ///
  /// In en, this message translates to:
  /// **'Failed to load data. Please try again.'**
  String get failedToLoadData;

  /// Empty jobs message for company
  ///
  /// In en, this message translates to:
  /// **'No jobs posted yet'**
  String get noJobsPosted;

  /// Default job title placeholder
  ///
  /// In en, this message translates to:
  /// **'Untitled Job'**
  String get untitledJob;

  /// Salary to be determined
  ///
  /// In en, this message translates to:
  /// **'Salary TBD'**
  String get salaryTbd;

  /// Number of applicants
  ///
  /// In en, this message translates to:
  /// **'{count} Applicants'**
  String applicantsCount(int count);

  /// View applicants button
  ///
  /// In en, this message translates to:
  /// **'View Applicants'**
  String get viewApplicants;

  /// Unlock candidate button
  ///
  /// In en, this message translates to:
  /// **'Unlock'**
  String get unlock;

  /// View profile button
  ///
  /// In en, this message translates to:
  /// **'View Profile'**
  String get viewProfile;

  /// Unknown name placeholder
  ///
  /// In en, this message translates to:
  /// **'Unknown'**
  String get unknown;

  /// Generic error message
  ///
  /// In en, this message translates to:
  /// **'An error occurred'**
  String get anErrorOccurred;

  /// All filter label
  ///
  /// In en, this message translates to:
  /// **'All'**
  String get all;

  /// Unlocked filter label
  ///
  /// In en, this message translates to:
  /// **'Unlocked'**
  String get unlocked;

  /// Locked filter label
  ///
  /// In en, this message translates to:
  /// **'Locked'**
  String get locked;

  /// Candidate unlock success message
  ///
  /// In en, this message translates to:
  /// **'Candidate unlocked successfully'**
  String get candidateUnlockedSuccessfully;

  /// Candidate unlock error message
  ///
  /// In en, this message translates to:
  /// **'Failed to unlock candidate. Please try again.'**
  String get failedToUnlockCandidate;

  /// No candidates found message
  ///
  /// In en, this message translates to:
  /// **'No candidates found'**
  String get noCandidatesFound;

  /// Detail button text
  ///
  /// In en, this message translates to:
  /// **'Detail'**
  String get detail;

  /// Unlock candidate dialog title
  ///
  /// In en, this message translates to:
  /// **'Unlock Candidate'**
  String get unlockCandidate;

  /// Unlock candidate confirmation message
  ///
  /// In en, this message translates to:
  /// **'Are you sure you want to unlock this candidate? A fee may be charged.'**
  String get unlockCandidateConfirmation;

  /// Full time job type
  ///
  /// In en, this message translates to:
  /// **'Full Time'**
  String get fullTime;

  /// Part time job type
  ///
  /// In en, this message translates to:
  /// **'Part Time'**
  String get partTime;

  /// Remote job type
  ///
  /// In en, this message translates to:
  /// **'Remote'**
  String get remote;

  /// No job postings message
  ///
  /// In en, this message translates to:
  /// **'No job postings yet'**
  String get noJobPostingsYet;

  /// Number of applications short
  ///
  /// In en, this message translates to:
  /// **'{count} apps'**
  String applicationsCount(int count);

  /// Edit job screen title
  ///
  /// In en, this message translates to:
  /// **'Edit Job'**
  String get editJob;

  /// Create job screen title
  ///
  /// In en, this message translates to:
  /// **'Create Job'**
  String get createJob;

  /// Form header text
  ///
  /// In en, this message translates to:
  /// **'Fill it'**
  String get fillIt;

  /// Job title field label
  ///
  /// In en, this message translates to:
  /// **'Job Title'**
  String get jobTitle;

  /// Job title field hint
  ///
  /// In en, this message translates to:
  /// **'Enter job title'**
  String get enterJobTitle;

  /// Salary range field label
  ///
  /// In en, this message translates to:
  /// **'Salary Range'**
  String get salaryRange;

  /// Salary range field hint
  ///
  /// In en, this message translates to:
  /// **'e.g. 300-500 KWD'**
  String get salaryRangeHint;

  /// Experience level dropdown hint
  ///
  /// In en, this message translates to:
  /// **'Select experience level'**
  String get selectExperienceLevel;

  /// Hiring type field label
  ///
  /// In en, this message translates to:
  /// **'Type of Hiring'**
  String get typeOfHiring;

  /// Hiring type dropdown hint
  ///
  /// In en, this message translates to:
  /// **'Select hiring timeframe'**
  String get selectHiringTimeframe;

  /// Employment type field label
  ///
  /// In en, this message translates to:
  /// **'Employment Type'**
  String get employmentType;

  /// Employment type dropdown hint
  ///
  /// In en, this message translates to:
  /// **'Select employment type'**
  String get selectEmploymentType;

  /// Work location field label
  ///
  /// In en, this message translates to:
  /// **'Work Location'**
  String get workLocation;

  /// Work location dropdown hint
  ///
  /// In en, this message translates to:
  /// **'Select work location'**
  String get selectWorkLocation;

  /// Job description field label
  ///
  /// In en, this message translates to:
  /// **'Job Description'**
  String get jobDescription;

  /// Job description field hint
  ///
  /// In en, this message translates to:
  /// **'Write job description...'**
  String get writeJobDescription;

  /// Interview type field label
  ///
  /// In en, this message translates to:
  /// **'Type of Interview'**
  String get typeOfInterview;

  /// Physical interview type
  ///
  /// In en, this message translates to:
  /// **'Physical'**
  String get physical;

  /// Online interview type
  ///
  /// In en, this message translates to:
  /// **'Online'**
  String get online;

  /// Loading majors text
  ///
  /// In en, this message translates to:
  /// **'Loading majors...'**
  String get loadingMajors;

  /// Select majors button text
  ///
  /// In en, this message translates to:
  /// **'Select majors'**
  String get selectMajors;

  /// Update job button text
  ///
  /// In en, this message translates to:
  /// **'Update Job'**
  String get updateJob;

  /// Job title validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter job title'**
  String get pleaseEnterJobTitle;

  /// Job description validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter job description'**
  String get pleaseEnterJobDescription;

  /// Job update success message
  ///
  /// In en, this message translates to:
  /// **'Job updated successfully'**
  String get jobUpdatedSuccessfully;

  /// Job create success message
  ///
  /// In en, this message translates to:
  /// **'Job created successfully'**
  String get jobCreatedSuccessfully;

  /// Immediate hiring type
  ///
  /// In en, this message translates to:
  /// **'Immediate'**
  String get immediate;

  /// Within 1 month hiring type
  ///
  /// In en, this message translates to:
  /// **'Within 1 Month'**
  String get within1Month;

  /// Within 3 months hiring type
  ///
  /// In en, this message translates to:
  /// **'Within 3 Months'**
  String get within3Months;

  /// Flexible hiring type
  ///
  /// In en, this message translates to:
  /// **'Flexible'**
  String get flexible;

  /// Contract employment type
  ///
  /// In en, this message translates to:
  /// **'Contract'**
  String get contract;

  /// On-site job type
  ///
  /// In en, this message translates to:
  /// **'On-site'**
  String get onSite;

  /// Hybrid job type
  ///
  /// In en, this message translates to:
  /// **'Hybrid'**
  String get hybrid;

  /// Job details screen title
  ///
  /// In en, this message translates to:
  /// **'Job Details'**
  String get jobDetails;

  /// No description placeholder
  ///
  /// In en, this message translates to:
  /// **'No description provided'**
  String get noDescriptionProvided;

  /// Not specified placeholder
  ///
  /// In en, this message translates to:
  /// **'Not specified'**
  String get notSpecified;

  /// Active status label
  ///
  /// In en, this message translates to:
  /// **'Active'**
  String get active;

  /// Inactive status label
  ///
  /// In en, this message translates to:
  /// **'Inactive'**
  String get inactive;

  /// Number of applications
  ///
  /// In en, this message translates to:
  /// **'{count} applications'**
  String applications(int count);

  /// Job specifications section title
  ///
  /// In en, this message translates to:
  /// **'Job Specifications'**
  String get jobSpecifications;

  /// Hiring type label
  ///
  /// In en, this message translates to:
  /// **'Hiring Type'**
  String get hiringType;

  /// Experience label
  ///
  /// In en, this message translates to:
  /// **'Experience'**
  String get experience;

  /// Required majors section title
  ///
  /// In en, this message translates to:
  /// **'Required Majors'**
  String get requiredMajors;

  /// Description section title
  ///
  /// In en, this message translates to:
  /// **'Description'**
  String get description;

  /// Requirements section title
  ///
  /// In en, this message translates to:
  /// **'Requirements'**
  String get requirements;

  /// View applicants button with count
  ///
  /// In en, this message translates to:
  /// **'View Applicants ({count})'**
  String viewApplicantsCount(int count);

  /// Job applicants screen title
  ///
  /// In en, this message translates to:
  /// **'Job Applicants'**
  String get jobApplicants;

  /// Pending status
  ///
  /// In en, this message translates to:
  /// **'Pending'**
  String get pending;

  /// Reviewed status
  ///
  /// In en, this message translates to:
  /// **'Reviewed'**
  String get reviewed;

  /// Shortlisted status
  ///
  /// In en, this message translates to:
  /// **'Shortlisted'**
  String get shortlisted;

  /// Rejected status
  ///
  /// In en, this message translates to:
  /// **'Rejected'**
  String get rejected;

  /// Failed to load applicants error
  ///
  /// In en, this message translates to:
  /// **'Failed to load applicants. Please try again.'**
  String get failedToLoadApplicants;

  /// Single applicant count
  ///
  /// In en, this message translates to:
  /// **'{count} Applicant'**
  String applicantCount(int count);

  /// Multiple applicants count
  ///
  /// In en, this message translates to:
  /// **'{count} Applicants'**
  String applicantCountPlural(int count);

  /// No applicants message
  ///
  /// In en, this message translates to:
  /// **'No applicants yet'**
  String get noApplicantsYet;

  /// Applications appear here hint
  ///
  /// In en, this message translates to:
  /// **'Applications will appear here'**
  String get applicationsWillAppearHere;

  /// Search applicants hint
  ///
  /// In en, this message translates to:
  /// **'Search applicants...'**
  String get searchApplicants;

  /// Recently time label
  ///
  /// In en, this message translates to:
  /// **'Recently'**
  String get recently;

  /// Minutes ago
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String minutesAgo(int count);

  /// Hours ago
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String hoursAgo(int count);

  /// One day ago
  ///
  /// In en, this message translates to:
  /// **'1 day ago'**
  String get dayAgo;

  /// Days ago
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String daysAgo(int count);

  /// Weeks ago
  ///
  /// In en, this message translates to:
  /// **'{count}w ago'**
  String weeksAgo(int count);

  /// Has cover letter label
  ///
  /// In en, this message translates to:
  /// **'Has cover letter'**
  String get hasCoverLetter;

  /// View button
  ///
  /// In en, this message translates to:
  /// **'View'**
  String get view;

  /// Job label
  ///
  /// In en, this message translates to:
  /// **'Job'**
  String get job;

  /// Candidate profile screen title
  ///
  /// In en, this message translates to:
  /// **'Candidate Profile'**
  String get candidateProfile;

  /// Could not open CV error
  ///
  /// In en, this message translates to:
  /// **'Could not open CV'**
  String get couldNotOpenCv;

  /// Resident label
  ///
  /// In en, this message translates to:
  /// **'Resident'**
  String get resident;

  /// Availability label
  ///
  /// In en, this message translates to:
  /// **'Availability'**
  String get availability;

  /// Experience and education section title
  ///
  /// In en, this message translates to:
  /// **'Experience & Education'**
  String get experienceAndEducation;

  /// Education label
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get education;

  /// About section title
  ///
  /// In en, this message translates to:
  /// **'About'**
  String get about;

  /// Fields/majors section title
  ///
  /// In en, this message translates to:
  /// **'Fields / Majors'**
  String get fieldsMajors;

  /// Skills section title
  ///
  /// In en, this message translates to:
  /// **'Skills'**
  String get skills;

  /// CV/Resume section title
  ///
  /// In en, this message translates to:
  /// **'CV / Resume'**
  String get cvResume;

  /// Candidate resume title
  ///
  /// In en, this message translates to:
  /// **'Candidate Resume'**
  String get candidateResume;

  /// Tap to view or download hint
  ///
  /// In en, this message translates to:
  /// **'Tap to view or download'**
  String get tapToViewOrDownload;

  /// External profile section title
  ///
  /// In en, this message translates to:
  /// **'External Profile'**
  String get externalProfile;

  /// Upwork profile title
  ///
  /// In en, this message translates to:
  /// **'Upwork Profile'**
  String get upworkProfile;

  /// View external profile hint
  ///
  /// In en, this message translates to:
  /// **'View external profile'**
  String get viewExternalProfile;

  /// Profile locked title
  ///
  /// In en, this message translates to:
  /// **'Profile Locked'**
  String get profileLocked;

  /// Unlock candidate description
  ///
  /// In en, this message translates to:
  /// **'Unlock this candidate to view their complete profile including:\n\n• Contact Information\n• CV / Resume\n• Skills & Summary\n• Personal Details'**
  String get unlockCandidateDescription;

  /// Send message button
  ///
  /// In en, this message translates to:
  /// **'Send Message'**
  String get sendMessage;

  /// Schedule interview screen title
  ///
  /// In en, this message translates to:
  /// **'Schedule Interview'**
  String get scheduleInterview;

  /// Invalid candidate error
  ///
  /// In en, this message translates to:
  /// **'Invalid candidate'**
  String get invalidCandidate;

  /// Interview scheduled success message
  ///
  /// In en, this message translates to:
  /// **'Interview scheduled successfully!'**
  String get interviewScheduledSuccessfully;

  /// Failed to schedule interview error
  ///
  /// In en, this message translates to:
  /// **'Failed to schedule interview'**
  String get failedToScheduleInterview;

  /// Job application label
  ///
  /// In en, this message translates to:
  /// **'Job Application'**
  String get jobApplication;

  /// Contact information section title
  ///
  /// In en, this message translates to:
  /// **'Contact Information'**
  String get contactInformation;

  /// Interview details section title
  ///
  /// In en, this message translates to:
  /// **'Interview Details'**
  String get interviewDetails;

  /// Type of interview label
  ///
  /// In en, this message translates to:
  /// **'Type Of Interview'**
  String get typeOfInterviewLabel;

  /// Interview date label
  ///
  /// In en, this message translates to:
  /// **'Interview Date'**
  String get interviewDate;

  /// Time label
  ///
  /// In en, this message translates to:
  /// **'Time'**
  String get time;

  /// Meeting link label
  ///
  /// In en, this message translates to:
  /// **'Meeting Link'**
  String get meetingLink;

  /// Interview location label
  ///
  /// In en, this message translates to:
  /// **'Interview Location'**
  String get interviewLocation;

  /// Enter meeting link hint
  ///
  /// In en, this message translates to:
  /// **'Enter meeting link (Zoom, Google Meet, etc.)'**
  String get enterMeetingLink;

  /// Enter interview location hint
  ///
  /// In en, this message translates to:
  /// **'Enter interview location address'**
  String get enterInterviewLocation;

  /// Additional notes label
  ///
  /// In en, this message translates to:
  /// **'Additional Notes (Optional)'**
  String get additionalNotes;

  /// Additional notes hint
  ///
  /// In en, this message translates to:
  /// **'Add any additional information for the candidate...'**
  String get additionalNotesHint;

  /// Phone interview type
  ///
  /// In en, this message translates to:
  /// **'Phone'**
  String get phone;

  /// Applicant details screen title
  ///
  /// In en, this message translates to:
  /// **'Applicant Details'**
  String get applicantDetails;

  /// Application info section title
  ///
  /// In en, this message translates to:
  /// **'Application Info'**
  String get applicationInfo;

  /// Applied for label
  ///
  /// In en, this message translates to:
  /// **'Applied For'**
  String get appliedFor;

  /// Applied on label
  ///
  /// In en, this message translates to:
  /// **'Applied On'**
  String get appliedOn;

  /// Status label
  ///
  /// In en, this message translates to:
  /// **'Status'**
  String get status;

  /// Cover letter section title
  ///
  /// In en, this message translates to:
  /// **'Cover Letter'**
  String get coverLetter;

  /// Applicant resume title
  ///
  /// In en, this message translates to:
  /// **'Applicant Resume'**
  String get applicantResume;

  /// Message button
  ///
  /// In en, this message translates to:
  /// **'Message'**
  String get message;

  /// Scheduled label
  ///
  /// In en, this message translates to:
  /// **'scheduled'**
  String get scheduled;

  /// Failed to load meetings error
  ///
  /// In en, this message translates to:
  /// **'Failed to load meetings. Please try again.'**
  String get failedToLoadMeetings;

  /// No interviews message short
  ///
  /// In en, this message translates to:
  /// **'No interviews scheduled'**
  String get noInterviewsScheduledShort;

  /// Interviews appear here hint
  ///
  /// In en, this message translates to:
  /// **'Interviews for this day will appear here'**
  String get interviewsWillAppearHere;

  /// Expected salary label
  ///
  /// In en, this message translates to:
  /// **'Expected Salary'**
  String get expectedSalary;

  /// Working hours label
  ///
  /// In en, this message translates to:
  /// **'Working Hours'**
  String get workingHours;

  /// About company section title
  ///
  /// In en, this message translates to:
  /// **'About Company'**
  String get aboutCompany;

  /// Follow button text
  ///
  /// In en, this message translates to:
  /// **'Follow'**
  String get follow;

  /// Read more button text
  ///
  /// In en, this message translates to:
  /// **'Read More'**
  String get readMore;

  /// Read less button text
  ///
  /// In en, this message translates to:
  /// **'Read Less'**
  String get readLess;

  /// Login prompt for applying
  ///
  /// In en, this message translates to:
  /// **'Please login or create an account to apply for jobs.'**
  String get pleaseLoginToApplyForJobs;

  /// Profile activation required title
  ///
  /// In en, this message translates to:
  /// **'Profile Activation Required'**
  String get profileActivationRequired;

  /// Activate profile description
  ///
  /// In en, this message translates to:
  /// **'You need to activate your profile before applying for jobs. A small one-time activation fee is required.'**
  String get activateProfileDescription;

  /// Activate now button text
  ///
  /// In en, this message translates to:
  /// **'Activate Now'**
  String get activateNow;

  /// Already applied button text
  ///
  /// In en, this message translates to:
  /// **'Already Applied'**
  String get alreadyApplied;

  /// Apply now button text
  ///
  /// In en, this message translates to:
  /// **'Apply Now'**
  String get applyNow;

  /// Apply job modal title
  ///
  /// In en, this message translates to:
  /// **'Apply This Job?'**
  String get applyThisJob;

  /// Cover letter optional label
  ///
  /// In en, this message translates to:
  /// **'Cover Letter (Optional)'**
  String get coverLetterOptional;

  /// Cover letter hint text
  ///
  /// In en, this message translates to:
  /// **'Write a brief cover letter to introduce yourself...'**
  String get coverLetterHint;

  /// Submit application button text
  ///
  /// In en, this message translates to:
  /// **'Submit Application'**
  String get submitApplication;

  /// Application submitted success message
  ///
  /// In en, this message translates to:
  /// **'Application submitted successfully!'**
  String get applicationSubmittedSuccessfully;

  /// Invalid job error
  ///
  /// In en, this message translates to:
  /// **'Invalid job'**
  String get invalidJob;

  /// Please login to apply message
  ///
  /// In en, this message translates to:
  /// **'Please login to apply'**
  String get pleaseLoginToApply;

  /// Already applied for job message
  ///
  /// In en, this message translates to:
  /// **'You have already applied for this job.'**
  String get alreadyAppliedForJob;

  /// Job no longer available message
  ///
  /// In en, this message translates to:
  /// **'This job is no longer available.'**
  String get jobNoLongerAvailable;

  /// No description available placeholder
  ///
  /// In en, this message translates to:
  /// **'No description available.'**
  String get noDescriptionAvailable;

  /// No company description available placeholder
  ///
  /// In en, this message translates to:
  /// **'No company description available.'**
  String get noCompanyDescriptionAvailable;

  /// Applicants count label
  ///
  /// In en, this message translates to:
  /// **'{count} Applicants'**
  String applicantsLabel(int count);

  /// Minutes ago full text
  ///
  /// In en, this message translates to:
  /// **'{count} minutes ago'**
  String minutesAgoLabel(int count);

  /// Hours ago full text
  ///
  /// In en, this message translates to:
  /// **'{count} hours ago'**
  String hoursAgoLabel(int count);

  /// One day ago text
  ///
  /// In en, this message translates to:
  /// **'1 day ago'**
  String get oneDayAgo;

  /// Days ago full text
  ///
  /// In en, this message translates to:
  /// **'{count} days ago'**
  String daysAgoLabel(int count);

  /// Months ago text
  ///
  /// In en, this message translates to:
  /// **'{count} month ago'**
  String monthsAgo(int count);

  /// Months ago plural text
  ///
  /// In en, this message translates to:
  /// **'{count} months ago'**
  String monthsAgoPlural(int count);

  /// Interview summary screen title
  ///
  /// In en, this message translates to:
  /// **'Interview Summary'**
  String get interviewSummary;

  /// Location label
  ///
  /// In en, this message translates to:
  /// **'Location'**
  String get location;

  /// Contact label
  ///
  /// In en, this message translates to:
  /// **'Contact'**
  String get contact;

  /// Status label with value
  ///
  /// In en, this message translates to:
  /// **'Status: {status}'**
  String statusLabel(String status);

  /// Reject button text
  ///
  /// In en, this message translates to:
  /// **'Reject'**
  String get reject;

  /// Accept interview button text
  ///
  /// In en, this message translates to:
  /// **'Accept Interview'**
  String get acceptInterview;

  /// Interview accepted message
  ///
  /// In en, this message translates to:
  /// **'Interview accepted!'**
  String get interviewAccepted;

  /// Interview rejected message
  ///
  /// In en, this message translates to:
  /// **'Interview rejected'**
  String get interviewRejected;

  /// Failed to update interview error
  ///
  /// In en, this message translates to:
  /// **'Failed to update interview'**
  String get failedToUpdateInterview;

  /// Invalid date placeholder
  ///
  /// In en, this message translates to:
  /// **'Invalid date'**
  String get invalidDate;

  /// Filter jobs modal title
  ///
  /// In en, this message translates to:
  /// **'Filter Jobs'**
  String get filterJobs;

  /// Clear all filters button
  ///
  /// In en, this message translates to:
  /// **'Clear All'**
  String get clearAll;

  /// Major/field filter label
  ///
  /// In en, this message translates to:
  /// **'Major / Field'**
  String get majorField;

  /// Loading locations text
  ///
  /// In en, this message translates to:
  /// **'Loading locations...'**
  String get loadingLocations;

  /// Loading education levels text
  ///
  /// In en, this message translates to:
  /// **'Loading education levels...'**
  String get loadingEducationLevels;

  /// Loading experience levels text
  ///
  /// In en, this message translates to:
  /// **'Loading experience levels...'**
  String get loadingExperienceLevels;

  /// Apply filters button
  ///
  /// In en, this message translates to:
  /// **'Apply Filters'**
  String get applyFilters;

  /// Good morning greeting
  ///
  /// In en, this message translates to:
  /// **'Good Morning,'**
  String get goodMorning;

  /// Good afternoon greeting
  ///
  /// In en, this message translates to:
  /// **'Good Afternoon,'**
  String get goodAfternoon;

  /// Good evening greeting
  ///
  /// In en, this message translates to:
  /// **'Good Evening,'**
  String get goodEvening;

  /// Jobs label
  ///
  /// In en, this message translates to:
  /// **'Jobs'**
  String get jobs;

  /// Jobs count label
  ///
  /// In en, this message translates to:
  /// **'Jobs ({count})'**
  String jobsCount(int count);

  /// No jobs found message
  ///
  /// In en, this message translates to:
  /// **'No jobs found'**
  String get noJobsFound;

  /// Apply button text
  ///
  /// In en, this message translates to:
  /// **'Apply'**
  String get apply;

  /// User default name
  ///
  /// In en, this message translates to:
  /// **'User'**
  String get user;

  /// Education level filter label
  ///
  /// In en, this message translates to:
  /// **'Education Level'**
  String get educationLevel;

  /// Old password field label
  ///
  /// In en, this message translates to:
  /// **'Old Password'**
  String get oldPassword;

  /// Old password validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter your old password'**
  String get pleaseEnterOldPassword;

  /// New password validation error
  ///
  /// In en, this message translates to:
  /// **'Please enter a new password'**
  String get pleaseEnterNewPasswordField;

  /// Confirm password validation error
  ///
  /// In en, this message translates to:
  /// **'Please confirm your new password'**
  String get pleaseConfirmPassword;

  /// Password change success message
  ///
  /// In en, this message translates to:
  /// **'Password changed successfully'**
  String get passwordChangedSuccessfully;

  /// Not authenticated error
  ///
  /// In en, this message translates to:
  /// **'Not authenticated'**
  String get notAuthenticated;

  /// Confirm new password field label
  ///
  /// In en, this message translates to:
  /// **'Confirm New Password'**
  String get confirmNewPassword;

  /// File not found error
  ///
  /// In en, this message translates to:
  /// **'Selected file not found'**
  String get selectedFileNotFound;

  /// CV upload success message
  ///
  /// In en, this message translates to:
  /// **'CV uploaded successfully'**
  String get cvUploadedSuccessfully;

  /// Upload failed prefix
  ///
  /// In en, this message translates to:
  /// **'Upload failed'**
  String get uploadFailed;

  /// Error prefix
  ///
  /// In en, this message translates to:
  /// **'Error'**
  String get error;

  /// Edit digital resume title
  ///
  /// In en, this message translates to:
  /// **'Edit Digital Resume'**
  String get editDigitalResume;

  /// Personal information section title
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInformation;

  /// Professional information section title
  ///
  /// In en, this message translates to:
  /// **'Professional Information'**
  String get professionalInformation;

  /// Nationality label with value
  ///
  /// In en, this message translates to:
  /// **'Nationality: {nationality}'**
  String nationalityLabel(String nationality);

  /// Residence label with value
  ///
  /// In en, this message translates to:
  /// **'Residence: {residence}'**
  String residenceLabel(String residence);

  /// Majors label with value
  ///
  /// In en, this message translates to:
  /// **'Majors: {majors}'**
  String majorsLabel(String majors);

  /// Education label with value
  ///
  /// In en, this message translates to:
  /// **'Education: {education}'**
  String educationLabel(String education);

  /// Experience label with value
  ///
  /// In en, this message translates to:
  /// **'Experience: {experience}'**
  String experienceLabel(String experience);

  /// No CV uploaded message
  ///
  /// In en, this message translates to:
  /// **'No CV uploaded yet'**
  String get noCvUploadedYet;

  /// CV uploaded label
  ///
  /// In en, this message translates to:
  /// **'CV Uploaded'**
  String get cvUploaded;

  /// Allowed CV file formats
  ///
  /// In en, this message translates to:
  /// **'PDF, DOC, DOCX (Max 10MB)'**
  String get cvFileFormats;

  /// Additional info section title
  ///
  /// In en, this message translates to:
  /// **'Additional Info'**
  String get additionalInfo;

  /// Availability label with value
  ///
  /// In en, this message translates to:
  /// **'Availability: {availability}'**
  String availabilityLabel(String availability);

  /// Scan QR code label
  ///
  /// In en, this message translates to:
  /// **'Scan Here'**
  String get scanHere;

  /// Profession title field label
  ///
  /// In en, this message translates to:
  /// **'Profession Title'**
  String get professionTitle;

  /// Profession title field hint
  ///
  /// In en, this message translates to:
  /// **'e.g., UI UX Designer, Software Engineer'**
  String get professionTitleHint;

  /// Address field label
  ///
  /// In en, this message translates to:
  /// **'Address'**
  String get address;

  /// Upwork URL field label
  ///
  /// In en, this message translates to:
  /// **'Upwork Profile URL'**
  String get upworkProfileUrl;

  /// Upwork URL field hint
  ///
  /// In en, this message translates to:
  /// **'e.g., uptowork.com/mycv/j.smith'**
  String get upworkProfileUrlHint;

  /// Residence country field label
  ///
  /// In en, this message translates to:
  /// **'Residence Country'**
  String get residenceCountry;

  /// Majors field label
  ///
  /// In en, this message translates to:
  /// **'Majors'**
  String get majors;

  /// Public profile URL field label
  ///
  /// In en, this message translates to:
  /// **'Public Profile URL'**
  String get publicProfileUrl;

  /// Enter skill hint
  ///
  /// In en, this message translates to:
  /// **'Enter a skill and press Enter'**
  String get enterSkillHint;

  /// No skills message
  ///
  /// In en, this message translates to:
  /// **'No skills added yet'**
  String get noSkillsAdded;

  /// Summary/description field label
  ///
  /// In en, this message translates to:
  /// **'Summary/Description'**
  String get summaryDescription;

  /// Save changes button
  ///
  /// In en, this message translates to:
  /// **'Save Changes'**
  String get saveChanges;

  /// Profile update success message
  ///
  /// In en, this message translates to:
  /// **'Profile updated successfully'**
  String get profileUpdatedSuccessfully;

  /// Error picking image message
  ///
  /// In en, this message translates to:
  /// **'Error picking image'**
  String get errorPickingImage;

  /// Error updating profile message
  ///
  /// In en, this message translates to:
  /// **'Error updating profile'**
  String get errorUpdatingProfile;

  /// Select dropdown label
  ///
  /// In en, this message translates to:
  /// **'Select {label}'**
  String selectLabel(String label);

  /// Clear button
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get clear;

  /// Immediately availability option
  ///
  /// In en, this message translates to:
  /// **'Immediately'**
  String get immediately;

  /// Within 1 week availability option
  ///
  /// In en, this message translates to:
  /// **'Within 1 week'**
  String get within1Week;

  /// Within 2 weeks availability option
  ///
  /// In en, this message translates to:
  /// **'Within 2 weeks'**
  String get within2Weeks;

  /// Not available option
  ///
  /// In en, this message translates to:
  /// **'Not available'**
  String get notAvailable;

  /// Privacy policy main title
  ///
  /// In en, this message translates to:
  /// **'Privacy Policy – Shgul'**
  String get privacyPolicyTitle;

  /// Last updated date
  ///
  /// In en, this message translates to:
  /// **'Last updated: {date}'**
  String lastUpdated(String date);

  /// Privacy policy introduction
  ///
  /// In en, this message translates to:
  /// **'Shgul values and protects the privacy of every user. This Privacy Policy explains how we collect, use, store, and protect your personal information when you use our services. By accessing or using our services, you agree to the practices described in this policy.'**
  String get privacyPolicyIntro;

  /// Section 1 title
  ///
  /// In en, this message translates to:
  /// **'Section 1: Information We Collect'**
  String get section1Title;

  /// Personal information title
  ///
  /// In en, this message translates to:
  /// **'Personal Information'**
  String get personalInfoTitle;

  /// Personal information list
  ///
  /// In en, this message translates to:
  /// **'• Name\n• Email address\n• Phone number\n• Other account information you voluntarily provide'**
  String get personalInfoList;

  /// Non-personal information title
  ///
  /// In en, this message translates to:
  /// **'Non-Personal Information'**
  String get nonPersonalInfoTitle;

  /// Non-personal information list
  ///
  /// In en, this message translates to:
  /// **'• IP address\n• Device and browser type\n• Usage activity within the platform\n• Analytics data and system logs'**
  String get nonPersonalInfoList;

  /// Section 2 title
  ///
  /// In en, this message translates to:
  /// **'Section 2: How We Use Information'**
  String get section2Title;

  /// Section 2 content
  ///
  /// In en, this message translates to:
  /// **'The information collected is used to:\n• Provide and improve our services\n• Process transactions and manage accounts\n• Send important notifications and updates\n• Analyze usage patterns and enhance user experience\n• Ensure security and prevent fraud\n• Comply with legal obligations'**
  String get section2Content;

  /// Section 3 title
  ///
  /// In en, this message translates to:
  /// **'Section 3: Data Protection'**
  String get section3Title;

  /// Section 3 content
  ///
  /// In en, this message translates to:
  /// **'We implement industry-standard security measures to protect your personal information. However, no method of transmission over the internet is 100% secure, and we cannot guarantee absolute security.'**
  String get section3Content;

  /// Section 4 title
  ///
  /// In en, this message translates to:
  /// **'Section 4: Your Rights'**
  String get section4Title;

  /// Section 4 content
  ///
  /// In en, this message translates to:
  /// **'You have the right to:\n• Access your personal information\n• Request correction of inaccurate data\n• Request deletion of your data\n• Object to processing of your data\n• Request data portability\n• Withdraw consent at any time'**
  String get section4Content;

  /// Section 5 title
  ///
  /// In en, this message translates to:
  /// **'Section 5: Contact Us'**
  String get section5Title;

  /// Section 5 content
  ///
  /// In en, this message translates to:
  /// **'If you have any questions about this Privacy Policy, please contact us at support@shgul.com.'**
  String get section5Content;

  /// Customer service screen title
  ///
  /// In en, this message translates to:
  /// **'Customer Service'**
  String get customerService;

  /// Office address label
  ///
  /// In en, this message translates to:
  /// **'Office Address'**
  String get officeAddress;

  /// Phone support label
  ///
  /// In en, this message translates to:
  /// **'Phone Support'**
  String get phoneSupport;

  /// Email support label
  ///
  /// In en, this message translates to:
  /// **'Email Support'**
  String get emailSupport;

  /// Could not make phone call error
  ///
  /// In en, this message translates to:
  /// **'Could not make phone call to {number}'**
  String couldNotMakePhoneCall(String number);

  /// Could not open email error
  ///
  /// In en, this message translates to:
  /// **'Could not open email app'**
  String get couldNotOpenEmailApp;

  /// Could not open map error
  ///
  /// In en, this message translates to:
  /// **'Could not open map'**
  String get couldNotOpenMap;

  /// Email subject for customer service
  ///
  /// In en, this message translates to:
  /// **'Customer Service Inquiry'**
  String get customerServiceInquiry;

  /// Change CV button tooltip
  ///
  /// In en, this message translates to:
  /// **'Change CV'**
  String get changeCv;

  /// Upload CV button tooltip
  ///
  /// In en, this message translates to:
  /// **'Upload CV'**
  String get uploadCv;

  /// View CV button tooltip
  ///
  /// In en, this message translates to:
  /// **'View CV'**
  String get viewCv;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['ar', 'en'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'ar':
      return AppLocalizationsAr();
    case 'en':
      return AppLocalizationsEn();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}

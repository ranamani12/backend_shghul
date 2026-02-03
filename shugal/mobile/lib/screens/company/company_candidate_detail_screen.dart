import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../theme/app_theme.dart';
import '../../services/api_service.dart';
import '../../widgets/app_header.dart';
import '../../l10n/app_localizations.dart';
import '../shared/chat_screen.dart';

class CompanyCandidateDetailScreen extends StatefulWidget {
  final Map<String, dynamic> candidate;

  const CompanyCandidateDetailScreen({
    super.key,
    required this.candidate,
  });

  @override
  State<CompanyCandidateDetailScreen> createState() =>
      _CompanyCandidateDetailScreenState();
}

class _CompanyCandidateDetailScreenState
    extends State<CompanyCandidateDetailScreen> {

  Future<void> _openCV(String cvPath) async {
    final normalizedPath = ApiService.normalizeUrl(cvPath);
    final uri = Uri.parse(normalizedPath);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.couldNotOpenCv),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  Future<void> _openUpworkProfile(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri.parse('mailto:$email');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isUnlocked = widget.candidate['is_unlocked'] as bool? ?? false;

    // Get candidate info
    final name = widget.candidate['name'] as String? ?? l10n.unknown;
    final email = widget.candidate['email'] as String? ?? '';
    final mobileNumber = widget.candidate['mobile_number'] as String? ?? '';
    final professionTitle = widget.candidate['profession_title'] as String? ??
                            widget.candidate['job_title'] as String? ?? l10n.jobSeeker;
    final profileImagePath = widget.candidate['profile_image_path'] as String?;
    final summary = widget.candidate['summary'] as String? ?? '';
    final address = widget.candidate['address'] as String? ?? '';
    final dateOfBirth = widget.candidate['date_of_birth'] as String? ?? '';
    final availability = widget.candidate['availability'] as String? ?? '';
    final cvPath = widget.candidate['cv_path'] as String?;
    final skills = List<String>.from(widget.candidate['skills'] ?? []);
    final majorNames = List<String>.from(widget.candidate['major_names'] ?? []);
    final experienceName = widget.candidate['experience_name'] as String? ?? '';
    final educationName = widget.candidate['education_name'] as String? ?? '';
    final nationalityCountry = widget.candidate['nationality_country'] as String? ?? '';
    final residentCountry = widget.candidate['resident_country'] as String? ?? '';
    final upworkProfileUrl = widget.candidate['upwork_profile_url'] as String? ?? '';
    final uniqueCode = widget.candidate['unique_code'] as String? ?? '';

    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top Header
            const AppHeader(showLanguageWithActions: true),

            // Main Content Area
            Expanded(
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: AppTheme.bodySurfaceColor,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(48),
                    topRight: Radius.circular(48),
                  ),
                ),
                child: Column(
                  children: [
                    // Drag handle
                    Center(
                      child: Container(
                        height: 5,
                        width: 50,
                        margin: const EdgeInsets.only(top: 12),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade400,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // App Bar with Back Button and Title
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.arrow_back,
                              color: AppTheme.textPrimary,
                            ),
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                          ),
                          Expanded(
                            child: Text(
                              l10n.candidateProfile,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(width: 40),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Scrollable Content
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile Header Card
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: AppTheme.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                  ),
                                ],
                              ),
                              child: Column(
                                children: [
                                  // Profile Image
                                  Container(
                                    width: 100,
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor.withOpacity(0.15),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: AppTheme.primaryColor.withOpacity(0.3),
                                        width: 3,
                                      ),
                                    ),
                                    child: profileImagePath != null
                                        ? ClipOval(
                                            child: Image.network(
                                              ApiService.normalizeUrl(profileImagePath),
                                              fit: BoxFit.cover,
                                              width: 100,
                                              height: 100,
                                              errorBuilder: (_, __, ___) =>
                                                  const Icon(
                                                Icons.person,
                                                color: AppTheme.primaryColor,
                                                size: 50,
                                              ),
                                            ),
                                          )
                                        : const Icon(
                                            Icons.person,
                                            color: AppTheme.primaryColor,
                                            size: 50,
                                          ),
                                  ),
                                  const SizedBox(height: 16),

                                  // Name with Lock Status
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Text(
                                        isUnlocked ? name : '••••••••••',
                                        style: TextStyle(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w700,
                                          color: isUnlocked
                                              ? AppTheme.textPrimary
                                              : Colors.grey.shade400,
                                        ),
                                      ),
                                      if (!isUnlocked) ...[
                                        const SizedBox(width: 8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 8,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.orange.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Icon(
                                                Icons.lock,
                                                size: 12,
                                                color: Colors.orange.shade700,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                l10n.locked,
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.orange.shade700,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const SizedBox(height: 4),

                                  // Profession Title
                                  Text(
                                    professionTitle,
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade600,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),

                                  // Unique Code (if unlocked)
                                  if (isUnlocked && uniqueCode.isNotEmpty) ...[
                                    const SizedBox(height: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        'ID: $uniqueCode',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],

                                  // Contact Info (only if unlocked)
                                  if (isUnlocked) ...[
                                    const SizedBox(height: 16),
                                    const Divider(),
                                    const SizedBox(height: 12),

                                    // Email
                                    if (email.isNotEmpty)
                                      _buildContactRow(
                                        icon: Icons.email_outlined,
                                        value: email,
                                        onTap: () => _sendEmail(email),
                                      ),

                                    // Phone
                                    if (mobileNumber.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      _buildContactRow(
                                        icon: Icons.phone_outlined,
                                        value: mobileNumber,
                                        onTap: () => _callPhone(mobileNumber),
                                      ),
                                    ],

                                    // Address
                                    if (address.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      _buildContactRow(
                                        icon: Icons.location_on_outlined,
                                        value: address,
                                      ),
                                    ],
                                  ],
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),

                            // Quick Info Cards
                            if (isUnlocked) ...[
                              Row(
                                children: [
                                  if (nationalityCountry.isNotEmpty)
                                    Expanded(
                                      child: _buildInfoCard(
                                        icon: Icons.flag_outlined,
                                        label: l10n.nationality,
                                        value: nationalityCountry,
                                      ),
                                    ),
                                  if (nationalityCountry.isNotEmpty && residentCountry.isNotEmpty)
                                    const SizedBox(width: 12),
                                  if (residentCountry.isNotEmpty)
                                    Expanded(
                                      child: _buildInfoCard(
                                        icon: Icons.home_outlined,
                                        label: l10n.resident,
                                        value: residentCountry,
                                      ),
                                    ),
                                ],
                              ),
                              if (nationalityCountry.isNotEmpty || residentCountry.isNotEmpty)
                                const SizedBox(height: 12),

                              Row(
                                children: [
                                  if (dateOfBirth.isNotEmpty)
                                    Expanded(
                                      child: _buildInfoCard(
                                        icon: Icons.cake_outlined,
                                        label: l10n.dateOfBirth,
                                        value: dateOfBirth,
                                      ),
                                    ),
                                  if (dateOfBirth.isNotEmpty && availability.isNotEmpty)
                                    const SizedBox(width: 12),
                                  if (availability.isNotEmpty)
                                    Expanded(
                                      child: _buildInfoCard(
                                        icon: Icons.access_time,
                                        label: l10n.availability,
                                        value: availability,
                                      ),
                                    ),
                                ],
                              ),
                              if (dateOfBirth.isNotEmpty || availability.isNotEmpty)
                                const SizedBox(height: 20),
                            ],

                            // Experience & Education
                            if (experienceName.isNotEmpty || educationName.isNotEmpty) ...[
                              Text(
                                l10n.experienceAndEducation,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  if (experienceName.isNotEmpty)
                                    Expanded(
                                      child: _buildInfoCard(
                                        icon: Icons.work_history_outlined,
                                        label: l10n.experience,
                                        value: experienceName,
                                        color: Colors.blue,
                                      ),
                                    ),
                                  if (experienceName.isNotEmpty && educationName.isNotEmpty)
                                    const SizedBox(width: 12),
                                  if (educationName.isNotEmpty)
                                    Expanded(
                                      child: _buildInfoCard(
                                        icon: Icons.school_outlined,
                                        label: l10n.education,
                                        value: educationName,
                                        color: Colors.purple,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Summary (only if unlocked and has content)
                            if (isUnlocked && summary.isNotEmpty) ...[
                              Text(
                                l10n.about,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  summary,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade700,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Majors/Fields
                            if (majorNames.isNotEmpty) ...[
                              Text(
                                l10n.fieldsMajors,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: majorNames.map((major) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.primaryColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        major,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: AppTheme.primaryColor,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Skills (only if unlocked and has content)
                            if (isUnlocked && skills.isNotEmpty) ...[
                              Text(
                                l10n.skills,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: AppTheme.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: skills.map((skill) {
                                    return Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 8,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.green.shade50,
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                          color: Colors.green.shade200,
                                        ),
                                      ),
                                      child: Text(
                                        skill,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],

                            // CV / Resume Section (only if unlocked and has CV)
                            if (isUnlocked && cvPath != null && cvPath.isNotEmpty) ...[
                              Text(
                                l10n.cvResume,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: () => _openCV(cvPath),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.red.shade100,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 56,
                                        height: 56,
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.picture_as_pdf,
                                          color: Colors.red.shade400,
                                          size: 32,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              l10n.candidateResume,
                                              style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              l10n.tapToViewOrDownload,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        width: 44,
                                        height: 44,
                                        decoration: BoxDecoration(
                                          color: AppTheme.primaryColor.withOpacity(0.1),
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.download_outlined,
                                          color: AppTheme.primaryColor,
                                          size: 22,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Upwork Profile (only if unlocked and has URL)
                            if (isUnlocked && upworkProfileUrl.isNotEmpty) ...[
                              Text(
                                l10n.externalProfile,
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 12),
                              GestureDetector(
                                onTap: () => _openUpworkProfile(upworkProfileUrl),
                                child: Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppTheme.white,
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.green.shade100,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 48,
                                        height: 48,
                                        decoration: BoxDecoration(
                                          color: Colors.green.shade50,
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Icon(
                                          Icons.link,
                                          color: Colors.green.shade600,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              l10n.upworkProfile,
                                              style: const TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              l10n.viewExternalProfile,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey.shade500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Icon(
                                        Icons.open_in_new,
                                        color: Colors.green.shade600,
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],

                            // Locked Notice (only if not unlocked)
                            if (!isUnlocked) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: Colors.orange.shade50,
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: Colors.orange.shade200,
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  children: [
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade100,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        Icons.lock_outline,
                                        size: 32,
                                        color: Colors.orange.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      l10n.profileLocked,
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.orange.shade800,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      l10n.unlockCandidateDescription,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.orange.shade700,
                                        height: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 20),
                            ],

                            const SizedBox(height: 100),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Action Bar
            Container(
              color: AppTheme.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: SafeArea(
                child: isUnlocked
                    ? Row(
                        children: [
                          // Message Button
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                final candidateId = widget.candidate['id'] as int?;
                                if (candidateId != null) {
                                  final candidateProfile = widget.candidate['candidate_profile'] as Map<String, dynamic>?;
                                  final firstName = candidateProfile?['first_name'] ?? '';
                                  final lastName = candidateProfile?['last_name'] ?? '';
                                  String candidateName = '$firstName $lastName'.trim();
                                  if (candidateName.isEmpty) {
                                    candidateName = widget.candidate['name'] ?? 'Candidate';
                                  }
                                  final profileImagePath = widget.candidate['profile_image_path'] as String? ??
                                                           candidateProfile?['profile_image_path'] as String?;

                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ChatScreen(
                                        userId: candidateId,
                                        userName: candidateName,
                                        userImage: profileImagePath,
                                        userRole: 'candidate',
                                      ),
                                    ),
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryColor,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.chat_outlined, size: 20),
                                  const SizedBox(width: 8),
                                  Text(
                                    l10n.sendMessage,
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Call Button
                          if (mobileNumber.isNotEmpty)
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: Colors.green.shade50,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: IconButton(
                                onPressed: () => _callPhone(mobileNumber),
                                icon: Icon(
                                  Icons.phone_outlined,
                                  color: Colors.green.shade600,
                                  size: 24,
                                ),
                              ),
                            ),
                          if (mobileNumber.isNotEmpty) const SizedBox(width: 12),
                          // Schedule Interview Button
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: AppTheme.lightGreen,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: IconButton(
                              onPressed: () {
                                // TODO: Schedule interview
                              },
                              icon: Icon(
                                Icons.calendar_today_outlined,
                                color: AppTheme.green,
                                size: 24,
                              ),
                            ),
                          ),
                        ],
                      )
                    : ElevatedButton(
                        onPressed: () {
                          // Pop back and indicate unlock is needed
                          Navigator.pop(context, 'unlock');
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          minimumSize: const Size(double.infinity, 56),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.lock_open, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              l10n.unlockCandidate,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactRow({
    required IconData icon,
    required String value,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: AppTheme.primaryColor,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: onTap != null ? AppTheme.primaryColor : Colors.grey.shade600,
                fontWeight: onTap != null ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
          if (onTap != null)
            Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.grey.shade400,
            ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String label,
    required String value,
    Color? color,
  }) {
    final cardColor = color ?? AppTheme.primaryColor;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: cardColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

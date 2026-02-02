import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Mock data for job offers
  List<Map<String, dynamic>> _getJobOffers() {
    return [
      {
        'companyName': 'Axie Infinity',
        'title': 'Jr. Game Designer',
        'salary': 'KWD 1100 - 12.000/Month',
        'tags': ['Game', 'Unity'],
        'iconColor': Colors.blue,
      },
      {
        'companyName': 'Uniswap',
        'title': 'Sr. Product Designer',
        'salary': 'KWD 1500 - 15.000/Month',
        'tags': ['Product Design', 'Full Time'],
        'iconColor': Colors.pink,
      },
      {
        'companyName': 'Tech Solutions',
        'title': 'Frontend Developer',
        'salary': 'KWD 1200 - 13.000/Month',
        'tags': ['React', 'TypeScript'],
        'iconColor': Colors.green,
      },
    ];
  }

  // Mock data for candidates
  List<Map<String, dynamic>> _getCandidates() {
    return [
      {
        'name': 'John Doe',
        'title': 'Senior Developer',
        'location': 'Kuwait City',
        'tags': ['Full Stack', 'Remote'],
        'iconColor': Colors.orange,
      },
      {
        'name': 'Jane Smith',
        'title': 'UI/UX Designer',
        'location': 'Salmiya',
        'tags': ['Design', 'Figma'],
        'iconColor': Colors.purple,
      },
      {
        'name': 'Mike Johnson',
        'title': 'Product Manager',
        'location': 'Hawalli',
        'tags': ['Agile', 'Strategy'],
        'iconColor': Colors.teal,
      },
    ];
  }

  @override
  Widget build(BuildContext context) {
    final jobOffers = _getJobOffers();
    final candidates = _getCandidates();

    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  height: 80,
                  width: 80,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.work,
                      size: 40,
                      color: AppTheme.primaryColor,
                    );
                  },
                ),

                // Notification Icon
                Image.asset(
                  'assets/images/icons/bell.png',
                  height: 50,
                  width: 50,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.notification_important_sharp,
                      size: 40,
                      color: AppTheme.primaryColor,
                    );
                  },
                ),
              ],
            ),
          ),

          // 🔹 WHITE CONTENT AREA
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(top: 0),
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppTheme.bodySurfaceColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(56),
                  topRight: Radius.circular(56),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Gray indicator bar
                  Container(
                    height: 6,
                    width: 60,
                    margin: const EdgeInsets.only(top: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),

                  // Search Bar
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppTheme.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(left: 20.0),
                              child: TextField(
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.transparent,
                                    ),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(
                                      color: Colors.transparent,
                                    ),
                                  ),
                                  hintText: 'Search...',
                                  icon: const Icon(
                                    Icons.search,
                                    color: AppTheme.textMuted,
                                    size: 30,
                                  ),

                                  hintStyle: const TextStyle(
                                    color: AppTheme.textMuted,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(
                              Icons.tune,
                              color: AppTheme.textMuted,
                            ),
                            onPressed: () {
                              // Handle filter
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Job Offer',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    // Navigate to all job offers
                                  },
                                  child: const Text(
                                    'See All',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: 240,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10.0,
                              ),
                              itemCount: jobOffers.length,
                              itemBuilder: (context, index) {
                                final job = jobOffers[index];
                                return _buildJobCard(job);
                              },
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Candidates Section
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Candidates',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    // Navigate to all candidates
                                  },
                                  child: const Text(
                                    'See All',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Candidates Horizontal List
                          SizedBox(
                            height: 280,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              itemCount: candidates.length,
                              itemBuilder: (context, index) {
                                final candidate = candidates[index];
                                return _buildCandidateCard(candidate);
                              },
                            ),
                          ),
                          const SizedBox(height: 80), // Space for bottom nav bar
                        ],
                      ),
                    ),
                  ),

                  // Job Offer Section

                  // Job Offers Horizontal List
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildJobCard(Map<String, dynamic> job) {
    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company Icon, Name, and Favorite
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (job['iconColor'] as Color).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.business,
                    color: job['iconColor'] as Color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        job['companyName'] as String,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: const Icon(
                    Icons.favorite_border,
                    color: AppTheme.textMuted,
                    size: 20,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Job Title
            Text(
              job['title'] as String,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),

            const SizedBox(height: 8),

            // Salary
            Text(
              job['salary'] as String,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),

            const SizedBox(height: 12),

            // Tags
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: (job['tags'] as List<String>)
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.bodySurfaceColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),

            const SizedBox(height: 8),
            const Divider(color: AppTheme.bodySurfaceColor, thickness: 1),
            const SizedBox(height: 8),


            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionButton(
                  icon: 'assets/images/icons/view.png',
                  onPressed: () {
                    // Handle view
                  },
                ),
                const SizedBox(width: 24),
                _buildActionButton(
                  icon: 'assets/images/icons/chat.png',
                  onPressed: () {
                    // Handle chat
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCandidateCard(Map<String, dynamic> candidate) {
    return Container(
      width: 240,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Icon, Name, and Favorite
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: (candidate['iconColor'] as Color).withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person,
                    color: candidate['iconColor'] as Color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        candidate['name'] as String,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.favorite_border,
                    color: AppTheme.textMuted,
                    size: 20,
                  ),
                  onPressed: () {
                    // Handle favorite
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Candidate Title
            Text(
              candidate['title'] as String,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),

            const SizedBox(height: 8),

            // Location
            Text(
              candidate['location'] as String,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.textSecondary,
              ),
            ),

            const SizedBox(height: 12),

            // Tags
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: (candidate['tags'] as List<String>)
                  .map(
                    (tag) => Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.bodySurfaceColor,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tag,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMuted,
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 15),
            const Divider(color: AppTheme.bodySurfaceColor, thickness: 2),
            const SizedBox(height: 12),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildActionButton(
                  icon: 'assets/images/icons/view.png',
                  onPressed: () {
                    // Handle view
                  },
                ),
                const SizedBox(width: 24),
                _buildActionButton(
                  icon: 'assets/images/icons/chat.png',
                  onPressed: () {
                    // Handle chat
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required String icon,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 80,
        height: 40,
        decoration: BoxDecoration(
          color: AppTheme.bodySurfaceColor,
          borderRadius: BorderRadius.circular(20), // ✅ pill shape
          border: Border.all(color: Colors.transparent, width: 1.5),
        ),
        child: Center(
          child: ColorFiltered(
            colorFilter: ColorFilter.mode(
              AppTheme.primaryColor,
              BlendMode.srcIn,
            ),
            child: Image.asset(
              icon,
              width: 18,
              height: 18,
              errorBuilder: (_, __, ___) => Icon(
                Icons.visibility_outlined,
                size: 18,
                color: AppTheme.primaryColor,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

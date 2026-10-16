import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

import '../models/app_state.dart';

class AppDrawer extends StatefulWidget {
  final VoidCallback onNavigateHome;
  final VoidCallback onNavigateResumeEditor;
  final VoidCallback onNavigateTools;
  final VoidCallback onNavigateProfile;

  const AppDrawer({
    super.key,
    required this.onNavigateHome,
    required this.onNavigateResumeEditor,
    required this.onNavigateTools,
    required this.onNavigateProfile,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  @override
  void initState() {
    super.initState();
    appState.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    appState.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(28)),
      ),
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Color(0xFFF7F7F9),
                borderRadius: BorderRadius.only(topRight: Radius.circular(28)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6C5CE7),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6C5CE7).withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        appState.userName.isNotEmpty
                            ? appState.userName[0].toUpperCase()
                            : 'J',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appState.userName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1A1A1E),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          appState.userEmail,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFEBFF),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            'Resume tools ready',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6C5CE7),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            // Navigation Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildDrawerItem(
                    icon: Icons.home_rounded,
                    title: 'Home',
                    onTap: () {
                      Navigator.pop(context);
                      widget.onNavigateHome();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.description_rounded,
                    title: 'Resume Builder',
                    onTap: () {
                      Navigator.pop(context);
                      widget.onNavigateResumeEditor();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.handyman_rounded,
                    title: 'Career Tools',
                    onTap: () {
                      Navigator.pop(context);
                      widget.onNavigateTools();
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.bookmark_border_rounded,
                    title: 'Saved Cover Letters',
                    onTap: () {
                      Navigator.pop(context);
                      toastification.show(
                        context: context,
                        type: ToastificationType.info,
                        style: ToastificationStyle.flatColored,
                        title: const Text('Cover Letters'),
                        description: const Text('Cover letter generator is ready.'),
                        alignment: Alignment.topCenter,
                        autoCloseDuration: const Duration(seconds: 3),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.person_outline_rounded,
                    title: 'Profile Settings',
                    onTap: () {
                      Navigator.pop(context);
                      widget.onNavigateProfile();
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                    child: Divider(color: Color(0xFFEFEFF2)),
                  ),
                  _buildDrawerItem(
                    icon: Icons.help_outline_rounded,
                    title: 'Help & Support',
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: const Text(
                            'Help & Support',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          content: const Text(
                            'Use Resume Builder to edit and export a CV, or Career Tools to create a cover letter and practice interview questions.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'OK',
                                style: TextStyle(color: Color(0xFF6C5CE7)),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    icon: Icons.info_outline_rounded,
                    title: 'About CV Helper',
                    onTap: () {
                      Navigator.pop(context);
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                          title: const Text(
                            'CV Helper v1.0.0',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          content: const Text(
                            'CV Helper lets you edit and export a resume, check it against a job description, and draft career materials on your device.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text(
                                'Close',
                                style: TextStyle(color: Color(0xFF6C5CE7)),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Footer Version Info
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Center(
                child: Text(
                  'CV Helper • v1.0.0 Pro',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFF7F7F9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: const Color(0xFF1A1A1E), size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Color(0xFF1A1A1E),
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }
}

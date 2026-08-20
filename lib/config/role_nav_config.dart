import 'package:flutter/material.dart';
import '../providers/role_provider.dart';

class NavItem {
  final IconData icon;
  final String label;
  final String route;
  const NavItem(this.icon, this.label, this.route);
}

List<NavItem> getNavItemsForRole(UserRole role) {
  // Common tabs everyone gets
  const home = NavItem(Icons.home_rounded, 'HOME', '/');
  const words = NavItem(Icons.menu_book_rounded, 'WORDS', '/dictionary');
  const profile = NavItem(Icons.person_rounded, 'YOU', '/profile');
  const learn = NavItem(Icons.school_rounded, 'LEARN', '/learning');
  const sentiment = NavItem(Icons.insights_rounded, 'VITALITY', '/sentiment'); // Added sentiment placeholder

  switch (role) {
    case UserRole.learner:
      return [home, words, learn, sentiment, profile];
    case UserRole.staff:
      return [
        home,
        words,
        sentiment,
        profile,
      ];
    case UserRole.educator:
      return [
        const NavItem(
          Icons.grid_view_rounded,
          'DASHBOARD',
          '/educator/dashboard',
        ),
        const NavItem(Icons.group_rounded, 'STUDENTS', '/educator/students'),
        const NavItem(
          Icons.insights_rounded,
          'ANALYTICS',
          '/educator/analytics',
        ),
        profile,
      ];
    case UserRole.admin:
      return [
        const NavItem(Icons.dashboard_rounded, 'OVERVIEW', '/admin/overview'),
        const NavItem(Icons.people_rounded, 'USERS', '/admin/users'),
        const NavItem(
          Icons.library_books_rounded,
          'LESSONS',
          '/admin/lessons',
        ),
        const NavItem(Icons.insights_rounded, 'VITALITY', '/sentiment'),
        const NavItem(Icons.book_rounded, 'ARCHIVE', '/admin/dictionary'),
        profile,
      ];
  }
}




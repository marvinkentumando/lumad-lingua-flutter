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
  const map = NavItem(Icons.map_rounded, 'MAP', '/map');
  const words = NavItem(Icons.menu_book_rounded, 'WORDS', '/dictionary');
  const profile = NavItem(Icons.person_rounded, 'YOU', '/profile');
  const learn = NavItem(Icons.school_rounded, 'LEARN', '/learning');

  switch (role) {
    case UserRole.learner:
      return [home, map, words, learn, profile];
    case UserRole.contributor:
      return [
        home,
        map,
        words,
        const NavItem(Icons.add_circle_rounded, 'ADD', '/contribute'),
        profile,
      ];
    case UserRole.validator:
      return [
        const NavItem(Icons.home_rounded, 'HOME', '/validator/home'),
        const NavItem(Icons.list_alt_rounded, 'ENTRIES', '/validator/entries'),
        const NavItem(
          Icons.record_voice_over_rounded,
          'VOICES',
          '/validator/voices',
        ),
        const NavItem(Icons.menu_book_rounded, 'LESSONS', '/validator/lessons'),
        profile,
      ];
    case UserRole.educator:
      return [
        const NavItem(
          Icons.grid_view_rounded,
          'DASHBOARD',
          '/educator/dashboard',
        ),
        const NavItem(
          Icons.library_books_rounded,
          'LESSONS',
          '/educator/lessons',
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
        const NavItem(Icons.library_books_rounded, 'CONTENT', '/admin/content'),
        profile,
      ];
  }
}




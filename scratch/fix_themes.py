import os

files_to_fix = [
    "lib/screens/achievements_screen.dart",
    "lib/screens/admin_overview_screen.dart",
    "lib/screens/admin_requests_screen.dart",
    "lib/screens/ancestral_vault_shop_screen.dart",
    "lib/screens/artifact_detail_screen.dart",
    "lib/screens/contributor_screen.dart",
    "lib/screens/dashboard_screen.dart",
    "lib/screens/educator_lessons_screen.dart",
    "lib/screens/educator_students_screen.dart",
    "lib/screens/flashcards_screen.dart",
    "lib/screens/gallery_screen.dart",
    "lib/screens/learning_hub_screen.dart",
    "lib/screens/lingua_duel_screen.dart",
    "lib/screens/mastery_dashboard_screen.dart",
    "lib/screens/notification_screen.dart",
    "lib/screens/profile_screen.dart",
    "lib/screens/scenario_hub_screen.dart",
    "lib/screens/validator_home_screen.dart",
    "lib/widgets/impact_card.dart",
    "lib/widgets/pronunciation_analysis_widget.dart",
    "lib/widgets/recording_card.dart",
    "lib/widgets/wotd_widget.dart"
]

for file_path in files_to_fix:
    full_path = os.path.join(os.getcwd(), file_path)
    if os.path.exists(full_path):
        with open(full_path, 'r', encoding='utf-8') as f:
            content = f.read()
        
        new_content = content.replace('BrandCardTheme.darkGlass', 'BrandCardTheme.vibrant')
        
        if new_content != content:
            with open(full_path, 'w', encoding='utf-8') as f:
                f.write(new_content)
            print(f"Fixed: {file_path}")
        else:
            print(f"No changes needed: {file_path}")
    else:
        print(f"File not found: {file_path}")

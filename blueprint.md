# SaiLearn App Blueprint

## Overview

SaiLearn is a comprehensive educational application designed to streamline interactions between students, teachers, and administrators. The app provides role-based access to a suite of tools for managing schedules, assignments, grades, and communication, all within a secure and intuitive interface.

## Style and Design

The application follows a clean and modern design aesthetic, with a user-friendly interface that prioritizes clarity and ease of use. Key design elements include:

*   **Color Scheme:** A professional and visually appealing palette with a primary color of green, creating a consistent and branded look.
*   **Typography:** Clear and legible fonts to ensure readability across all devices.
*   **Layout:** A responsive and adaptive layout that provides a seamless experience on both mobile and web platforms.
*   **Animated Navigation:** An interactive bottom navigation bar where the selected item animates with a subtle scaling effect, and all labels are persistently visible for enhanced clarity.

## Features

### Implemented

*   **Role-Based Authentication:** Secure login for students, teachers, and administrators, ensuring that users can only access features relevant to their role.
*   **Automatic Persistent Login:** The app automatically remembers any user who successfully logs in, allowing them to stay logged in across sessions for a more convenient and seamless experience.
*   **Cross-Platform Compatibility:** A single codebase that runs on both Android and web, providing a consistent experience for all users.
*   **Redesigned Student Dashboard:** A brand new, modern dashboard for students with a dynamic welcome message, attendance and progress tracking, and an animated bottom navigation bar.
*   **Intuitive Navigation:** A clear and straightforward navigation system that makes it easy for users to find the information they need.
*   **Student Profile Page:** A dedicated page where students can view their personal and guardian information, upload a profile picture, and log out of the application.

### Current Plan: Enhance Bottom Navigation Clarity

*   **Objective:** To improve the bottom navigation bar by making all item labels visible, while retaining the scaling animation for the selected item.
*   **Steps:**
    1.  **Modify `student_dashboard.dart`:**
        *   In the `_buildNavItem` method, remove the conditional logic that was hiding the labels for unselected items.
        *   Ensure the `Text` widget for the label is always rendered for every navigation item.
        *   The color of the icon and text will continue to change based on the selection state, while the scaling animation remains on the active item.
    2.  **Update `blueprint.md`:** Document the improved label visibility in the navigation bar.

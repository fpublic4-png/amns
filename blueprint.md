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
*   **Advanced Notification Pop-up:** A pop-up dialog that appears when the notification bell is clicked, with separate tabs for "Notifications" and "Homework." It fetches and displays messages from Firestore using a robust, multi-query approach that ensures all relevant information is displayed correctly and efficiently.

### Current Plan: Definitive Multi-Query Fix for All Data

*   **Objective:** To permanently and correctly fix the data fetching for both notifications and homework by implementing a unified and robust multi-query strategy that eliminates guesswork and ensures stability.
*   **Steps:**
    1.  **Implement Unified Multi-Query Strategy:**
        *   The data fetching logic in `lib/notifications_popup.dart` was completely rewritten to use a single, reliable multi-query approach for *both* the `notifications` and `homework` collections.
        *   This strategy performs three distinct, explicit queries for each collection:
            1.  Fetches items for 'Everyone'.
            2.  Fetches items for the student's specific 'Whole Class'.
            3.  Fetches items for the student's specific 'Class/Section'.
        *   All results are combined into a `Map` to automatically handle de-duplication, ensuring each item appears only once.
        *   This definitive approach removes all previous assumptions and unstable logic, guaranteeing a correct and robust implementation.
    2.  **Update `blueprint.md`:** Document the final, unified multi-query strategy, marking the complete resolution of the data fetching issues.

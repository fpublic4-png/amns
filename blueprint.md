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
*   **Notification Pop-up:** A pop-up dialog that appears when the notification bell is clicked, with separate tabs for "Notifications" and "Homework." It fetches and displays messages from Firestore based on the student's class and "everyone" broadcasts.

### Current Plan: Implement Notification Pop-up

*   **Objective:** To create a pop-up dialog that displays notifications and homework for the logged-in student.
*   **Steps:**
    1.  **Create `lib/notifications_popup.dart`:**
        *   Build a stateful widget with a `TabController` for "Notifications" and "Homework" tabs.
        *   Implement logic to fetch the student's class from Firestore using their user ID.
        *   Fetch messages from the `notifications` collection, filtering by the student's class and "everyone."
        *   Fetch messages from the `homework` collection, filtering by the student's class.
        *   Display the fetched messages in a `ListView` for each respective tab, with a message for when there are no new items.
    2.  **Modify `lib/student_dashboard.dart`:**
        *   Import the new `notifications_popup.dart` file.
        *   Create a method, `_showNotificationsPopup()`, that uses `showDialog` to display the `NotificationsPopup` widget within an `AlertDialog`.
        *   Update the `onPressed` callback of the notification `IconButton` in the `AppBar` to call the `_showNotificationsPopup` method.
    3.  **Update `blueprint.md`:** Document the new notification pop-up feature.

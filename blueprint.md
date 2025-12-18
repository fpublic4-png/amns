# SaiLearn App Blueprint

## Overview

SaiLearn is a comprehensive educational application designed to streamline interactions between students, teachers, and administrators. The app provides role-based access to a suite of tools for managing schedules, assignments, grades, and communication, all within a secure and intuitive interface.

## Style and Design

The application follows a clean and modern design aesthetic, with a user-friendly interface that prioritizes clarity and ease of use. Key design elements include:

*   **Color Scheme:** A professional and visually appealing palette with a primary color of green, creating a consistent and branded look.
*   **Typography:** Clear and legible fonts to ensure readability across all devices.
*   **Layout:** A responsive and adaptive layout that provides a seamless experience on both mobile and web platforms.

## Features

### Implemented

*   **Role-Based Authentication:** Secure login for students, teachers, and administrators, ensuring that users can only access features relevant to their role.
*   **Automatic Persistent Login:** The app automatically remembers any user who successfully logs in, allowing them to stay logged in across sessions for a more convenient and seamless experience.
*   **Cross-Platform Compatibility:** A single codebase that runs on both Android and web, providing a consistent experience for all users.
*   **Redesigned Student Dashboard:** A brand new, modern dashboard for students with a dynamic welcome message, attendance and progress tracking, and a new bottom navigation bar.
*   **Intuitive Navigation:** A clear and straightforward navigation system that makes it easy for users to find the information they need.
*   **Student Profile Page:** A dedicated page where students can view their personal and guardian information, upload a profile picture, and log out of the application.

### Current Plan: Student Profile Page

*   **Objective:** To create a "My Profile" page that allows students to view and manage their profile information.
*   **Steps:**
    1.  **Add `image_picker` dependency:** Include the `image_picker` package to allow users to select a profile picture from their device's gallery.
    2.  **Create Profile Page UI:** Build the `student_profile_page.dart` file with a "My Profile" header, a logout button, a profile picture section, and fields for student and guardian information.
    3.  **Fetch Student Data:** Implement logic to retrieve the student's data from Firestore, including their name, ID, class, house, email, phone number, address, and guardian details.
    4.  **Implement Profile Picture Upload:** Add functionality to upload the selected profile picture to Firebase Storage and update the student's profile with the new image URL.
    5.  **Implement Logout:** Create a logout function that clears the user's session data and navigates them back to the login page.
    6.  **Navigate to Profile Page:** Update the `student_dashboard.dart` file to navigate to the `StudentProfilePage` when the user clicks on their profile picture.
    7.  **Resolve Dependencies:** Fix dependency conflicts between `firebase_auth` and `firebase_storage` by updating the package versions in `pubspec.yaml` and running `flutter pub get`.
    8.  **Update `blueprint.md`:** Document the new "Student Profile" feature in the `blueprint.md` file.

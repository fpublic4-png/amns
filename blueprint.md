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

### Current Plan: Student Dashboard Redesign

*   **Objective:** To create a modern, intuitive, and feature-rich dashboard for students, following the provided design.
*   **Steps:**
    1.  **Add `percent_indicator` dependency:** Include the `percent_indicator` package for progress tracking.
    2.  **Redesign the UI:** Rebuild the `student_dashboard.dart` file with a new layout, including a header, body, and footer.
    3.  **Fetch Student Name:** Dynamically retrieve and display the student's name from Firestore.
    4.  **Implement Bottom Navigation:** Create a bottom navigation bar with five tabs: Home, Material, AI Doubt, Tests, and PYQs.
    5.  **Add Progress Indicators:** Include progress indicators for "Lectures Watched" and "Subject Mastery."

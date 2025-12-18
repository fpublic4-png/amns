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
*   **Intuitive Navigation:** A clear and straightforward navigation system that makes it easy for users to find the information they need.

### Current Plan: Automatic Persistent Login

*   **Objective:** To automatically remember any user who successfully logs in, removing the need for a "Remember Me" checkbox and providing a more seamless user experience.
*   **Steps:**
    1.  **Integrate `shared_preferences`:** Add the `shared_preferences` package to enable secure local data storage.
    2.  **Remove "Remember Me" Checkbox:** Eliminate the checkbox from the student, teacher, and admin login pages.
    3.  **Automatically Save User Credentials:** When a user logs in successfully, their user ID and role will be automatically saved to the device.
    4.  **Implement Auto-Login:** On app startup, check for saved credentials and automatically navigate the user to their dashboard if found.
    5.  **Add Logout Button:** Provide a logout button on each dashboard to clear saved credentials and return to the main login screen.

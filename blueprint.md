# SaiLearn - A School Learning Solution

## Overview

This application provides a login portal for students and staff of SaiLearn, a school learning solution.

## Style, Design, and Features

### Version 1.0.0

#### **Login Screen**

*   **Visual Design:**
    *   Background Color: A light greyish-blue (`#F0F4F8`).
    *   Typography:
        *   Main Title ("Welcome to SaiLearn"): Large, bold, and in a dark green color.
        *   Subtitle ("Your complete school learning solution."): Medium size, in a grey color.
        *   Card Title ("Login As"): Bold and prominent.
    *   Layout: A centrally aligned column containing the welcome text and a login card.
    *   Card: A white card with rounded corners and a subtle shadow, giving it a "lifted" look.
*   **Features:**
    *   **Role-based Login:**
        *   Presents two distinct login options: "Student" and "Staff".
        *   Each option is represented by a large, tappable button with a relevant icon.
    *   **Navigation:**
        *   Tapping the "Student" button navigates the user to the `StudentPage`.
        *   Tapping the "Staff" button navigates the user to the `StaffPage`.

#### **Student Page**

*   A simple placeholder page with a green `AppBar` and a welcome message for students.

#### **Staff Page**

*   A simple placeholder page with a dark green `AppBar` and a welcome message for staff.

## Current Plan

**Request:** "Remove your flutter demo page and instead of it i have attached the photo copy it and make it main login page and in it there are two buttons student and teachers if we click on it both opens new pages"

**Steps:**

1.  **Create `lib/login_page.dart`**: Implement the login screen UI as per the provided image.
2.  **Create `lib/student_page.dart`**: Create a placeholder page for the student section.
3.  **Create `lib/staff_page.dart`**: Create a placeholder page for the staff section.
4.  **Update `lib/main.dart`**: Set `LoginPage` as the initial route of the application.
5.  **Create `blueprint.md`**: To document the project's features and the current development plan.

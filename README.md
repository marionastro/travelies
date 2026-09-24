<img height=128 width=128 style="display: block; margin: auto;" alt="AppIcon" src="https://github.com/user-attachments/assets/23464982-74fc-4abd-bc01-4246837df6c7" />
<h1>Travelies</h1>
> A collaborative iOS application built with Swift and SwiftUI to track trips, share multimedia moments, and manage collaborative travel experiences.

"Travelies" was born with the objective of modernizing the concept of a photo album, combining geolocated multimedia documentation with a social infrastructure[cite: 6]. The project includes the iOS client app and a custom REST API for the backend[cite: 6].

---
## 📸 Screenshots
<div align="center">
  <img width="80%" height="2345" alt="travelies" src="https://github.com/user-attachments/assets/3a31ad2b-b449-4dca-b9bb-dd96a4a478b8" />
</div>

## ✨ Key Features

*   **Interactive Maps:** Visualization of trips and multimedia posts via pins on an interactive map developed using the MapKit framework[cite: 6].
*   **Multimedia Integration:** Capture photos and record videos directly through a custom integrated camera, or by selecting them from the device's Photos app[cite: 6].
*   **Geotagging:** Multimedia posts automatically include location data (latitude and longitude) and the acquisition date[cite: 6].
*   **Social & Collaboration:** Account creation, friendship management, and the ability to view the public trips of friends[cite: 6].
*   **Deep Link Invitations:** Trip creators can invite participants or add friends by generating and sharing a unique dedicated link[cite: 6].
*   **Privacy Controls:** Management of trip privacy to decide whether to make them visible to the circle of friends or keep them private[cite: 6].

## 🛠️ Tech Stack

**Front-end (iOS)**
*   **Language & UI:** Swift, SwiftUI, UIKit[cite: 6].
*   **Frameworks:** MapKit (for the map), UIActivityViewController (for sharing)[cite: 6].
*   **Architecture:** Layered structure based on Model, DataModel, and Repository[cite: 6].

**Back-end & Infrastructure**
*   **Stack:** LAMP (Linux, Apache, MySQL, PHP) hosted on an Ubuntu 24.04 Virtual Private Server[cite: 6].
*   **API:** RESTful API based on a Controller architecture[cite: 6].
*   **Database Access:** PDO (PHP Data Objects) library with prepared statements to prevent vulnerabilities such as SQL Injection[cite: 6].

## 🧠 Architecture & Core Logic

*   **Custom Session Management:** Authentication state is maintained using a unique session key (valid for two weeks), stored in `UserDefaults` on the client side and verified by the MySQL database at each app launch[cite: 6].
*   **Caching System:** The application reduces network load and prevents slowdowns by managing multimedia content in memory through the concurrent `TCache` class[cite: 6].
*   **URL Scheme Handling:** The invitation system is based on structured links (e.g., `travelies://f?invite=...` and `travelies://j?invite=...`). The app intercepts the incoming URL, extracts the parameter, and triggers an asynchronous POST request to the server to validate the friendship or participation[cite: 6].
*   **Multipart Uploads:** Post uploading analyzes the initial byte sequences ("signatures") of the files in real-time to safely infer the correct MIME type (JPEG, PNG, or MP4) before transmitting the data to the server[cite: 6].

## 🚀 Getting Started

The application consumes a Custom REST API for managing data and multimedia resources[cite: 6]. 

To test the application's interface locally via Xcode:
1. Clone the repository.
2. Open the project file in Xcode (make sure you have a Mac and a targeted iOS simulator or device)[cite: 6].
3. Build the project. *(Note: Some network features might require connection to a mocked local backend if the live server is unreachable).*

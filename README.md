
<div align="center">
  <img width="128" height="128" alt="AppIcon 1" src="https://github.com/user-attachments/assets/31683c5a-7bef-49b7-a4d5-ce1610e393f1" />
</div>
<div align="center">
    A collaborative iOS application built with Swift and SwiftUI to<br>track trips, share multimedia moments, and manage collaborative<br>travel experiences.
</div>
<br>
<div align="center">
  <img width="75%" height="5849" alt="travelies" src="https://github.com/user-attachments/assets/50adf7c9-7087-4fae-b28a-25b969192646" />
</div>

---
<h1>Travelies</h1>
<p>Travelies was born with the objective of modernizing the concept of a photo album, combining geolocated multimedia documentation with a social infrastructure. The project includes the iOS client app and a custom REST API for the backend</p>

## 📸 Screenshots
<table align="center">
  <tr>
    <td align="center">
      <img width="60%" height="1280" alt="photo_2026-09-24_23-51-21 1" src="https://github.com/user-attachments/assets/babe517a-038b-4ea9-aa1c-6ff349235d07" />
      <br /><em>Upload</em>
    </td>
    <td align="center">
      <img width="60%" height="1280" alt="photo_2026-09-24_23-51-22 1" src="https://github.com/user-attachments/assets/0f15e927-042b-4a96-a759-e402a3bfc9e1" />
      <br /><em>Query</em>
    </td>
  </tr>
  <tr>
    <td align="center">
      <img width="60%" height="1280" alt="Group 51" src="https://github.com/user-attachments/assets/0b03b8ba-1bab-4251-8f1a-c1166862b1c1" />
      <br /><em>Folder Analysis</em>
    </td>
    <td align="center">
      <img width="60%" height="1280" alt="photo_2026-09-24_23-51-20 1" src="https://github.com/user-attachments/assets/27cbfa71-8a45-483a-8334-85a214b396e5" />
      <br /><em>Doc Analysis</em>
    </td>
  </tr>
</table>
  
## 🎯 Key Features

*   **Interactive Maps:** Visualization of trips and multimedia posts via pins on an interactive map developed using the MapKit framework.
*   **Multimedia Integration:** Capture photos and record videos directly through a custom integrated camera, or by selecting them from the device's Photos app.
*   **Geotagging:** Multimedia posts automatically include location data (latitude and longitude) and the acquisition date.
*   **Social & Collaboration:** Account creation, friendship management, and the ability to view the public trips of friends.
*   **Deep Link Invitations:** Trip creators can invite participants or add friends by generating and sharing a unique dedicated link.
*   **Privacy Controls:** Management of trip privacy to decide whether to make them visible to the circle of friends or keep them private.

## 🛠️ Tech Stack
*   **Language & UI:** Swift, SwiftUI, UIKit.
*   **Frameworks:** MapKit (for the map), UIActivityViewController (for sharing).
*   **Architecture:** Layered structure based on Model, DataModel, and Repository.

## 🧠 Architecture & Core Logic

*   **Custom Session Management:** Authentication state is maintained using a unique session key (valid for two weeks), stored in `UserDefaults` on the client side and verified by the MySQL database at each app launch.
*   **Caching System:** The application reduces network load and prevents slowdowns by managing multimedia content in memory through the concurrent `TCache` class.
*   **URL Scheme Handling:** The invitation system is based on structured links (e.g., `travelies://f?invite=...` and `travelies://j?invite=...`). The app intercepts the incoming URL, extracts the parameter, and triggers an asynchronous POST request to the server to validate the friendship or participation.
*   **Multipart Uploads:** Post uploading analyzes the initial byte sequences ("signatures") of the files in real-time to safely infer the correct MIME type (JPEG, PNG, or MP4) before transmitting the data to the server.

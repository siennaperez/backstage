# Backstage

Hi hi! This is a project I created for the UF WiCSE x AMEX Shadowing program. It reflects my love for concerts by connecting users together based on events in common. More details can be found below the run instructions.

## How to Run

This project was built in Flutter, however, I deployed this "mobile app" via Chrome, using the following: 
- "flutter pub get" to update your dependencies
- "flutter run -d chrome" to open locally in a minimized chrome window

To connect your own API key, a .env file will need the following format: 

      API_KEY=
      APP_ID=
      MESSAGING_SENDER_ID=
      PROJECT_ID=
      AUTH_DOMAIN=
      STORAGE_BUCKET=
      MEASUREMENT_ID=
      TICKETMASTER_API_KEY=

## Report

AMEX WiCSE Shadowing Project: Final Report
Project Overview
  As a concert enthusiast, there is nothing I look forward to more than planning my next show. With that, sometimes it can be hard to find all the nearby events and someone to bring along. The Backstage app brings together concert discovery, ticketing insights, and social driven features to make going to shows as seamless and exciting as the music itself.
This app provides:
➔ Personalized concert finding: pulling data from nearby events via the Ticketmaster
API.
➔ Ticket insights: presents the starting ticket cost for each show.
➔ Buddy discovery: allow approved messaging for those coming to the same events
as you. Target Audience:
➔ Backstage is targeted towards younger audiences looking to make new friends and feel comfortable attending events without the company of their current friends. When creating this, I had college students, new grads, and recently relocated individuals in mind.
 Deliverables and their Process
➔ Authentication: users are prompted to log into their account, accepting information like display name, username, email, and password. This process is linked to the Firebase database user group.
➔ Profile edits: once logged in, users can edit their previous log in information, as well as profile photo, location, and bio.
➔ API integration: the home feed recommends nearby and upcoming events and their cheapest ticket options via the Ticketmaster API. The location preference can be adjusted in the profile page, but is set to Tampa, FL by default. The API provides a picture of the event, artist name, location, and date.
➔ Attending events: users have the ability to mark/check off these events as “attendingˮ, which appears on their personal profile and publicly to others.
➔ Messaging: users can find anyone signed up on the app and their publicly displayed events, allowing them to decide to message people based on events in common and/or events they are debating on attending. Messaging is provided via the same Firebase database, by adding all users to the same subgroup and allowing you to filter by username.
  
 Timeline and Updates
Divided into three sprints, each being 4 weeks long:
1. Sprint 1: Planning and basic initiation
2. Sprint 2: Development and finetuning
3. Sprint 3: Advanced Features and Deploying (if time allows)
  
   Timeline Reflections
While the project scope remained the same, I removed the task of deploying the app. I discovered that my laptop does not have enough storage space to download XCode, and therefore launched the app locally through a small Chrome window, rather than on an IOS or Android simulator. I also did not have time for user experience feedback by testing the app amongst friends, as this was limited to a 2 credit project. I still love the app I was able to create and am grateful for the learning experiences along the way.

Code and Technologies
➔ The sprint schedule was managed on Jira
➔ Wireframing was completed using Figma
➔ The tech stack includes the Dart language with a
Flutter stack
➔ Deployed on Chrome using “flutter run -d chromeˮ
➔ Ticketmaster API for events, filtered into just concerts (removing sports events, comedy, etc.)

 Resources used
Throughout the semester, I utilized a fair amount of YouTube tutorials, API and Firebase documentation, and advice from my AMEX mentor. There were also times when referencing Stack Overflow or AI was beneficial to save time debugging.
Tests performed and their results
To test user signups, logins, and messaging, I created a few demo accounts to practice creating connections. The results are shown below in screenshots:
 
Conclusions
In completing this project, I was able to bring together my love for live music and software engineering to create a product that I would personally use. While I faced limitations in deployment and formal user testing, the development process allowed me to explore a new stack of technologies and refresh my API integration and database setup skills. This project was a fun way to strengthen my AGILE process understanding, holding myself accountable to sprints without a group. In the future, I hope to implement another additional feature, whether that is teaching myself a cloud function or adding more security aspects, since that is another interest of mine.

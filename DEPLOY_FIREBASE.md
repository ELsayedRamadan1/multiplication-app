Steps to build and deploy the Flutter web app to Firebase Hosting

Prerequisites
- Node.js + npm installed (needed for firebase-tools)
- Firebase CLI (optional locally) or use GitHub Actions for CI
- A Firebase project and hosting site
- GitHub repository (we added a GitHub Action in `.github/workflows/firebase-hosting.yml`)

Local quick deploy (for testing):
1. Install firebase-tools if you don't have it:

   npm install -g firebase-tools

2. Login to Firebase:

   firebase login

3. From the repo root, build the web app:

   flutter clean
   flutter pub get
   flutter build web --release

4. Initialize hosting (if not already initialized):

   firebase init hosting
   # Choose existing project -> select your Firebase project
   # public directory: build/web
   # configure as single-page app: yes

5. Deploy:

   firebase deploy --only hosting

Using GitHub Actions CI (recommended):
1. The workflow `.github/workflows/firebase-hosting.yml` runs on pushes to `main` and will:
   - Set up Flutter
   - Build the web app
   - Install firebase-tools and deploy to Firebase Hosting

2. Add two repository secrets in GitHub:
   - `FIREBASE_TOKEN` - a CI token for firebase (see below on how to create it)
   - `FIREBASE_PROJECT` - your Firebase project id (e.g. my-app-12345)

Creating a `FIREBASE_TOKEN` for CI
1. Locally (or on any machine with the Firebase CLI):

   firebase login:ci

   # copy the token printed by the command

2. In your GitHub repository: Settings -> Secrets -> Actions -> New repository secret
   - Name: FIREBASE_TOKEN
   - Value: <the token you copied>

3. Also add `FIREBASE_PROJECT` as a repository secret with the project id.

Triggering deploy
- Push to `main` branch or run the workflow manually from the Actions tab.

Notes
- The GitHub Action uses `subosito/flutter-action@v2` to install Flutter, which uses the stable release by default.
- If your repository default branch is not `main`, edit the workflow trigger accordingly.
- If you prefer to use an App Check or other advanced Firebase features, configure them in the Firebase Console.

If you want, I can also:
- Change the trigger to run on tags (e.g., only deploy when you push a semver tag)
- Add a preview/staging target in Firebase and a separate workflow
- Help create the Firebase project and set up hosting if you give me the project id or want instructions for creating it


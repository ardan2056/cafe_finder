/*
 Example helper: obtain Firebase ID token from a web client (modular SDK)
 and call the backend with Authorization: Bearer <ID_TOKEN>

 This is a small example intended to be run in a browser context where
 the Firebase Web SDK is available. It demonstrates how to get the current
 user's ID token and call the backend `/admin/promote` endpoint.
*/

// Import the modular SDK when using bundlers. For a simple CDN usage, adapt accordingly.
// import { getAuth } from 'firebase/auth';

async function callPromoteEndpoint(backendUrl, uid, role) {
  // Assumes firebase has been initialized in the web app and user is signed in
  const auth = firebase.auth(); // if using compat or older namespace; otherwise use getAuth()
  const user = auth.currentUser;
  if (!user) throw new Error('User not signed in');
  const idToken = await user.getIdToken();

  const resp = await fetch(`${backendUrl}/admin/promote`, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
      'Authorization': `Bearer ${idToken}`
    },
    body: JSON.stringify({ uid, role })
  });
  return resp.json();
}

module.exports = { callPromoteEndpoint };

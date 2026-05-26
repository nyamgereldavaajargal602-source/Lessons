// Profile page script
const emailElement = document.querySelector('.account-email');
const signOutButton = document.getElementById('signOut');

// Auth check happens in navigation.js

const userEmail = localStorage.getItem('eMongoliaUserEmail');
if (emailElement) {
  emailElement.textContent = userEmail;
}

if (signOutButton) {
  signOutButton.addEventListener('click', () => {
    localStorage.removeItem('eMongoliaUserEmail');
    window.location.href = 'index.html';
  });
}


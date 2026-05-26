// Navigation and authentication check
const userEmail = localStorage.getItem('eMongoliaUserEmail');

// Check if user is authenticated on protected pages
function checkAuth() {
  const currentPage = window.location.pathname;
  const protectedPages = ['home.html', 'profile.html', 'services.html', 'more.html'];
  
  // Check if current page is protected
  const isProtected = protectedPages.some(page => currentPage.includes(page));
  
  if (isProtected && !userEmail) {
    window.location.href = 'index.html';
  }
}

// Initialize auth check on page load
checkAuth();

// Update active nav item
document.addEventListener('DOMContentLoaded', () => {
  const currentPage = window.location.pathname.split('/').pop() || 'home.html';
  const navItems = document.querySelectorAll('.nav-item');
  
  navItems.forEach(item => {
    item.classList.remove('active');
    
    // Check if this nav item should be active
    const onclick = item.getAttribute('onclick');
    if (onclick && onclick.includes(currentPage)) {
      item.classList.add('active');
    }
  });
});

// Sign out handler
const signOutButton = document.getElementById('signOut');
if (signOutButton) {
  signOutButton.addEventListener('click', () => {
    localStorage.removeItem('eMongoliaUserEmail');
    window.location.href = 'index.html';
  });
}

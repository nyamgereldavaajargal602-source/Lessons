const emailInput = document.getElementById('email');
const passwordInput = document.getElementById('password');
const submitButton = document.getElementById('submit');
const errorBox = document.getElementById('error');
const buttonText = submitButton.querySelector('.button-text');
const spinner = submitButton.querySelector('.spinner');

function updateButtonState() {
  const email = emailInput.value.trim();
  const password = passwordInput.value;
  submitButton.disabled = email.length === 0 || password.length === 0;
}

function showError(message) {
  errorBox.textContent = message;
  errorBox.classList.remove('hidden');
}

function clearError() {
  errorBox.textContent = '';
  errorBox.classList.add('hidden');
}

function setLoading(loading) {
  if (loading) {
    submitButton.disabled = true;
    buttonText.textContent = '';
    spinner.classList.remove('hidden');
  } else {
    spinner.classList.add('hidden');
    buttonText.textContent = 'Log In';
    updateButtonState();
  }
}

function isValidEmail(value) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(value);
}

submitButton.addEventListener('click', async () => {
  const email = emailInput.value.trim();
  const password = passwordInput.value;

  clearError();

  if (email.length === 0 || password.length === 0) {
    showError('Email and password are required.');
    return;
  }

  if (!isValidEmail(email)) {
    showError('Please enter a valid email address.');
    return;
  }

  setLoading(true);
  await new Promise((resolve) => setTimeout(resolve, 800));
  setLoading(false);

  if (password.length < 4) {
    showError('Invalid email or password.');
    return;
  }

  localStorage.setItem('eMongoliaUserEmail', email);
  window.location.href = 'home.html';
});

[emailInput, passwordInput].forEach((input) => {
  input.addEventListener('input', () => {
    clearError();
    updateButtonState();
  });
});

updateButtonState();

(() => {
  'use strict';

  const ACCOUNTS_KEY = 'ligtaslink.accounts.v1';
  const SESSION_KEY = 'ligtaslink.session.v1';
  const encoder = new TextEncoder();
  const $ = (id) => document.getElementById(id);

  const elements = {
    authView: $('authView'),
    homeView: $('homeView'),
    loginForm: $('loginForm'),
    loginEmail: $('loginEmail'),
    loginPassword: $('loginPassword'),
    loginError: $('loginError'),
    registerDialog: $('registerDialog'),
    registerForm: $('registerForm'),
    registerError: $('registerError'),
    resetDialog: $('resetDialog'),
    resetForm: $('resetForm'),
    resetError: $('resetError'),
    toast: $('toast'),
    userName: $('userName'),
    userEmail: $('userEmail')
  };

  function loadAccounts() {
    try {
      const parsed = JSON.parse(localStorage.getItem(ACCOUNTS_KEY) || '[]');
      return Array.isArray(parsed) ? parsed : [];
    } catch {
      return [];
    }
  }

  function saveAccounts(accounts) {
    localStorage.setItem(ACCOUNTS_KEY, JSON.stringify(accounts));
  }

  function bytesToBase64(bytes) {
    let binary = '';
    bytes.forEach((byte) => { binary += String.fromCharCode(byte); });
    return btoa(binary);
  }

  function randomSalt() {
    const bytes = new Uint8Array(18);
    crypto.getRandomValues(bytes);
    return bytesToBase64(bytes);
  }

  async function passwordHash(value, salt) {
    const material = await crypto.subtle.importKey(
      'raw', encoder.encode(value), { name: 'PBKDF2' }, false, ['deriveBits']
    );
    const bits = await crypto.subtle.deriveBits(
      { name: 'PBKDF2', hash: 'SHA-256', salt: encoder.encode(salt), iterations: 120000 },
      material,
      256
    );
    return bytesToBase64(new Uint8Array(bits));
  }

  function normalizeEmail(value) {
    return value.trim().toLowerCase();
  }

  function showError(element, message) {
    element.textContent = message;
    element.hidden = !message;
  }

  function setBusy(form, busy) {
    form.querySelectorAll('button, input').forEach((control) => { control.disabled = busy; });
  }

  let toastTimer;
  function toast(message) {
    clearTimeout(toastTimer);
    elements.toast.textContent = message;
    elements.toast.hidden = false;
    toastTimer = setTimeout(() => { elements.toast.hidden = true; }, 3200);
  }

  function validateForm(form) {
    form.querySelectorAll('input').forEach((input) => input.classList.toggle('invalid', !input.checkValidity()));
    return form.reportValidity();
  }

  function showHome(account) {
    localStorage.setItem(SESSION_KEY, account.email);
    elements.userName.textContent = account.name;
    elements.userEmail.textContent = account.email;
    elements.authView.hidden = true;
    elements.homeView.hidden = false;
    document.title = `LigtasLink · ${account.name}`;
  }

  function showLogin() {
    elements.homeView.hidden = true;
    elements.authView.hidden = false;
    document.title = 'LigtasLink';
  }

  $('registerButton').addEventListener('click', () => {
    elements.registerForm.reset();
    showError(elements.registerError, '');
    elements.registerDialog.showModal();
    $('registerName').focus();
  });

  $('forgotButton').addEventListener('click', () => {
    elements.resetForm.reset();
    $('resetEmail').value = elements.loginEmail.value.trim();
    showError(elements.resetError, '');
    elements.resetDialog.showModal();
    $('resetEmail').focus();
  });

  document.querySelectorAll('[data-close]').forEach((button) => {
    button.addEventListener('click', () => $(button.dataset.close).close());
  });

  document.querySelectorAll('[data-toggle-password]').forEach((button) => {
    button.addEventListener('click', () => {
      const input = $(button.dataset.togglePassword);
      const revealing = input.type === 'password';
      input.type = revealing ? 'text' : 'password';
      button.textContent = revealing ? 'Hide' : 'Show';
      button.setAttribute('aria-label', revealing ? 'Hide password' : 'Show password');
    });
  });

  elements.loginForm.addEventListener('submit', async (event) => {
    event.preventDefault();
    showError(elements.loginError, '');
    if (!validateForm(elements.loginForm)) return;
    setBusy(elements.loginForm, true);
    try {
      const email = normalizeEmail(elements.loginEmail.value);
      const account = loadAccounts().find((candidate) => candidate.email === email);
      if (!account || await passwordHash(elements.loginPassword.value, account.passwordSalt) !== account.passwordHash) {
        showError(elements.loginError, 'Incorrect email or password.');
        return;
      }
      elements.loginPassword.value = '';
      showHome(account);
    } catch {
      showError(elements.loginError, 'This browser could not open local storage. Try Microsoft Edge or Google Chrome.');
    } finally {
      setBusy(elements.loginForm, false);
    }
  });

  elements.registerForm.addEventListener('submit', async (event) => {
    event.preventDefault();
    showError(elements.registerError, '');
    if (!validateForm(elements.registerForm)) return;
    if ($('registerPassword').value !== $('registerConfirm').value) {
      showError(elements.registerError, 'Passwords do not match.');
      return;
    }
    setBusy(elements.registerForm, true);
    try {
      const accounts = loadAccounts();
      const email = normalizeEmail($('registerEmail').value);
      if (accounts.some((account) => account.email === email)) {
        showError(elements.registerError, 'An account with that email already exists.');
        return;
      }
      const passwordSalt = randomSalt();
      const pinSalt = randomSalt();
      const account = {
        name: $('registerName').value.trim(),
        email,
        passwordSalt,
        passwordHash: await passwordHash($('registerPassword').value, passwordSalt),
        pinSalt,
        pinHash: await passwordHash($('registerPin').value, pinSalt)
      };
      accounts.push(account);
      saveAccounts(accounts);
      elements.registerDialog.close();
      showHome(account);
      toast('Account created successfully.');
    } catch {
      showError(elements.registerError, 'The account could not be saved. Try Microsoft Edge or Google Chrome.');
    } finally {
      setBusy(elements.registerForm, false);
    }
  });

  elements.resetForm.addEventListener('submit', async (event) => {
    event.preventDefault();
    showError(elements.resetError, '');
    if (!validateForm(elements.resetForm)) return;
    setBusy(elements.resetForm, true);
    try {
      const accounts = loadAccounts();
      const email = normalizeEmail($('resetEmail').value);
      const index = accounts.findIndex((account) => account.email === email);
      if (index < 0) {
        showError(elements.resetError, 'No account was found for that email.');
        return;
      }
      const account = accounts[index];
      if (await passwordHash($('resetPin').value, account.pinSalt) !== account.pinHash) {
        showError(elements.resetError, 'The recovery PIN is incorrect.');
        return;
      }
      const passwordSalt = randomSalt();
      account.passwordSalt = passwordSalt;
      account.passwordHash = await passwordHash($('resetPassword').value, passwordSalt);
      accounts[index] = account;
      saveAccounts(accounts);
      elements.resetDialog.close();
      elements.loginEmail.value = email;
      toast('Password changed. You can now sign in.');
    } catch {
      showError(elements.resetError, 'The password could not be changed on this browser.');
    } finally {
      setBusy(elements.resetForm, false);
    }
  });

  $('signOutButton').addEventListener('click', () => {
    localStorage.removeItem(SESSION_KEY);
    showLogin();
    toast('Signed out.');
  });

  document.querySelectorAll('input').forEach((input) => {
    input.addEventListener('input', () => input.classList.remove('invalid'));
  });

  try {
    const sessionEmail = localStorage.getItem(SESSION_KEY);
    const account = loadAccounts().find((candidate) => candidate.email === sessionEmail);
    if (account) showHome(account); else showLogin();
  } catch {
    showLogin();
    showError(elements.loginError, 'Please open this app in Microsoft Edge or Google Chrome.');
  }
})();

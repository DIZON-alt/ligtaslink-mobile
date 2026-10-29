const http = require('node:http');
const crypto = require('node:crypto');
const fs = require('node:fs/promises');
const path = require('node:path');

const PORT = Number(process.env.PORT) || 3000;
const DATA_FILE = path.join(__dirname, '..', 'assets', 'data.json');
const SERVICES_FILE = path.join(__dirname, '..', 'assets', 'services.json');

async function readData() {
  try {
    const contents = await fs.readFile(DATA_FILE, 'utf8');
    const data = JSON.parse(contents);
    return { users: Array.isArray(data.users) ? data.users : [] };
  } catch (error) {
    if (error.code === 'ENOENT') return { users: [] };
    throw error;
  }
}

async function writeData(data) {
  await fs.writeFile(DATA_FILE, `${JSON.stringify(data, null, 2)}\n`, 'utf8');
}

async function readServices() {
  const contents = await fs.readFile(SERVICES_FILE, 'utf8');
  const catalog = JSON.parse(contents);
  return {
    catalog: catalog.catalog,
    services: Array.isArray(catalog.services) ? catalog.services : [],
  };
}

function sendJson(response, statusCode, body) {
  response.writeHead(statusCode, {
    'Content-Type': 'application/json; charset=utf-8',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, PATCH, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
  });
  response.end(JSON.stringify(body));
}

async function readJsonBody(request) {
  let body = '';
  for await (const chunk of request) {
    body += chunk;
    if (body.length > 1_000_000) throw new Error('Request body is too large.');
  }
  if (!body) return {};
  const parsed = JSON.parse(body);
  if (!parsed || typeof parsed !== 'object' || Array.isArray(parsed)) {
    throw new Error('Request body must be a JSON object.');
  }
  return parsed;
}

function publicUser(user) {
  return { id: user.id, name: user.name, email: user.email, createdAt: user.createdAt };
}

function hashSecret(value, salt) {
  return crypto.scryptSync(value, salt, 64).toString('hex');
}

function verifySecret(value, salt, expectedHash) {
  const actualHash = Buffer.from(hashSecret(value, salt), 'hex');
  const expected = Buffer.from(expectedHash, 'hex');
  return actualHash.length === expected.length && crypto.timingSafeEqual(actualHash, expected);
}

function validateUser(body, partial = false) {
  const fields = {};
  if (!partial || body.name !== undefined) {
    if (typeof body.name !== 'string' || body.name.trim().length < 2) {
      return { error: 'name must contain at least 2 characters.' };
    }
    fields.name = body.name.trim();
  }
  if (!partial || body.email !== undefined) {
    if (typeof body.email !== 'string' || !/^\S+@\S+\.\S+$/.test(body.email.trim())) {
      return { error: 'email must be a valid email address.' };
    }
    fields.email = body.email.trim().toLowerCase();
  }
  return { fields };
}

function validateCredentials(body) {
  const user = validateUser(body);
  if (user.error) return user;
  if (typeof body.password !== 'string' || body.password.length < 8) {
    return { error: 'password must contain at least 8 characters.' };
  }
  if (typeof body.recoveryPin !== 'string' || !/^\d{4,8}$/.test(body.recoveryPin)) {
    return { error: 'recoveryPin must contain 4 to 8 digits.' };
  }
  return { fields: { ...user.fields, password: body.password, recoveryPin: body.recoveryPin } };
}

function credentialUser(user) {
  return { ...publicUser(user), token: user.id };
}

async function handleRequest(request, response) {
  if (request.method === 'OPTIONS') {
    sendJson(response, 204, {});
    return;
  }

  const url = new URL(request.url, `http://${request.headers.host || 'localhost'}`);
  const parts = url.pathname.split('/').filter(Boolean);

  if (request.method === 'GET' && url.pathname === '/api/health') {
    sendJson(response, 200, { status: 'ok', service: 'ligtaslink-api' });
    return;
  }

  if (request.method === 'GET' && url.pathname === '/api/services') {
    sendJson(response, 200, await readServices());
    return;
  }

  if (request.method === 'POST' && url.pathname === '/api/auth/register') {
    const body = await readJsonBody(request);
    const validation = validateCredentials(body);
    if (validation.error) {
      sendJson(response, 400, { error: validation.error });
      return;
    }
    const data = await readData();
    if (data.users.some((user) => user.email === validation.fields.email)) {
      sendJson(response, 409, { error: 'A user with that email already exists.' });
      return;
    }
    const passwordSalt = crypto.randomBytes(16).toString('hex');
    const pinSalt = crypto.randomBytes(16).toString('hex');
    const user = {
      id: crypto.randomUUID(),
      name: validation.fields.name,
      email: validation.fields.email,
      passwordSalt,
      passwordHash: hashSecret(validation.fields.password, passwordSalt),
      pinSalt,
      pinHash: hashSecret(validation.fields.recoveryPin, pinSalt),
      createdAt: new Date().toISOString(),
    };
    data.users.push(user);
    await writeData(data);
    sendJson(response, 201, credentialUser(user));
    return;
  }

  if (request.method === 'POST' && url.pathname === '/api/auth/login') {
    const body = await readJsonBody(request);
    const email = typeof body.email === 'string' ? body.email.trim().toLowerCase() : '';
    const user = (await readData()).users.find((candidate) => candidate.email === email);
    if (!user || typeof body.password !== 'string' || !verifySecret(body.password, user.passwordSalt, user.passwordHash)) {
      sendJson(response, 401, { error: 'Incorrect email or password.' });
      return;
    }
    sendJson(response, 200, credentialUser(user));
    return;
  }

  if (request.method === 'POST' && url.pathname === '/api/auth/reset-password') {
    const body = await readJsonBody(request);
    const data = await readData();
    const email = typeof body.email === 'string' ? body.email.trim().toLowerCase() : '';
    const index = data.users.findIndex((candidate) => candidate.email === email);
    const user = data.users[index];
    if (!user) {
      sendJson(response, 404, { error: 'No account was found for that email.' });
      return;
    }
    if (typeof body.recoveryPin !== 'string' || !verifySecret(body.recoveryPin, user.pinSalt, user.pinHash)) {
      sendJson(response, 401, { error: 'The recovery PIN is incorrect.' });
      return;
    }
    if (typeof body.newPassword !== 'string' || body.newPassword.length < 8) {
      sendJson(response, 400, { error: 'newPassword must contain at least 8 characters.' });
      return;
    }
    const passwordSalt = crypto.randomBytes(16).toString('hex');
    data.users[index] = {
      ...user,
      passwordSalt,
      passwordHash: hashSecret(body.newPassword, passwordSalt),
    };
    await writeData(data);
    sendJson(response, 200, credentialUser(data.users[index]));
    return;
  }

  if (parts[0] !== 'api' || parts[1] !== 'users' || parts.length > 3) {
    sendJson(response, 404, { error: 'Route not found.' });
    return;
  }

  const data = await readData();
  const userId = parts[2];

  if (request.method === 'GET' && !userId) {
    sendJson(response, 200, { users: data.users.map(publicUser) });
    return;
  }

  if (request.method === 'GET' && userId) {
    const user = data.users.find((candidate) => candidate.id === userId);
    if (!user) {
      sendJson(response, 404, { error: 'User not found.' });
      return;
    }
    sendJson(response, 200, publicUser(user));
    return;
  }

  if (request.method === 'POST' && !userId) {
    const body = await readJsonBody(request);
    const validation = validateUser(body);
    if (validation.error) {
      sendJson(response, 400, { error: validation.error });
      return;
    }
    if (data.users.some((user) => user.email === validation.fields.email)) {
      sendJson(response, 409, { error: 'A user with that email already exists.' });
      return;
    }
    const user = {
      id: crypto.randomUUID(),
      ...validation.fields,
      createdAt: new Date().toISOString(),
    };
    data.users.push(user);
    await writeData(data);
    sendJson(response, 201, publicUser(user));
    return;
  }

  if ((request.method === 'PUT' || request.method === 'PATCH') && userId) {
    const index = data.users.findIndex((user) => user.id === userId);
    if (index < 0) {
      sendJson(response, 404, { error: 'User not found.' });
      return;
    }
    const body = await readJsonBody(request);
    const validation = validateUser(body, request.method === 'PATCH');
    if (validation.error) {
      sendJson(response, 400, { error: validation.error });
      return;
    }
    if (validation.fields.email && data.users.some((user, candidateIndex) => (
      candidateIndex !== index && user.email === validation.fields.email
    ))) {
      sendJson(response, 409, { error: 'A user with that email already exists.' });
      return;
    }
    data.users[index] = { ...data.users[index], ...validation.fields };
    await writeData(data);
    sendJson(response, 200, publicUser(data.users[index]));
    return;
  }

  if (request.method === 'DELETE' && userId) {
    const index = data.users.findIndex((user) => user.id === userId);
    if (index < 0) {
      sendJson(response, 404, { error: 'User not found.' });
      return;
    }
    const [deletedUser] = data.users.splice(index, 1);
    await writeData(data);
    sendJson(response, 200, publicUser(deletedUser));
    return;
  }

  sendJson(response, 405, { error: 'Method not allowed.' });
}

const server = http.createServer((request, response) => {
  handleRequest(request, response).catch((error) => {
    console.error(error);
    sendJson(response, 500, { error: 'Internal server error.' });
  });
});

server.listen(PORT, () => {
  console.log(`LigtasLink REST API listening on http://localhost:${PORT}`);
});

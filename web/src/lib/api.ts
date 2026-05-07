import axios from 'axios';

const API_BASE_URL = 'https://learno-school.onrender.com/api'; // Deployed URL
// const API_BASE_URL = 'http://localhost:3001/api'; // Local URL for testing

const api = axios.create({
  baseURL: API_BASE_URL,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Add interceptor to include auth token
api.interceptors.request.use((config) => {
  if (typeof window !== 'undefined') {
    const token = localStorage.getItem('auth_token');
    if (token) {
      config.headers.Authorization = `Bearer ${token}`;
    }
  }
  return config;
});

export default api;

import axios from 'axios';

// Configuração base da API
const api = axios.create({
  baseURL: process.env.REACT_APP_API_URL || 'http://localhost:8000',
  timeout: 10000,
  headers: {
    'Content-Type': 'application/json',
  },
});

// Interceptor para logging de requisições (apenas em desenvolvimento)
if (process.env.NODE_ENV === 'development') {
  api.interceptors.request.use(
    (config) => {
      console.log(`🚀 ${config.method?.toUpperCase()} ${config.url}`);
      return config;
    },
    (error) => {
      console.error('❌ Request Error:', error);
      return Promise.reject(error);
    }
  );

  api.interceptors.response.use(
    (response) => {
      console.log(`✅ ${response.config.method?.toUpperCase()} ${response.config.url} - ${response.status}`);
      return response;
    },
    (error) => {
      console.error(`❌ ${error.config?.method?.toUpperCase()} ${error.config?.url} - ${error.response?.status}`, error.response?.data);
      return Promise.reject(error);
    }
  );
}

export default api;
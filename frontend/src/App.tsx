import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { ThemeProvider, createTheme } from '@mui/material/styles';
import CssBaseline from '@mui/material/CssBaseline';
import { AuthProvider } from './contexts/AuthContext';
import ProtectedRoute from './components/auth/ProtectedRoute';
import LoginForm from './components/auth/LoginForm';
import Dashboard from './components/Dashboard';
import './App.css';

const theme = createTheme({
  palette: {
    mode: 'light',
    primary: {
      main: '#1976d2',
    },
    secondary: {
      main: '#dc004e',
    },
  },
});

function App() {
  return (
    <ThemeProvider theme={theme}>
      <CssBaseline />
      <Router>
        <AuthProvider>
          <div className="App">
            <Routes>
              {/* Rota de Login - Pública */}
              <Route path="/login" element={<LoginForm />} />
              
              {/* Rotas Protegidas */}
              <Route
                path="/dashboard"
                element={
                  <ProtectedRoute>
                    <Dashboard />
                  </ProtectedRoute>
                }
              />
              
              {/* Rota Raiz - Redireciona para Dashboard se autenticado, senão para Login */}
              <Route
                path="/"
                element={
                  <ProtectedRoute redirectToLogin={false}>
                    <Navigate to="/dashboard" replace />
                  </ProtectedRoute>
                }
              />
              
              {/* Rota Catch-all para URLs não encontradas */}
              <Route path="*" element={<Navigate to="/login" replace />} />
            </Routes>
          </div>
        </AuthProvider>
      </Router>
    </ThemeProvider>
  );
}

export default App;
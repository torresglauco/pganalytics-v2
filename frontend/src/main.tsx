import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import App from './App.tsx'
import './index.css'

console.log('🚀 main.tsx carregando...');

// Função helper para extrair mensagem de erro de forma type-safe
function getErrorMessage(error: unknown): string {
  if (error instanceof Error) {
    return error.message;
  }
  if (typeof error === 'string') {
    return error;
  }
  return 'Erro desconhecido';
}

try {
  console.log('🔍 Procurando elemento root...');
  const rootElement = document.getElementById('root');
  
  if (!rootElement) {
    console.error('❌ Elemento root não encontrado!');
    throw new Error('Elemento root não encontrado');
  }
  
  console.log('✅ Elemento root encontrado');
  const root = createRoot(rootElement);
  
  console.log('✅ CreateRoot executado');
  root.render(
    <StrictMode>
      <App />
    </StrictMode>
  );
  
  console.log('✅ Render executado com sucesso!');
  
  // Esconder loading se existir
  setTimeout(() => {
    const loading = document.getElementById('loading');
    if (loading) {
      loading.style.display = 'none';
      console.log('✅ Loading escondido');
    }
  }, 500);
  
} catch (error) {
  const errorMessage = getErrorMessage(error);
  console.error('❌ ERRO CRÍTICO no main.tsx:', errorMessage);
  
  // Mostrar erro na tela
  const loading = document.getElementById('loading');
  if (loading) {
    loading.innerHTML = `
      <div style="color: red; padding: 20px;">
        <h2>❌ ERRO NO REACT:</h2>
        <p>${errorMessage}</p>
        <p>Veja o console do browser para mais detalhes.</p>
      </div>
    `;
  } else {
    // Criar div de erro se não existe loading
    const errorDiv = document.createElement('div');
    errorDiv.innerHTML = `
      <div style="color: red; padding: 20px; font-family: Arial;">
        <h2>❌ ERRO NO REACT:</h2>
        <p>${errorMessage}</p>
      </div>
    `;
    document.body.appendChild(errorDiv);
  }
}

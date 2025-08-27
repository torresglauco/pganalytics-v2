/// <reference types="vite/client" />

interface ImportMetaEnv {
  readonly VITE_API_URL: string
  // adicione mais variáveis de ambiente aqui
}

interface ImportMeta {
  readonly env: ImportMetaEnv
}

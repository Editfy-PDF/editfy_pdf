# Editfy-PDF
Faça perguntas a arquivos PDF usando IA generativa.

# Roadmap

**Banco de dados local** ✅

**Criptografia de Chaves de API** ✅

**Serviços de IA** ✅

    - Extrai texto do PDF ✅
    - Conexão com API da OpenAI (local e remoto) ✅
    - Conexão com API da Gemini AI ✅
    - Inferência local (Llama.cpp + Vulkan) ✅
    - Algoritmo de busca de conteúdo relevante no PDF ✅

**Tela principal (Tela de Interações)** ✅
    
    - Imagem miniatura do arquivo ✅
    - Botão p/ adicionar documento ✅
    - Botão de redirecionamento p/ Tela Configurações ✅
    - salva novos elementos no banco de dados ✅
    - Lê do banco de dados e mostra elementos na tela ✅

**Tela de Chat** ✅

    - Input do usuário ✅
    - Salva o conteúdo da conversa no banco de dados ✅
    - Retorna conteúdo da conversa do banco de dados ✅
    - Envia input do usuário para o serviço de IA ✅
    - Botão de redirecionamento para Tela de Visualização de documento ✅

**Tela de Visualização de Documento** ✅
    
    - Renderiza documentos PDF ✅

**Tela de Configuração** ✅

    - Seletor de temas ✅
    - Seletor de serviço de IA ✅
        - OpenAI ✅
        - Google Gemini ✅
        - Servidor Personalizado (compatível com API da OpenAI) ✅
        - Llama.cpp (inferência local com uso de GPU através do Vulkan) ✅
# Google Play — ficha em português (pt-BR)

Rascunho da ficha brasileira do Praxis para o Google Play, adaptado de `app-store-listing-pt-BR.md`. A descrição abaixo só afirma recursos do build atual do Android. Campos que dependem de uma decisão humana estão em **Pendências antes de publicar**.

A descrição é a mesma das duas lojas: ao mudá-la aqui, mude também em `app-store-listing-pt-BR.md` (e vice-versa). Só os campos e os limites de caracteres diferem.

## Metadados

- **Nome do app (até 30 caracteres):** Praxis
- **Descrição curta (até 80 caracteres):**

  Leia e estude textos marxistas do Marxists Internet Archive, em português.

- **Descrição completa (até 4.000 caracteres):**

  Leia e estude textos do Marxists Internet Archive, em português.

  Explore autores, obras, temas e história. Pesquise no catálogo, salve textos para encontrar depois e acompanhe seu histórico e progresso de leitura no aparelho.

  Ajuste a experiência de leitura com opções de fonte, tamanho, entrelinha, margens, alinhamento e cores. Abra textos e PDFs do arquivo e continue de onde parou.

  O catálogo vem incluído no app. Textos, PDFs e retratos são carregados do Marxists Internet Archive quando necessário; é preciso ter conexão para abrir conteúdo que ainda não está em cache.

  O Praxis não exige conta e não tem anúncios nem compras. Favoritos, histórico, progresso e preferências ficam no aparelho. O compartilhamento de análises de uso é opcional e desativado por padrão; os eventos enviados não incluem títulos, nomes de autores, termos de busca nem posições de leitura.

  O app apresenta atribuição de fonte aos textos do Marxists Internet Archive e aos respectivos autores e tradutores.

- **Categoria:** Livros e referência
- **Tags sugeridas (escolher na lista fixa da Play Console, até 5):** Livros e referência · Educação · História · Política · Filosofia
- **E-mail de contato:** support@guifran.co
- **URL da política de privacidade:** https://guifrancoabreu.github.io/praxis/privacy.html
- **URL de suporte:** https://guifrancoabreu.github.io/praxis/
- **Direitos autorais:** pendente — confirmar o titular legal antes de preencher.
- **Classificação etária:** pendente — depende do questionário IARC (ver pendências).
- **Dispositivos:** somente telefone, retrato. Excluir tablets no catálogo de dispositivos.
- **Preço:** gratuito, sem compras no app.

## Segurança dos dados — rascunho para a Play Console

Preencher o formulário *Segurança dos dados* com as respostas abaixo. Elas descrevem este build: sem conta, dados de leitura no aparelho, sem identificador de publicidade, análises opcionais e conteúdo carregado de marxists.org.

| Seção do formulário | Resposta sugerida |
|---|---|
| Coleta ou compartilhamento de dados obrigatório | Não. O app funciona sem conta e sem enviar dados pessoais. |
| Conta e login | O app não cria conta. Nenhum dado de conta é coletado. |
| Dados de leitura (textos salvos, histórico, posição, preferências) | Armazenados apenas no armazenamento local do app. Não são enviados ao desenvolvedor. Desinstalar o app ou limpar os dados apaga tudo. |
| Localização, contatos, arquivos, fotos, mensagens, saúde, finanças | Não coletados. |
| Identificador de publicidade | Não. O app não usa ID de publicidade nem SDK de anúncios. |
| Anúncios | Nenhum. |
| Atividade no app (interações) | Coletada **somente se a pessoa ativar o compartilhamento opcional**, desativado por padrão. Eventos gerais: filtro escolhido, uso da busca, abertura de autor ou texto, favorito, controles do leitor, links de apoio. Sem título, autor, termo de busca, caminho do arquivo ou posição de leitura. |
| Identificadores | Nenhum identificador persistente. O SDK do TelemetryDeck roda em memória, sem identificador de instalação guardado entre execuções. |
| Finalidade da atividade no app | Análises e melhoria do produto. Sem publicidade, sem personalização de anúncios, sem venda de dados. |
| Compartilhamento com terceiros | Os eventos vão para o TelemetryDeck, que atua como provedor de análise; não há venda nem repasse para anunciantes. |
| Criptografia em trânsito | Sim. As solicitações usam HTTPS. |
| Exclusão de dados | Não há conta. Os dados locais somem ao desinstalar ou limpar os dados do app. Para os eventos opcionais, o pedido pode ser feito por e-mail. |
| Conteúdo do arquivo (marxists.org) | Quando a pessoa abre um texto, PDF ou retrato ainda não armazenado em cache, o app solicita o conteúdo diretamente a `www.marxists.org`. O servidor do arquivo pode ver IP e dados da conexão. O arquivo não é operado pelo Praxis. |
| Links externos | O app abre Ko-fi e Marxists.org no navegador; esses sites seguem as próprias políticas. |

Não declarar "nenhum dado coletado" de forma genérica: a atividade no app existe quando o compartilhamento opcional é ativado, e as solicitações ao arquivo chegam a um servidor de terceiros. Revisar também as declarações exigidas para SDKs incorporados no binário enviado.

## Pendências antes de publicar

1. **Direitos sobre o conteúdo:** revisar a situação de uso dos textos, PDFs e retratos do Marxists Internet Archive antes de publicar a ficha e o app.
2. **Questionário IARC:** responder no Play Console e aplicar a classificação etária resultante.
3. **Declarações da Play Console:** confirmar segurança dos dados, público-alvo e conteúdo, anúncios (nenhum), acesso ao app e exclusão de tablets.
4. **Keystore:** criar e guardar a chave de upload fora do repositório e ativar o Play App Signing.

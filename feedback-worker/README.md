# Envio de feedback

O app envia feedback para um Cloudflare Worker, que encaminha o texto para `support@guifran.co` pela API do Resend. A chave fica apenas no Worker; o endereço fornecido pelo usuário é usado como reply-to. O endpoint não registra o conteúdo intencionalmente. O limite por IP reduz abuso, mas não garante sua prevenção; monitore o uso do Resend e configure proteções adicionais no Cloudflare se necessário.

1. Crie um remetente em um domínio verificado no Resend e uma chave de API com permissão de envio.
2. Em `feedback-worker`, instale/use o Wrangler autenticado e publique o Worker: `npx wrangler deploy`.
3. Configure os segredos no Worker: `npx wrangler secret put RESEND_API_KEY` e `npx wrangler secret put FEEDBACK_FROM_EMAIL`. Não inclua seus valores no repositório ou nos aplicativos. O remetente deve ser um endereço no domínio verificado.
4. Configure a URL HTTPS pública do Worker nos builds dos aplicativos. No iOS, defina o build setting `PRAXIS_FEEDBACK_URL` para a URL completa do Worker (por exemplo, via configuração de build ou `xcodebuild ... PRAXIS_FEEDBACK_URL=https://...`). Consulte a documentação Android para a configuração equivalente.
5. Envie um teste real após publicar e confira a entrega e o reply-to. Sem URL ou configuração do Worker o formulário exibirá erro e manterá os dados para nova tentativa.

O binding de rate limit do `wrangler.jsonc` é obrigatório; ajuste `namespace_id` para um número exclusivo na conta Cloudflare. Use Wrangler 4.36 ou posterior. O endpoint aceita apenas POST JSON com `type` (`bug` ou `suggestion`), `details` (até 5.000 caracteres) e `email`. Não disponibilize o serviço até revisar os limites e políticas de retenção aplicáveis na sua conta Cloudflare e no Resend.

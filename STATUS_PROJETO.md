# Status do projeto

## Engine e versão

- Godot 4.7.2 estável, edição padrão sem C#.
- Instalação portátil em `tools/godot/4.7.2/`.
- Renderizador Compatibility/OpenGL.
- Plataforma inicial: Windows.

## Execução e controles

- Abra `tools/godot/4.7.2/Godot_v4.7.2-stable_win64.exe` e importe `project.godot`, se necessário.
- Execute o projeto com **F5** no editor.
- Movimento: **WASD**.
- Ataque direcionado ao mouse: **clique esquerdo**.
- Ataque na direção atual: **Espaço**.
- Esquiva: **Shift** ou **Ctrl**, usando a direção do movimento; sem direção, usa a direção atual.
- Após vitória ou derrota: **R** inicia uma nova tentativa.

## Estado atual

- Conceito provisório: **Dívida Fantasma**, roguelite de ação cyberpunk em 2D com perspectiva isométrica.
- Demo de combate consolidada como versão `0.1.0` e exportada para Windows.
- Implementado: arena provisória isométrica, personagem, movimento em oito direções, câmera, colisões e ataque básico direcional.
- Implementado: esquiva direcional com recarga, invulnerabilidade configurável e respeito às colisões da arena.
- Implementado: alvo de treinamento com três pontos de vida e reinício automático após ser destruído.
- Implementado: inimigo corpo a corpo que persegue, sinaliza o alcance e ataca após preparação.
- Implementado: inimigo atirador que mantém distância, mostra a linha de mira e dispara projéteis.
- Implementado: cinco pontos de vida, morte, vitória, tela de resultado e reinício completo da tentativa.
- Implementado: recuo dos inimigos, pausa curta no impacto, faíscas, tremor de câmera e sons provisórios para golpe, dano, esquiva e resultado.

## Decisões técnicas

- Priorizar arte 2D leve e recursos provisórios.
- Usar o renderizador Compatibility por causa das placas de vídeo disponíveis.
- Evitar C#, dependências externas e arquitetura complexa neste estágio.
- Movimento usa aceleração e desaceleração; os parâmetros de ajuste estão expostos em `scripts/player.gd`.
- Dano, preparação, duração ativa e recuperação do ataque estão centralizados como parâmetros exportados em `scripts/player.gd`.
- O ataque permite movimento simultâneo para preservar agilidade; ataques adicionais ficam bloqueados durante preparação, duração ativa e recuperação.
- Cada alvo é registrado durante o golpe para impedir dano duplicado pela mesma ativação.
- Velocidade, duração, recarga e invulnerabilidade da esquiva estão centralizadas como parâmetros exportados em `scripts/player.gd`.
- Ataque e esquiva não podem permanecer ativos simultaneamente; quando os comandos quase coincidem, a esquiva tem prioridade defensiva.
- Inimigos usam formas e cores distintas: laranja para corpo a corpo e roxo para atirador; avisos de perigo usam vermelho.
- O atirador recua quando o jogador se aproxima e avança quando está longe; esse controle de distância foi aprovado por tornar o posicionamento mais interessante.
- A vida é representada por cinco fragmentos de memória na interface.
- Vitória exige eliminar os dois inimigos de combate; o alvo de treinamento não conta.
- Vitória e derrota congelam inimigos e projéteis; o reinício recarrega a cena e limpa o estado da tentativa.
- O feedback usa formas e áudio gerados pelo próprio projeto, sem assets externos; a pausa de impacto dura 45 ms e congela apenas os objetos de combate.
- Recuo e efeitos são leves e temporários para preservar leitura e desempenho.
- A perspectiva isométrica é visual. O movimento permanece alinhado à tela para controles mais diretos.
- Orçamento inicial zero; disponibilidade aproximada de duas horas por dia.

## Validação

- Realizado: executável do Godot confirmou a versão 4.7.2 pelo terminal.
- Realizado: editor e jogo carregaram em modo headless sem erros de projeto.
- Realizado: `tests/phase1_smoke_test.gd` confirmou cena, personagem, câmera, colisão, normalização diagonal e bloqueio da borda direita.
- Realizado pelo usuário: WASD e diagonais funcionam, inversão de direção responde corretamente, nenhuma borda foi atravessada e a câmera está fluida.
- Fase 1 concluída e aprovada.
- Realizado: regressão automatizada da Fase 1 continuou passando após a inclusão do ataque.
- Realizado: `tests/phase2_attack_test.gd` confirmou início do ataque, bloqueio durante o intervalo e exatamente um dano por golpe.
- Realizado pelo usuário: ataque direcional funcionou, só atingiu dentro do alcance, intervalo entre golpes ficou adequado e cada golpe removeu apenas uma barra.
- Realizado pelo usuário: velocidade geral do ataque foi considerada boa.
- Fase 2 concluída e aprovada.
- Realizado: regressões automatizadas das Fases 1 e 2 continuaram passando após a inclusão da esquiva.
- Realizado: `tests/phase3_dodge_test.gd` confirmou deslocamento, invulnerabilidade temporária, bloqueio de repetição, recarga e colisão com a borda.
- Realizado pelo usuário: esquiva funcionou nas direções de movimento e, sem movimento, seguiu a direção atual do personagem.
- Realizado pelo usuário: recarga perceptível, bordas contêm o avanço, esquiva prevalece no conflito com ataque e distância/velocidade foram aprovadas.
- Fase 3 concluída e aprovada.
- Realizado: `tests/phase4_enemies_test.gd` confirmou sinalização corpo a corpo, um impacto após a preparação, dano do jogador no inimigo e projétil após a linha de mira.
- Realizado: todas as regressões automatizadas das Fases 1, 2 e 3 continuaram passando.
- Realizado pelo usuário: aviso corpo a corpo dá tempo de esquivar; atirador mantém distância; linha permite prever o disparo; projétil tem velocidade justa e pode ser evitado.
- Realizado pelo usuário: ambos os inimigos podem ser atingidos e eliminados normalmente.
- Realizado: teste integrado colocou um projétil sobre o jogador durante a esquiva e confirmou que o contador não aumentou.
- Fase 4 concluída e aprovada.
- Realizado: `tests/phase5_run_cycle_test.gd` confirmou perda de vida, morte em zero, derrota, vitória e interface de resultado.
- Realizado: nova instância da tentativa restaurou vida completa, dois inimigos e estado de combate.
- Realizado: suíte completa das Fases 1 a 5 passou sem regressões.
- Realizado pelo usuário: derrota exibiu “Conexão interrompida” e o reinício com R funcionou.
- Realizado pelo usuário: vida e inimigos retornaram; os dois inimigos puderam ser eliminados; vitória e novo reinício funcionaram.
- Realizado pelo usuário: nenhum projétil ou estado anterior permaneceu após reiniciar; a tentativa começou do zero.
- Fase 5 concluída e aprovada.
- Realizado: `tests/phase6_feedback_test.gd` confirmou recuo na direção do golpe, pausa de impacto, faíscas, tremor e retomada do processamento.
- Realizado: sons provisórios foram criados e conectados sem arquivos externos.
- Realizado: suíte das Fases 1 a 5 permaneceu aprovada após o polimento.
- Realizado pelo usuário: impacto parece forte e bem executado; recuo ajuda após aprender o ritmo; tremor está confortável; faíscas são claras e não escondem o combate.
- Realizado pelo usuário: feedback de esquiva, dano, vitória e derrota está distinto; o único ajuste solicitado foi reduzir o volume.
- Ajustado: todos os efeitos sonoros foram reduzidos em 5 dB, preservando suas diferenças relativas.
- Fase 6 concluída e aprovada após o ajuste de volume.
- Realizado: suíte consolidada com seis testes automatizados passou integralmente.
- Realizado: preset Windows criado e exportação release gerou `build/windows/DividaFantasma.exe` com recursos embutidos.
- Realizado: build exportado iniciou em modo headless e gerou log sem erros de script ou carregamento.
- Realizado pelo usuário: executável exportado foi testado fora do editor e aprovado, sem problemas relatados.
- Demo de combate `0.1.0` estabilizada.

## Ambiente conhecido

- 16 GB de RAM.
- NVIDIA GeForce 210 e Intel HD Graphics 4400.
- Windows 10 Pro 64 bits, build 17763.

## Problemas conhecidos

- O hardware gráfico e a versão do Windows são antigos. Se o Godot 4.7.2 ficar instável, será necessário avaliar uma versão anterior.
- O ambiente automatizado protegido não permite criar os dados normais do jogo no AppData; isso não impediu o carregamento headless.

## Próximo bloco

- Fase 6.5: proteger a demo em Git e registrar `v0.1.0`.
- Fase 7: integrar o visual e as animações do Protagonista 01; manter o Protagonista 02 reservado como skin futura.
- Fase 8: construir três salas artesanais conectadas por portas liberadas após os combates.
- Fase 9: oferecer três melhorias após cada sala, mantendo as escolhas durante a tentativa.
- Fase 10: criar o primeiro chefe com até três ataques sinalizados e uma mudança simples de comportamento.
- Fase 11: consolidar menu, pausa, volume e uma demonstração Windows de aproximadamente 5–10 minutos.

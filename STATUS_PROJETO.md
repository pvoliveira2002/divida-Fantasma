# Status do projeto

## Engine e versão

- Godot 4.7.2 estável, edição padrão sem C#.
- Instalação portátil em `tools/godot/4.7.2/`.
- Renderizador Compatibility/OpenGL.
- Plataforma inicial: Windows.

## Execução e controles

- Abra `tools/godot/4.7.2/Godot_v4.7.2-stable_win64.exe` e importe `project.godot`, se necessário.
- Execute o projeto com **F5** no editor.
- A versão Windows 0.2.0 está em `build/windows/DividaFantasma.exe`, com recursos embutidos. O jogo abre no menu inicial.
- **Esc** pausa/continua. Menus oferecem controles, volume, reinício e retorno ao início. Volume geral é persistido em `user://preferences.cfg`.
- Movimento: **WASD**.
- Ataque direcionado ao mouse: **clique esquerdo**.
- Ataque na direção atual: **Espaço**.
- Esquiva: **Shift** ou **Ctrl**, usando a direção do movimento; sem direção, usa a direção atual.
- Após vitória ou derrota: **R** inicia uma nova tentativa.
- Porta liberada à direita: aproxime-se e pressione **E** para avançar de sala.
- Após limpar uma sala, instale um protocolo por clique ou teclas **1, 2, 3**. A porta libera após a escolha; após a terceira sala, ela leva ao chefe.

## Estado atual

- Conceito provisório: **Dívida Fantasma**, roguelite de ação cyberpunk em 2D com perspectiva isométrica.
- Demo de combate `0.1.0` foi o marco anterior; versão `0.2.0` exportada para Windows com salas, protocolos, chefe e menus, aguardando aceite manual final.
- Implementado: arena provisória isométrica, personagem, movimento em oito direções, câmera, colisões e ataque básico direcional.
- Implementado: esquiva direcional com recarga, invulnerabilidade configurável e respeito às colisões da arena.
- Implementado: alvo de treinamento com três pontos de vida e reinício automático após ser destruído.
- Implementado: inimigo corpo a corpo que persegue, sinaliza o alcance e ataca após preparação.
- Implementado: inimigo atirador que mantém distância, mostra a linha de mira e dispara projéteis.
- Implementado: cinco pontos de vida, morte, vitória, tela de resultado e reinício completo da tentativa.
- Implementado: recuo dos inimigos, pausa curta no impacto, faíscas, tremor de câmera e sons provisórios para golpe, dano, esquiva e resultado.
- Fase 7 em andamento: folha-base do Protagonista 01 integrada com quatro vistas direcionais estáticas; visual aprovado pelo usuário e preservado como `directional_base_v1.png`.
- Fase 7.2 em andamento: folhas `idle_4dir_v1.png` e `run_4dir_v1.png` criadas e conectadas ao personagem com quatro quadros por direção.

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
- Vitória exige concluir as três salas, instalar os protocolos e derrotar o chefe com seus dois guardas no encontro final. O alvo de treinamento não conta.
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
- Realizado: Godot importou `directional_base_v1.png` e carregou a cena do jogador sem erros de script ou referências ausentes.
- Realizado: os seis testes automatizados das Fases 1 a 6 passaram após a integração visual direcional.
- Realizado pelo usuário: as quatro poses estáticas do Protagonista 01 foram aprovadas e devem ser preservadas como referência visual das animações.
- Realizado: Godot importou as folhas de parado e corrida, carregou `player.tscn` e compilou `player.gd` sem erros.
- Realizado: `project.godot` e `scenes/main.tscn` foram restaurados para a versão funcional com autorização do usuário.
- Realizado: os seis testes automatizados das Fases 1 a 6 passaram após a integração das animações de parado e corrida.
- Pendente do usuário: validar visualmente na arena o ciclo de parado, corrida, escala e ponto de apoio.
- Ajustado após teste do usuário: idle passou a usar as poses estáticas aprovadas com respiração sutil, eliminando avanço falso entre quadros.
- Ajustado após teste do usuário: corrida recebeu compensação individual de alinhamento para reduzir flutuação e inconsistência dos pés.
- Realizado: os seis testes automatizados continuaram passando após as correções de idle e corrida.
- Ajustado após novo teste do usuário: diagonais para cima usam apenas os quadros traseiros com contato dos pés legível, evitando o desaparecimento do pé dianteiro.
- Fase 7.3: folha de ataque em quatro direções criada e conectada aos estados reais de preparação, impacto e recuperação.
- Realizado: Godot importou a folha de ataque e os seis testes automatizados passaram, incluindo dano único por golpe e regressões de esquiva.
- Realizado pelo usuário: soco cibernético testado e aprovado visualmente. Fase 7.3 concluída.
- Fase 7.4 implementada para avaliação: esquiva usa poses existentes da corrida com sequência própria, compressão e inclinação visuais sincronizadas com o impulso de 0,16 s; sem nova folha de sprites e sem alterar a mecânica.
- Realizado: seis testes automatizados passaram; teste de esquiva verifica compressão, inclinação, ausência de deslocamento físico pela animação e restauração da rotação.
- Observado: teste da Fase 4 emitiu aviso de duas instâncias ObjectDB não liberadas ao encerrar, apesar de passar. Causa ainda não investigada.
- Realizado pelo usuário: animação de esquiva aprovada. Fase 7.4 concluída.
- Fase 7.5 implementada para avaliação: dano aplica recuo e oscilação apenas no sprite por 0,16 s, preservando controle e tempos de ataque; morte anima queda de 0,45 s em torno dos pés e mantém a pose final. Ambas reaproveitam a arte existente.
- Morte cancela ataque e esquiva, desliga a área de ataque e impede novos golpes; derrota e reinício continuam imediatos.
- Realizado: seis testes automatizados passaram nesta entrega, sem o aviso ObjectDB observado na execução anterior. Teste da Fase 5 verifica recuperação do visual após dano, cancelamento de ataque ao morrer, progressão e estabilidade da queda após derrota e limpeza ao reiniciar.
- Realizado pelo usuário: animações de dano e morte aprovadas; solicitado somente reduzir o tremor da câmera nos impactos.
- Ajustado: amplitude do tremor reduzida em 70% (acerto: 5 para 1,5 px; dano recebido: 8 para 2,4 px), com duração reduzida de 0,10 para 0,07 s e de 0,16 para 0,10 s, respectivamente. Demais efeitos preservados.

## Ambiente conhecido

- 16 GB de RAM.
- NVIDIA GeForce 210 e Intel HD Graphics 4400.
- Windows 10 Pro 64 bits, build 17763.

## Problemas conhecidos

- O hardware gráfico e a versão do Windows são antigos. Se o Godot 4.7.2 ficar instável, será necessário avaliar uma versão anterior.
- O ambiente automatizado protegido não permite criar os dados normais do jogo no AppData; isso não impediu o carregamento headless.

## Próximo bloco

- Fase 8 implementada: três encontros artesanais (Acesso: 2 inimigos; Arquivo: 3; Núcleo: 4), com o mesmo contorno de arena, cores, marcações e posições de inimigos distintas. Sem geração procedural.
- `scripts/room_sequence.gd` controla salas, porta com colisão durante o combate e transição por E; `arena.gd` mantém vida/resultado da tentativa através do mesmo jogador.
- Transições preservam vida e recarga da esquiva, limpam projéteis, efeitos, alvo de treinamento, referências do golpe e pausa de impacto; entrada reposiciona o jogador em local seguro e restaura a câmera.
- Testado: sete testes automatizados passaram, incluindo bloqueio físico da porta, preservação de vida, limpeza, rejeição de transição repetida, vitória final, derrota e estado inicial de nova tentativa. Capturas das salas renderizadas pelo Godot foram produzidas; apresentação da sala Arquivo inspecionada.
- Observação: avisos intermitentes ObjectDB ao encerrar testes foram identificados como AudioStreamWAV/AudioStreamPlaybackWAV; não houve falha nas verificações. Não foi demonstrado vazamento durante o jogo.
- Realizado pelo usuário: sequência de salas e dificuldade crescente aprovadas. Fase 8 concluída.
- Fase 9 revisada conforme direção do usuário: bônus numéricos substituídos por Curto-Circuito, Rastro Fantasma e Sobrecarga. Reinstalar soma 1 ao dano do efeito; protocolos coexistem sem modificar o dano básico, a recarga ou a invulnerabilidade. Regras e propostas futuras estão em `PROTOCOLOS.md`.
- Seleção bloqueia combate e passagem até uma escolha válida; recompensa é consumida antes da aplicação, impedindo duplicação. Níveis são exibidos no HUD e zerados numa nova tentativa. A terceira escolha libera o acesso ao chefe.
- Interface de instalação: título e instrução propostos pelo usuário, ícones vetoriais grandes, descrições curtas, circuitos decorativos, destaque ao passar o mouse/focar, selo NOVO PROTOCOLO e evolução de protocolos instalados.
- `scripts/combat_protocols.gd` recebe apenas acertos básicos confirmados e esquivas; danos secundários não reativam protocolos. Contadores, cargas e efeitos pendentes são limpos ao concluir/trocar sala e encerrar a tentativa. Instalações persistem entre salas.
- Realizado: nove testes automatizados passaram, incluindo protocolos combinados, descarga no golpe fatal, contagem por alvo/golpe, atraso e posição da explosão, alcance/cone da onda, não recursão, evolução, persistência e reinício. Cartões e efeitos de combate foram renderizados no Godot e inspecionados visualmente.
- Pendente: aprovação manual dos protocolos e balanceamento. Avisos intermitentes de áudio ao encerrar testes continuam registrados; no teste específico de protocolos foram eliminados ao aguardar a liberação do áudio antes de encerrar. Build Windows ainda não reexportada.
- Realizado pelo usuário: primeira versão dos três protocolos e nova interface aprovadas. Outras cinco ideias e combinações permanecem documentadas em `PROTOCOLOS.md`.
- Fase 10 implementada para avaliação: Cobrador de Memórias (24 de vida), em um quarto encontro após as três salas, acompanhado de dois guardas corpo a corpo. Vida do jogador e protocolos são preservados, sem cura automática. Visual provisório geométrico próprio, barra de vida inferior e avisos vermelhos.
- Chefe tem três ataques: leque de três projéteis (240 px/s), investida (720 px/s por até 0,36 s, respeitando paredes) e golpe circular (120 px). Preparação de 0,85 s, dano de 1 por impacto/projétil e recuperação de 1,05 s sinalizada com anel ciano. Investida limita dano a um acerto por ativação.
- Abaixo de 50% da vida, movimento aumenta 15% e recuperação passa a 75% da duração original. Tempo de aviso, alcance e dano são preservados. Não há animações cinematográficas nem novos sistemas exclusivos.
- Vitória exige chefe e guardas derrotados. Morte do chefe limpa projéteis; derrota congela o chefe. Reinício retorna à primeira sala com vida e protocolos zerados/restaurados como antes.
- Realizado: dez testes automatizados passaram; verificadas sinalização antes do dano, invulnerabilidade, mira travada, dano único da investida, colisão com borda, transição de fase, interação com Sobrecarga, morte, derrota e vitória final sem antecipação. Capturas dos três avisos e barra de vida foram renderizadas e inspecionadas.
- Realizado pelo usuário: primeiro chefe e seus três ataques aprovados.
- Fase 11 implementada: cena inicial `menu.tscn`, iniciar/sair, controles, pausa por Esc, continuar, reiniciar, retorno ao menu e volume geral de 0–100% persistente. Vitória/derrota oferecem botões e R continua reiniciando a partida.
- Pausa congela árvore de jogo, incluindo movimentos, ataques, projéteis e explosões; a interface da pausa permanece ativa. Retomar durante seleção de protocolo preserva a seleção e o bloqueio de combate. Reiniciar/menu sempre removem a pausa antes da troca de cena.
- Realizado: doze testes automatizados passaram, incluindo fluxo completo menu → três salas → protocolos → chefe → vitória → menu → nova tentativa → derrota → reinício. Esse teste exercita caminhos determinísticos de combate, não avalia dificuldade ou tempo manual.
- Realizado: templates oficiais Windows 4.7.2 instalados localmente; exportação release 0.2.0 gerou `build/windows/DividaFantasma.exe` (112.265.536 bytes), com recursos embutidos. Inicialização headless e captura visual do menu no executável exportado sem erros. Menus inicial, controles, volume, pausa e resultado renderizados para inspeção; início, controles, pausa e resultado inspecionados.
- Limite de validação: template release não disponibiliza `--script`; teste automatizado de ponta a ponta foi realizado no projeto, não no executável final. Avisos intermitentes de áudio ao encerrar alguns testes seguem registrados.
- Próximo bloco: aceite manual da build Windows completa, cronometragem da tentativa (meta 5–10 minutos) e eventual ajuste de ritmo. Não foi afirmada duração medida nem conclusão do aceite manual da Fase 11.
- Realizado pelo usuário: primeira cronometragem manual terminou em menos de 1 minuto; as três salas e o chefe foram considerados fáceis, sem bugs aparentes durante a partida.
- Balanceamento 0.2.1 em avaliação: cada sala passou a ter três ondas artesanais (9 inimigos no Acesso, 12 no Arquivo e 15 no Núcleo), com no máximo seis inimigos simultâneos. Protocolos continuam sendo oferecidos somente após a última onda.
- Chefe ajustado para 36 de vida, aproximação mais rápida, avisos de 0,75 s, recuperação de 0,85 s e segunda metade mais agressiva. Dano por impacto e variedade de ataques foram preservados.
- Realizado: doze testes automatizados passaram após o balanceamento, cobrindo ondas, portas, protocolos, chefe, menus, reinício e fluxo completo. O teste isolado de volume usa `res://.godot` porque o ambiente protegido não grava em `user://`; o jogo real continua usando `user://preferences.cfg`.
- Próximo passo: nova partida manual cronometrada. Meta intermediária deste passe: aproximadamente 3–5 minutos, antes de decidir se novas mecânicas ou mais conteúdo são necessários para alcançar 5–10 minutos.

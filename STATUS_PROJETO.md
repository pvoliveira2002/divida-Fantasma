# Status do projeto

## Atualizacao atual - Fase 13.3

- Validacao completa antes do envio ao Git: os 12 testes automatizados disponiveis passaram em Godot 4.7.2, cobrindo movimento, ataque, esquiva, inimigos, feedback, ciclo de salas, protocolos, chefe, menu e partida completa. Os tres novos PNGs continuam como candidatos visuais nao integrados e, portanto, foram validados apenas quanto a dimensoes, grade, margens e transparencia.
- Candidata do combo corpo a corpo criada em `assets/characters/protagonist_01/combo_front_right_16f_v1.png`: folha RGBA 1536 x 1536 com quatro golpes em 16 quadros, grade 4 x 4 e celulas exatas de 384 x 384. Direcao, identidade e lado anatomico do braco cibernetico foram preservados; todos os quadros e efeitos possuem margens transparentes. Ainda nao integrada ao sistema de ataque.
- Candidata de animacao de salto criada em `assets/characters/protagonist_01/jump_front_right_8f_v1.png`: folha RGBA 2048 x 1024 com oito quadros em grade 4 x 2, celulas exatas de 512 x 512, direcao tres-quartos frontal para a direita e braco cibernetico consistente. O asset foi validado quanto a divisao, margens e transparencia, mas ainda nao foi integrado ao salto para a escotilha.
- Novo candidato visual fechado criado em `assets/environments/hatch/cyber_hatch_closed_v1.png`: sprite isometrica isolada em PNG RGBA 1536 x 1024, com fundo, nevoa, brilho externo e sombra projetada removidos. A arte ainda nao foi integrada a cena; aguarda aprovacao visual e a futura preparacao dos estados de abertura.
- Modelo da escotilha revisado a pedido do usuario: linguagem futurista de placas deslizantes substituida por uma peca industrial antiga e original, com moldura octogonal de ferro, tampa unica pesada, dobradicas, rebites, puxador, ferrugem, faixa de seguranca gasta e quatro travas reformadas com energia ciano.
- Durante o desbloqueio as travas acendem e a tampa vibra sem abrir prematuramente. Apos a escolha do protocolo, a tampa recua para a dobradica superior, revela um vao escuro com escada e mantem o holograma `E`. Posicao, tempos, interacao e salto do protagonista foram preservados.
- Validado apos a troca visual: `phase8_rooms_test.gd` e `phase11_full_run_test.gd` passaram. Pendente avaliacao manual de escala, peso da abertura, contraste da ferrugem e leitura do vao.

- Revisao principal da Fase 13.3: porta lateral removida e substituida por escotilha de piso. Cada uma das tres salas comuns sorteia uma posicao entre quatro pontos seguros previamente definidos; a posicao permanece estavel durante a sala e a escotilha nao adiciona colisao.
- Ao concluir a ultima onda, o aro inicia um desbloqueio parcial. A escolha do protocolo abre as duas placas por completo e ativa um sinal holografico com setas e icone `E`. A proximidade e a tecla `E` continuam obrigatorias; entradas repetidas sao bloqueadas.
- Protagonista recebeu transicao visual de 0,72 s controlada por codigo: preparacao comprimida, salto curto ate o centro, arco, sombra acompanhando o deslocamento, reducao e desaparecimento dentro da escotilha. Controles e colisao sao suspensos somente durante a entrada; a camera permanece estavel porque o corpo fisico nao e deslocado durante o efeito.
- A sala seguinte restaura corpo, sprite, controles, camera, vida e protocolos existentes no ponto seguro aprovado. O confronto final oculta a escotilha; a vitoria continua encerrando a partida diretamente.
- Textos de ajuda, dicas da sala e tela de controles foram atualizados para a nova interacao.
- Validado: `phase1_smoke_test.gd`, `phase5_run_cycle_test.gd`, `phase8_rooms_test.gd`, `phase9_upgrades_test.gd`, `phase10_boss_test.gd` e `phase11_full_run_test.gd` passaram. Cobertura inclui posicao autorizada, desbloqueio, abertura, proximidade, bloqueio de entrada dupla, animacao, restauracao e ausencia no chefe. Avisos intermitentes conhecidos de objetos ao encerrar o teste de salas permanecem sem falha funcional.
- Pendente: avaliacao manual do tamanho, ritmo de abertura, clareza do holograma e naturalidade do salto. Proximo bloco apos aprovacao: Fase 13.4, iluminacao e efeitos ambientais leves.

- Fase 13.2 aprovada pelo usuario: diferenciacao visual das salas mantem boa leitura durante a partida.
- Porta provisoria substituida visualmente por dois pilares metalicos e cinco segmentos de energia pulsante. Ao escolher a melhoria, os segmentos retraem, desaparecem e revelam uma seta de saida; a colisao original continua sendo a unica barreira fisica.
- Plataforma recebeu laterais inferiores escuras para criar espessura e quatro modulos tecnologicos baixos presos ao aro. Elementos usam a cor de identidade da sala e nao adicionam colisao, cobertura ou obstaculos.
- Validado: `phase1_smoke_test.gd`, `phase8_rooms_test.gd`, `phase10_boss_test.gd` e `phase11_full_run_test.gd` passaram. O teste de salas cobre porta fechada, inicio da retracao, remocao diferida da colisao e transicao. Aviso intermitente conhecido de objetos apareceu somente ao encerrar esse teste.
- Pendente: avaliacao manual da leitura da porta fechada/aberta, profundidade da plataforma e integracao dos modulos. Proximo bloco apos aprovacao: Fase 13.4, iluminacao e efeitos ambientais leves.

- Quatro identidades visuais leves foram adicionadas sobre o piso aprovado, sem novas texturas ou obstaculos: Acesso usa ciano e canal de entrada; Arquivo usa violeta e nos de dados; Nucleo usa verde-agua e circuitos ramificados; confronto final usa laranja e chevrons industriais.
- Cada sala aplica uma camada de cor muito suave, marcas nas regioes externas e contorno correspondente. O centro permanece limpo; avisos vermelhos de ataque, portas, personagens e projeteis continuam com prioridade visual.
- Dimensoes, colisoes, spawns e logica de transicao nao foram alterados. A troca visual reutiliza o `queue_redraw()` ja executado nas transicoes.
- Validado: `phase1_smoke_test.gd`, `phase8_rooms_test.gd`, `phase10_boss_test.gd` e `phase11_full_run_test.gd` passaram. O aviso conhecido de objetos de audio apareceu somente ao encerrar o teste de salas.
- Pendente: avaliacao manual da diferenciacao entre as quatro salas e da leitura durante combate. Proximo bloco apos aprovacao: Fase 13.3, portas, paredes baixas e elementos tecnologicos sem colisao adicional.

- Base visual da arena integrada em `assets/environments/arena/cyber_floor_base_v1.png`: plataforma industrial cyberpunk em losango, com chapas grafite, desgaste moderado, centro limpo e iluminacao ciano. A arte tem transparencia fora da plataforma e foi ajustada ao contorno existente de 1080 x 600.
- Colisoes, dimensoes e area jogavel foram preservadas. O contorno ciano fino continua sendo desenhado sobre os quatro segmentos fisicos para manter limite visual e colisao coincidentes; a grade provisoria deixou de ser exibida.
- Ajuste apos avaliacao manual: sombras do protagonista, Executor, Auditora e Cobrador agora combinam uma elipse ambiente curta com um nucleo escuro exatamente no ponto dos pes. O deslocamento inferior anterior foi removido para recuperar contato com o piso sem mover sprites, colisoes ou ataques.
- Validado: importacao da textura concluida; `phase1_smoke_test.gd`, `phase8_rooms_test.gd` e `phase11_full_run_test.gd` passaram. O teste de salas agora tambem protege a resolucao da arte e os quatro pontos aprovados da arena. Aviso intermitente conhecido de objetos de audio apareceu ao encerrar o teste de salas.
- Validado apos o ajuste de contato: `phase1_smoke_test.gd`, `phase4_enemies_test.gd` e `phase10_boss_test.gd` passaram.
- Aprovado pelo usuario: contraste, aparencia e contato dos personagens com o piso. Fase 13.1 concluida.
- Proximo bloco: Fase 13.2, variacoes visuais leves para Acesso, Arquivo, Nucleo e confronto final, preservando a base e a leitura do combate aprovadas.

- Reacao de dano e destruicao do Cobrador implementadas sem alterar vida, dificuldade ou ataques. Golpes causam clarao e oscilacao curta na direcao do impacto; o golpe fatal interrompe ataque e colisao imediatamente, limpa os projeteis pelo sinal existente e inicia uma queda mecanica de 0,82 s.
- A destruicao combina falha azul do nucleo, anel de energia expansivo, faiscas azuis, fragmentos laranja/grafite, compressao do corpo, reducao da sombra e apagamento. O chefe sai do grupo de combate no inicio, portanto a animacao nao bloqueia guardas, vitoria ou reinicio.
- Validado: `phase10_boss_test.gd`, `phase8_rooms_test.gd` e `phase11_full_run_test.gd` passaram. O aviso intermitente conhecido de objetos de audio apareceu somente ao encerrar o teste de salas. Pendente: avaliacao visual manual da intensidade e duracao da destruicao.
- Aprovado pelo usuario: reacao de dano e destruicao do Cobrador. Fase 12.10 concluida.
- Proximo bloco: Fase 13.1, criar a base visual do piso e das bordas da arena para eliminar a sensacao de personagens flutuando, preservando colisoes e dimensoes atuais.

- Escudo de plasma movido para uma camada acima do sprite, mantendo sombra e avisos abaixo do personagem. Velocidade dos tres plasmas do chefe aumentada de 240 para 270 px/s (+12,5%); dano, colisao e tempo de aviso permanecem iguais.

- Os tres projeteis do chefe deixaram de ser triangulos simples: agora sao esferas de plasma azul pulsante, com nucleo claro, particulas orbitais e rastro energetico. Colisao circular, velocidade e dano foram preservados; projeteis da Auditora nao foram alterados.

- Escudo do dash ampliado apos avaliacao manual: agora forma um disco oval vertical de plasma com cerca de 140 px de altura, cobrindo o corpo inteiro da cabeca aos pes e permanecendo apenas visual.

- Rajada alinhada ao visual: particulas e os tres projeteis do chefe agora usam azul eletrico. Durante `DASHING`, um escudo de plasma azul pulsante acompanha o ombro dianteiro sem alterar colisao ou invulnerabilidade.

- Ajuste solicitado: impacto circular agora levanta uma nuvem de 30 particulas largas de poeira alem dos detritos; inicio da ombrada cria uma rajada dedicada de 26 faiscas laranja no ombro dianteiro.

- Animacoes dos tres ataques aprovadas pelo usuario; faltavam efeitos de particulas.
- Particulas leves desenhadas por codigo foram integradas: poeira e faiscas laranja acompanham a ombrada, detritos com energia ciano surgem no impacto circular e descargas ciano saem das duas palmas na rajada.
- A ombrada emite um rastro curto durante o deslocamento. Efeitos sao visuais, temporarios e nao usam simulacao pesada de GPU.
- Testes do chefe, salas e fluxo completo passaram, incluindo verificacao de criacao dos efeitos sem alterar dano ou estados.
- Pendente: avaliacao manual da intensidade, cores e quantidade das particulas.

- Tres ataques do Cobrador receberam animacoes proprias em quatro direcoes: `dash_4dir_v1.png` usa ombrada, `slam_4dir_v1.png` usa dois punhos no chao e `volley_4dir_v1.png` carrega/dispara energia ciano pelas palmas.
- Preparacao usa quadros 0-1; execucao real usa quadro 2; recuperacao usa quadro 3. Dano circular, nascimento dos projeteis e movimento da investida continuam definidos pela logica aprovada.
- Escala 0,46 e ponto fisico foram preservados nas tres folhas. Testes do chefe, salas e fluxo completo passaram; o teste de salas manteve apenas o aviso intermitente conhecido ao encerrar.
- Pendente: avaliacao visual manual da leitura, sincronizacao e peso dos tres ataques.
- Proximo bloco apos aprovacao: reacao de dano e destruicao do Cobrador.

- Corrigida regressao visual observada pelo usuario: folhas 4x4 agora usam escala 0,46 e a base 2x2 usa 0,23, preservando exatamente o mesmo tamanho aparente nas trocas entre caminhada, parado e ataque.

- Visual-base e tamanho do Cobrador aprovados pelo usuario.
- `idle_4dir_v1.png` e `walk_4dir_v1.png` integradas: parado usa ciclo mecanico lento com nucleo pulsante; aproximacao usa passos curtos e pesados nas quatro direcoes.
- Ataques continuam na pose-base ate receberem folhas especificas. Animacoes nao deslocam o corpo fisico e preservam velocidade, colisao e balanceamento.
- Testes do chefe, salas e fluxo completo passaram. Aviso intermitente de objetos de audio ao encerrar o teste de salas continua sem falha funcional.
- Pendente: avaliacao manual de peso, contato dos pes e velocidade dos ciclos.
- Proximo bloco apos aprovacao: animacoes de rajada, investida e impacto circular.

- Ferramenta temporaria de teste adicionada ao menu: `TEMPORARIO - TESTAR CHEFE` inicia diretamente o encontro final com vida cheia, sem protocolos e com os dois guardas reais. `INICIAR TENTATIVA` continua iniciando na primeira sala.
- Validado: testes do chefe, salas e fluxo completo passaram; o fluxo completo confirmou o botao, sala final, chefe, guardas e estado inicial previsivel.

- Reacao de dano e destruicao da Auditora aprovadas ao avancar para o proximo bloco.
- Cobrador de Memorias recebeu folha-base estatica em quatro direcoes, derivada do conceito de tanque grafite e laranja reservado pelo usuario. O nucleo ciano diferencia o chefe dos inimigos comuns.
- Visual geometrico provisório foi substituido; sombra, colisao, vida, movimento, tres ataques, reforcos e segunda fase foram preservados.
- Testes do chefe, salas e fluxo completo passaram; o teste do chefe tambem confirmou quatro vistas e ausencia de movimento fisico pela troca visual.
- Pendente: avaliacao manual de escala, ponto de apoio, leitura dos avisos e troca de direcao.
- Proximo bloco apos aprovacao: parado e locomocao pesada do Cobrador.

- Disparo funcional aprovado pelo usuario; a velocidade visual ainda pode receber ajuste fino posterior.
- Auditora reage ao dano com recuo e oscilacao visual. Na derrota, ataque e colisao sao cancelados, ela sai do grupo de combate e executa queda, falha magenta e apagamento antes da remocao.
- Testes de inimigos, salas, protocolos e fluxo completo passaram. O teste de salas repetiu o aviso intermitente de objetos de audio ao encerrar, sem falha funcional.
- Pendente: avaliacao visual manual da reacao de dano e destruicao.
- Proximo bloco: definir a proxima frente visual depois dessa avaliacao.

- Auditora de Rede: locomocao e sequencia de disparo em quatro direcoes integradas.
- `shoot_4dir_v1.png` apresenta arma baixa, levantamento, mira e disparo com recuo; os quadros seguem `WINDUP`, `_fire()` e `RECOVERY` sem alterar o balanceamento.
- Testes executados: inimigos da Fase 4 e sequencia de salas da Fase 8 passaram.
- Pendente: avaliacao visual manual da sincronizacao, alinhamento dos pes e leitura do clarão.
- Proximo bloco: dano e destruicao da Auditora apos aprovacao do disparo.

## Engine e versão

- Godot 4.7.2 estável, edição padrão sem C#.
- Instalação portátil em `tools/godot/4.7.2/`.
- Renderizador Compatibility/OpenGL.
- Plataforma inicial: Windows.

## Execução e controles

- Abra `tools/godot/4.7.2/Godot_v4.7.2-stable_win64.exe` e importe `project.godot`, se necessário.
- Execute o projeto com **F5** no editor.
- A versão Windows 0.2.1 está em `build/windows/DividaFantasma.exe`, com recursos embutidos. O jogo abre no menu inicial.
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
- Demo de combate `0.1.0` foi o marco anterior; versão `0.2.1` aprovada com salas em ondas, protocolos, chefe com reforços, menus e recarga da esquiva rebalanceada.
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
- Realizado pelo usuário: as ondas aumentaram satisfatoriamente o tempo até o chefe, mas o encontro final continuou fácil porque os dois guardas iniciais morriam cedo e deixavam o chefe previsível sozinho.
- Balanceamento do chefe em avaliação: ao chegar a 66% e 33% da vida, o Cobrador solicita uma nova dupla composta por um inimigo corpo a corpo e um atirador. Os reforços surgem afastados do jogador e não alteram vida, dano ou avisos dos ataques do chefe.
- Realizado: doze testes automatizados passaram após a inclusão dos reforços; vitória continua exigindo eliminar o chefe e todas as escoltas, incluindo as convocadas durante a luta.
- Próximo passo: validar manualmente se os reforços mantêm pressão sem tornar a arena confusa ou injusta.
- Realizado pelo usuário: partida completa após os reforços durou 1 min 28 s, terminando com apenas um ponto de vida. Não foram observados bugs, trechos injustos ou problemas de leitura.
- Observado no balanceamento: a combinação focada em esquiva ficou forte demais e acelerou excessivamente a eliminação dos encontros. A pressão ofensiva dos inimigos está relevante, mas a duração total permanece muito abaixo da meta de 5–10 minutos.
- Próximo bloco recomendado: revisar o protocolo de esquiva preservando sua identidade, medir o tempo por sala e adicionar duração por decisões e encontros curtos, evitando inflar apenas a vida dos inimigos.
- Decisão de balanceamento: antes de alterar o Rastro Fantasma, aumentar levemente a recarga base da esquiva de 0,55 s para 0,65 s. Distância, duração e invulnerabilidade permanecem iguais; objetivo é exigir melhor escolha do momento da esquiva e impedir repetição sem compromisso.
- Realizado: os doze testes automatizados passaram após o ajuste da recarga, cobrindo esquiva, protocolos, salas, chefe, menus e fluxo completo. Pendente validar manualmente a sensação do novo intervalo.
- Realizado pelo usuário: a esquiva com recarga de 0,65 s permanece funcional e satisfatória, mas deixou de ser excessivamente repetível. Ajuste aprovado; o Rastro Fantasma não precisa de redução direta neste passe.
- Próximo passo: fazer uma cronometragem final com a recarga aprovada e, se o fluxo permanecer estável, reexportar a build Windows e fechar o marco `v0.2.1`.
- Realizado pelo usuário: cronometragem final permaneceu próxima de 1 min 28 s, ligeiramente maior por causa da nova janela entre esquivas. Ritmo e dificuldade foram aprovados para o escopo atual.
- Marco 0.2.1 preparado: executável Windows reexportado com recursos embutidos. A build iniciou em modo headless sem erros e seus metadados confirmaram `FileVersion` e `ProductVersion` 0.2.1.
- Próximo bloco: preservar o balanceamento aprovado e iniciar a identidade visual dos inimigos e ambientes, substituindo recursos provisórios de forma incremental sem alterar as mecânicas.
- Fase 12 iniciada: identidade visual dos inimigos. O primeiro passe será o inimigo corpo a corpo comum, com silhueta humanoide corporativa, armadura grafite, detalhes laranja e arma curta; a mecânica aprovada será preservada.
- Conceito futuro aprovado: robô tanque industrial com ombreiras laranja e punhos pesados. Reservado como inimigo pesado/elite (`Penhorador Blindado`, nome provisório), sem implementação nesta fase e sem substituir o inimigo comum.
- Fase 12.1 implementada para avaliação: o Executor de Cobrança substitui a forma geométrica do inimigo corpo a corpo por uma folha-base estática com quatro direções, armadura grafite, visor laranja e bastão de choque. Escala, colisão, vida, velocidade, alcance, dano e sinalização foram preservados.
- Realizado: Godot importou a nova arte; doze testes automatizados passaram. O teste de inimigos também confirmou textura carregada e seleção correta das quatro vistas. Avisos intermitentes de `ObjectDB` e gravação de logs no ambiente protegido permanecem conhecidos, sem falhas funcionais.
- Pendente do usuário: avaliar na arena escala, ponto de apoio, troca de direção e leitura do aviso de ataque antes de produzir animações.
- Realizado pelo usuário: escala do Executor aprovada. Observado que a sombra circular do inimigo prejudicava o contato com o piso e que o cenário provisório ainda transmite sensação de flutuação.
- Ajustado: sombra do Executor passou a ser elíptica, baixa e alinhada aos pés, seguindo a linguagem visual já usada no protagonista. A criação da arena definitiva permanece reservada ao bloco de ambientes.
- Fase 12.2 implementada para avaliação: folhas `idle_4dir_v1.png` e `run_4dir_v1.png` do Executor foram criadas com quatro quadros em quatro direções. Parado usa respiração mecânica sutil; perseguição usa ciclo pesado alternando o contato dos pés.
- As animações são apenas visuais: o código continua controlando posição, velocidade e colisão. Mudanças de estado reiniciam o ciclo, e preparação/recuperação permanecem paradas até receberem animação própria.
- Realizado: Godot importou as duas folhas; doze testes automatizados passaram. O teste de inimigos confirmou carregamento, quatro direções e ausência de deslocamento físico causado pela animação.
- Pendente do usuário: avaliar ritmo da corrida, estabilidade dos pés, escala e transição entre parado e perseguição.
- Realizado pelo usuário: parado e corrida do Executor aprovados; durante o ataque, o retorno ao primeiro quadro de parado foi identificado como uma pose estática inadequada.
- Fase 12.3 implementada para avaliação: folha `attack_4dir_v1.png` adicionada com preparação, levantamento do bastão, impacto e recuperação em quatro direções. Os quadros são derivados dos temporizadores reais de `WINDUP` e `RECOVERY`, preservando o instante do dano, aviso, alcance e balanceamento.
- Realizado: Godot importou a folha de ataque; doze testes automatizados passaram. O teste do inimigo confirmou que a sinalização usa os quadros iniciais e que o impacto avança para os quadros finais sem alterar a lógica de dano.
- Pendente do usuário: validar se preparação, golpe e recuperação parecem naturais e sincronizados com o círculo vermelho.
- Realizado pelo usuário: sequência do ataque aprovada, mas o instante do contato ainda não transmitia força destrutiva suficiente.
- Ajustado: impacto do Executor agora cria faíscas à frente do bastão, dois arcos elétricos expansivos no chão e compressão visual do corpo por 0,18 s. Dano, alcance, temporizadores e tremor global foram preservados.
- Realizado: doze testes automatizados passaram. O teste do inimigo confirmou ativação do impacto visual e criação das faíscas junto ao quadro de contato.
- Pendente do usuário: validar se o reforço visual transmite peso sem encobrir o jogador ou o círculo de perigo.
- Ajustado a pedido do usuário: os dois arcos expansivos do impacto passaram de laranja para azul/ciano. Nenhuma outra propriedade visual ou mecânica foi alterada.
- Fase 12.4 implementada para avaliação: dano do Executor combina o recuo existente com clarão e oscilação do sprite; derrota reutiliza o quadro atual em uma queda mecânica com compressão, faísca, sombra reduzida e apagamento em 0,42 s.
- O golpe fatal continua alimentando protocolos antes de o Executor sair do combate. Colisão e ataques são desativados na derrota; salas, ondas e vitória não aguardam o término puramente visual.
- Validado: testes direcionados de inimigos, ciclo da tentativa, salas, protocolos, chefe e fluxo completo passaram. Pendente avaliação visual do usuário.
- Fase 12.4 aprovada pelo usuário.
- Fase 12.5 iniciada: candidato visual v1 da `Auditora de Rede` criado em quatro direções, com silhueta leve, rifle de pulso, capa técnica curta e código de cor violeta/magenta. Ainda não integrado; aguarda aprovação visual.
- Visual da Auditora aprovado e integrado: quatro vistas estáticas acompanham o jogador inclusive durante o recuo; forma geométrica foi substituída e sombra passou a ser elíptica. IA, distância, mira, projétil, vida e dano foram preservados.
- Validado: testes direcionados de inimigos e sequência de salas passaram. Pendente avaliação manual de escala, ponto de apoio, troca de direção e leitura da linha de mira.
- Fase 12.5 — locomoção implementada para avaliação: `idle_4dir_v1.png`, `advance_4dir_v1.png` e `backpedal_4dir_v1.png` conectadas ao cálculo de distância existente. A Auditora avança voltada ao alvo e usa passos próprios para recuar sem inverter a animação.
- Validado: testes de inimigos e salas passaram; confirmadas folhas distintas, quatro direções e ausência de deslocamento físico causado pelos quadros. Pendente avaliação manual dos pés, capa e transições. Próximo bloco: levantar arma, mirar, disparar e recuperar.

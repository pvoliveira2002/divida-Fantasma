# Dívida Fantasma — Demo 0.2.0

Demo jogável de ação roguelite cyberpunk em 2D isométrico, com menu inicial, três salas, protocolos combináveis, chefe final, pausa e volume persistente.

## Jogar no Windows

Abra `build/windows/DividaFantasma.exe` e selecione **Iniciar tentativa**. O executável contém os recursos do jogo e não exige instalar o Godot.

## Como executar no editor

1. Abra `tools/godot/4.7.2/Godot_v4.7.2-stable_win64.exe`.
2. Importe `project.godot`, caso o projeto ainda não apareça na lista.
3. Pressione **F5**.

## Controles

- **WASD:** mover.
- **Clique esquerdo:** atacar na direção do mouse.
- **Espaço:** atacar na direção atual.
- **Shift ou Ctrl:** esquivar.
- **R:** reiniciar após vitória ou derrota.
- **E:** próximo à porta liberada à direita, avançar para a próxima sala.
- **1, 2 ou 3 / clique:** instalar um protocolo após concluir a sala.
- **Esc:** pausar e continuar. A pausa oferece controles, volume, reinício e retorno ao menu.

## Objetivo da demo

Conclua três salas fixas: Acesso (dois inimigos), Arquivo (três) e Núcleo (quatro). Elimine todos os inimigos e instale um protocolo para liberar a porta à direita; pressione E perto dela para avançar. Depois da terceira instalação, a porta leva ao **Cobrador de Memórias**, com dois guardas. A vida restante e os protocolos acompanham você. Derrote todo o encontro final para vencer. R reinicia toda a sequência e remove os protocolos.

As opções são **Curto-Circuito** (três acertos no mesmo alvo descarregam em outro), **Rastro Fantasma** (esquiva deixa uma silhueta explosiva) e **Sobrecarga** (três acertos carregam uma onda para o próximo). Protocolos podem ser combinados; reinstalar fortalece o dano do efeito. Consulte [PROTOCOLOS.md](PROTOCOLOS.md) para as regras completas e as combinações planejadas.

Os avisos vermelhos indicam ataques iminentes. A esquiva concede invulnerabilidade durante o impulso. O alvo azul fica apenas na primeira sala, serve para treinamento e não bloqueia a porta.

O chefe sinaliza três ataques: leque de projéteis, investida em linha reta e golpe circular. O anel ciano indica recuperação, uma oportunidade de contra-atacar. Abaixo de metade da vida, ele se movimenta mais rápido e se recupera antes, mantendo o tempo dos avisos. A barra de vida aparece na parte inferior da tela.

## Exportação para Windows

O preset `Windows Desktop` gera `build/windows/DividaFantasma.exe`. A exportação exige os templates oficiais correspondentes ao Godot 4.7.2.

A build 0.2.0 inclui salas, protocolos, chefe e menus. O volume geral pode ser ajustado no menu inicial ou na pausa e fica salvo em `user://preferences.cfg`. Voltar ao menu ou reiniciar encerra a tentativa e remove os protocolos.

## Validação da demo

Doze testes automatizados cobrem combate, protocolos, chefe, transições, pausa, volume e o fluxo completo do menu à vitória e reinício. O executável exportado passou na abertura sem erros e teve o menu renderizado e inspecionado. A execução automatizada de ponta a ponta usa o projeto; o template release não oferece `--script` para repetir esse teste no executável final.

Falta jogar uma tentativa completa no executável, testar Esc/volume durante o combate, concluir o chefe e retornar ao menu. A meta de 5–10 minutos ainda depende de cronometragem manual e eventual ajuste de ritmo, preservando a dificuldade aprovada.

## Estado técnico

Consulte `STATUS_PROJETO.md` para funcionalidades, decisões, testes e problemas conhecidos.

